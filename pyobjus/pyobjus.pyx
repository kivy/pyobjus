__all__ = ('ObjcClass', 'ObjcMethod', 'MetaObjcClass', 'ObjcException')


include "common.pxi"
include "runtime.pxi"
include "ffi.pxi"
include "type_enc.pxi"


# do the initialization!
pyobjc_internal_init()


cdef dict oclass_register = {}


class ObjcException(Exception):
    pass


cdef class ObjcClassStorage:
    cdef Class o_cls

    def __cinit__(self):
        self.o_cls = NULL


class MetaObjcClass(type):
    def __new__(meta, classname, bases, classDict):
        meta.resolve_class(classDict)
        tp = type.__new__(meta, classname, bases, classDict)
        oclass_register[classDict['__objcclass__']] = tp
        return tp

    @staticmethod
    def get_objcclass(name):
        return oclass_register.get(name)

    @classmethod
    def resolve_class(meta, classDict):
        # search the Objc class, and bind to our object
        if '__objcclass__' not in classDict:
            return ObjcException('__objcclass__ definition missing')

        cdef bytes __objcclass__ = <bytes>classDict['__objcclass__']
        cdef ObjcClassStorage storage = ObjcClassStorage()

        storage.o_cls = objc_getClass(__objcclass__)
        if storage.o_cls == NULL:
            raise ObjcException('Unable to found the class {0!r}'.format(
                __objcclass__))

        classDict['__cls_storage'] = storage

        cdef ObjcMethod om
        for name, value in classDict.iteritems():
            if isinstance(value, ObjcMethod):
                om = value
                if not om.is_static:
                    continue
                om.set_resolve_info(name, storage.o_cls, NULL)

        # FIXME do the static fields resolution


cdef class ObjcMethod(object):
    cdef bytes name
    cdef bytes signature
    cdef int is_static
    cdef object signature_return
    cdef object signature_args
    cdef Class o_cls
    cdef id o_instance

    def __cinit__(self, signature, **kwargs):
        pass

    def __init__(self, signature, **kwargs):
        super(ObjcMethod, self).__init__()
        self.signature = <bytes>signature
        self.signature_return, self.signature_args = parse_signature(signature)
        print 'RESOLVE', self.signature_return, self.signature_args
        self.is_static = kwargs.get('static', False)

    cdef void set_resolve_info(self, bytes name, Class o_cls, id o_instance) except *:
        self.name = name.replace(":", "_")
        self.o_cls = o_cls
        self.o_instance = o_instance

    cdef void ensure_method(self) except *:
        pass

    def __get__(self, obj, objtype):
        if obj is None:
            return self
        cdef ObjcClass oc = obj
        self.o_instance = oc.o_instance
        return self

    def __call__(self, *args):
        self.ensure_method()
        print '--> want to call', self.name, args
        print '--> return def is', self.signature_return
        print '--> args def is', self.signature_args

        cdef ffi_cif cif
        cdef ffi_status f_status
        #cdef farg f_result
        cdef void* f_result
        cdef ffi_type* f_result_type
        cdef void **f_args
        cdef ffi_type **f_arg_types
        cdef int index
        cdef size_t size


        #get return type type as ffitype*
        f_result_type = type_encoding_to_ffitype(self.signature_return)
        
        #allocate memory to hold ffitype* of arguments
        size = sizeof(ffi_type) * len(self.signature_args)
        f_arg_types = <ffi_type **>malloc(size)
        if f_arg_types == NULL:
            raise MemoryError()

        # populate f_args_type array for FFI prep
        index = 0
        for arg in self.signature_args:
            f_arg_types[index] = type_encoding_to_ffitype(arg)
            print "argtype: {0}  size:{1}".format(arg, f_arg_types[index][0].size)
            index = index + 1

        # FFI PREP 
        f_status = ffi_prep_cif(&cif,FFI_DEFAULT_ABI,
                len(self.signature_args),f_result_type, f_arg_types)
        if f_status != FFI_OK:
            raise ObjcException('Unable to prepare the method...')

        print "prep status: {0}".format(f_status)

        #allocate result buffer
        print "allocating f_result with size {0}".format(f_result_type[0].size)
        f_result = malloc(f_result_type[0].size)
        if f_result == NULL:
            raise MemoryError()

        # allocate f_args
        print "allocatinf f_args for {0} args".format(len(self.signature_args))
        f_args = <void**>malloc(sizeof(void*) * (len(self.signature_args)))
        if f_args == NULL:
            raise MemoryError()

        # arg 0 and 1 are the instance and the method selector
        cdef SEL selector = sel_registerName(self.name)
        f_args[0] = &self.o_instance
        f_args[1] = &selector

        #populate the rest of f_args based on method signature
        cdef void* val_ptr
        for index in range(2, len(self.signature_args)):
            # argument passed to call
            arg = args[index-2]

            # we already know the ffitype/size being used
            val_ptr = <void*>malloc(f_arg_types[index][0].size*2)
            print "allocating {0} bytes for arg:".format(f_arg_types[index][0].size, arg)

            # cast the argument type based on method sig and store at val_ptr
            sig, offset = self.signature_args[index]
            if sig == 'c':
                (<char*>val_ptr)[0] = bytes(arg)
            elif sig == 'i':
                (<int*>val_ptr)[0] = <int> int(arg)
            elif sig == 's':
                (<short*>val_ptr)[0] = <short> int(arg)
            elif sig == 'Q':
                (<unsigned long long*>val_ptr)[0] = <unsigned long long> long(arg)
            else:
                (<int*>val_ptr)[0] = 0
            print "fargs[{0}] = {1}, {2}".format(index, sig, arg)

            f_args[index] = val_ptr


        #cdef objc_selector
        ffi_call(&cif, <void(*)()>objc_msgSend, f_result, f_args)
        cdef id ret = (<id*>f_result)[0]
        #cdef id ret = objc_msgSend(f_args[0],  <SEL>f_args[1])
        print "return {0}".format(<int>ret)
        #drainAutoreleasePool(pool)
        #cdef char* ret_str = <char*> f_result
        return "hello"



cdef class ObjcClass(object):
    cdef Class o_cls
    cdef id o_instance

    def __cinit__(self, *args, **kwargs):
        self.o_cls = NULL
        self.o_instance = NULL

    def __init__(self, *args, **kwargs):
        super(ObjcClass, self).__init__()
        cdef ObjcClassStorage storage = self.__cls_storage
        self.o_cls = storage.o_cls

        if 'noinstance' not in kwargs:
            self.call_constructor(args)
            self.resolve_methods()
            self.resolve_fields()

    def __dealloc__(self):
        if self.o_instance != NULL:
            objc_msgSend(self.o_instance, sel_registerName('release'))
            self.o_instance = NULL

    cdef void instanciate_from(self, id o_instance) except *:
        self.o_instance = o_instance
        self.resolve_methods()
        self.resolve_fields()

    cdef void call_constructor(self, args) except *:
        self.o_instance = class_createInstance(self.o_cls, 0);
        self.o_instance = objc_msgSend(self.o_cls, sel_registerName('alloc'))
        if self.o_instance == NULL:
            raise ObjcException('Unable to instanciate {0}'.format(
                self.__javaclass__))
        self.o_instance = objc_msgSend(self.o_instance,
            sel_registerName('init'))


    cdef void resolve_methods(self) except *:
        cdef ObjcMethod om
        for name, value in self.__class__.__dict__.iteritems():
            if isinstance(value, ObjcMethod):
                om = value
                if om.is_static:
                    continue
                om.set_resolve_info(name, self.o_cls, self.o_instance)

    cdef void resolve_fields(self) except *:
        pass


