'''
Type documentation: https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html
'''

__all__ = ('ObjcClass', 'ObjcMethod', 'MetaObjcClass', 'ObjcException',
    'autoclass')


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
    cdef SEL selector 
    cdef SEL *selectors

    cdef int is_ready
    cdef ffi_cif f_cif
    cdef ffi_type* f_result_type
    cdef ffi_type **f_arg_types

    def __cinit__(self, signature, **kwargs):
        self.is_ready = 0
        self.f_result_type = NULL
        self.f_arg_types = NULL
        self.name = None
        self.selector = NULL
        self.selectors = NULL

    def __dealloc__(self):
        self.is_ready = 0
        if self.f_result_type != NULL:
            free(self.f_result_type)
            self.f_result_type = NULL
        if self.f_arg_types != NULL:
            free(self.f_arg_types)
            self.f_arg_types = NULL

    def __init__(self, signature, **kwargs):
        super(ObjcMethod, self).__init__()
        self.signature = <bytes>signature
        self.signature_return, self.signature_args = parse_signature(signature)
        print 'RESOLVE', self.signature_return, self.signature_args
        self.is_static = kwargs.get('static', False)
        self.name = kwargs.get('name')

        py_selectors = kwargs.get('selectors', [])
        if len(py_selectors):
            self.selectors = <SEL *>malloc(sizeof(SEL) * len(py_selectors))
            for index, name in enumerate(py_selectors):
                self.selectors[index] = sel_registerName(<bytes>name)

    cdef void set_resolve_info(self, bytes name, Class o_cls, id o_instance) except *:
        self.name = self.name or name.replace("_", ":")
        self.selector = sel_registerName(<bytes>self.name)
        self.o_cls = o_cls
        self.o_instance = o_instance

    cdef void ensure_method(self) except *:
        if self.is_ready:
            return

        # get return type type as ffitype*
        self.f_result_type = type_encoding_to_ffitype(self.signature_return)

        # allocate memory to hold ffitype* of arguments
        cdef int size = sizeof(ffi_type) * len(self.signature_args)
        self.f_arg_types = <ffi_type **>malloc(size)
        if self.f_arg_types == NULL:
            raise MemoryError()

        # populate f_args_type array for FFI prep
        cdef int index = 0
        for arg in self.signature_args:
            self.f_arg_types[index] = type_encoding_to_ffitype(arg)
            index = index + 1

        # FFI PREP 
        cdef ffi_status f_status
        f_status = ffi_prep_cif(&self.f_cif, FFI_DEFAULT_ABI,
                len(self.signature_args), self.f_result_type, self.f_arg_types)
        if f_status != FFI_OK:
            raise ObjcException(
                    'Unable to prepare the method {0!r}'.format(self.name))

        self.is_ready = 1


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

        cdef void *f_result
        cdef void **f_args
        cdef int index
        cdef size_t size

        # allocate result buffer
        f_result = malloc(self.f_result_type[0].size)
        if f_result == NULL:
            raise MemoryError('Unable to allocate f_result')

        # allocate f_args
        f_args = <void**>malloc(sizeof(void *) * len(self.signature_args))
        if f_args == NULL:
            free(f_result)
            raise MemoryError('Unable to allocate f_args')

        # arg 0 and 1 are the instance and the method selector
        f_args[0] = &self.o_instance
        f_args[1] = &self.selector
        print ' - selector is', <unsigned long>self.selector

        # populate the rest of f_args based on method signature
        cdef void* val_ptr
        f_index = 1
        for index in range(2, len(self.signature_args)):
            # argument passed to call
            arg = args[index-2]

            # we already know the ffitype/size being used
            val_ptr = <void*>malloc(self.f_arg_types[index][0].size)
            print "allocating {0} bytes for arg:".format(self.f_arg_types[index][0].size, arg)

            # cast the argument type based on method sig and store at val_ptr
            sig, offset, attr = self.signature_args[index]
            if sig == 'c':
                (<char*>val_ptr)[0] = bytes(arg)
            elif sig == 'i':
                (<int*>val_ptr)[0] = <int> int(arg)
            elif sig == 's':
                (<short*>val_ptr)[0] = <short> int(arg)
            elif sig == 'Q':
                (<unsigned long long*>val_ptr)[0] = <unsigned long long> long(arg)
            elif sig == '*':
                (<char **>val_ptr)[0] = <char *><bytes>arg
                #val_ptr = <char*><bytes>arg
            else:
                (<int*>val_ptr)[0] = 0
            print "fargs[{0}] = {1}, {2!r}".format(index, sig, arg)

            f_index += 1
            f_args[f_index] = self.selectors[index-2]
            f_index += 1
            f_args[f_index] = val_ptr


        ffi_call(&self.f_cif, <void(*)()>objc_msgSend, f_result, f_args)
        sig = self.signature_return[0]
        cdef id ret_id
        if sig == '@':
            ret_id = (<id*>f_result)[0]
            if ret_id == self.o_instance:
                return self
            assert(0)
        elif sig == 'c':
            return (<char*>f_result)[0]
        elif sig == 'i':
            return (<int *>f_result)[0]
        elif sig == 's':
            return (<short*>f_result)[0]
        elif sig == 'l':
            return (<long*>f_result)[0]
        elif sig == 'q':
            return (<long long*>f_result)[0]
        elif sig == 'C':
            return (<unsigned char*>f_result)[0]
        elif sig == 'I':
            return (<unsigned int*>f_result)[0]
        elif sig == 'S':
            return (<unsigned short*>f_result)[0]
        elif sig == 'L':
            return (<unsigned long*>f_result)[0]
        elif sig == 'Q':
            return (<unsigned long long*>f_result)[0]
        elif sig == 'f':
            return (<float*>f_result)[0]
        elif sig == 'd':
            return (<double*>f_result)[0]
        elif sig == 'b':
            return (<bool*>f_result)[0]
        elif sig == 'v':
            return None
        elif sig == '*':
            return <bytes>(<char**>f_result)[0]
        elif sig == '@':
            # id ?return (<long*>f_result)[0]
            pass
        elif sig == '#':
            # class ?
            pass
        elif sig == ':':
            # selector ? but as a return ?
            pass
        elif sig[0] == '[':
            # array
            pass
        elif sig[0] == '{':
            # array
            pass
        elif sig[0] == '(':
            # union
            pass
        elif sig == 'b':
            # bitfield
            pass
        elif sig[0] == '^':
            # pointer to type
            pass
        elif sig == '?':
            # unknown type
            pass

        else:
            assert(0)



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


registers = []

def ensureclass(clsname):
    if clsname in registers:
        return
    objcname = clsname.replace('.', '/')
    if MetaObjcClass.get_objcclass(objcname):
        return
    registers.append(clsname)
    autoclass(clsname)


def autoclass(clsname):
    cls = MetaObjcClass.get_objcclass(clsname)
    if cls:
        return cls

    classDict = {}

    #c = find_objcclass(clsname)
    #if c is None:
    #    raise Exception('Java class {0} not found'.format(c))
    #    return None

    cdef unsigned int index, num_methods
    cdef id clsid = objc_getClass(<bytes>clsname)
    cdef char *method_name
    cdef char *method_args
    cdef bytes nmae
    cdef Method* class_methods = class_copyMethodList(clsid, &num_methods)
    for index in xrange(num_methods):
        method_name = sel_getName(method_getName(class_methods[index]))
        method_args = method_getTypeEncoding(class_methods[index])
        name = <bytes>method_name
        print '->', name
        classDict[name] = ObjcMethod(<bytes>method_args)

    classDict['__objcclass__'] = clsname

    return MetaObjcClass.__new__(MetaObjcClass,
            clsname,
            (ObjcClass, ),
            classDict)

