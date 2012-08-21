__all__ = ('ObjcClass', 'ObjcMethod', 'MetaObjcClass', 'ObjcException')

import re

cdef extern from *:
    ctypedef char* const_char_ptr "const char*"

cdef extern from "stdlib.h":
    void free(void* ptr)
    void* malloc(size_t size)
    void* realloc(void* ptr, size_t size)

cdef extern from "objc/runtime.h":
    ctypedef void* id
    ctypedef void* Class
    ctypedef void* Method
    ctypedef struct objc_selector:
        pass

    id objc_getClass(const_char_ptr name)
    id objc_getRequiredClass(const_char_ptr)
    Method* class_copyMethodList(Class cls, unsigned int *outCount)
    id class_createInstance(Class cls, unsigned int)

    id objc_msgSend(id, objc_selector *, ...)
    objc_selector *sel_registerName(char *)

cdef extern from "common.h":
    void pyobjc_internal_init()
    id allocAndInitAutoreleasePool()
    void drainAutoreleasePool(id pool)

cdef extern from "ffi/ffi.h":
    cdef enum ffi_status:
        FFI_OK = 0,
        FFI_BAD_TYPEDEF,
        FFI_BAD_ABI
    cdef enum ffi_abi:
        FFI_DEFAULT_ABI
    ctypedef struct ffi_cif:
        pass
    ctypedef struct ffi_type:
        size_t size
        unsigned short _type "type"

    cdef ffi_type ffi_type_void
    cdef ffi_type ffi_type_uint8
    cdef ffi_type ffi_type_sint8
    cdef ffi_type ffi_type_uint16
    cdef ffi_type ffi_type_sint16
    cdef ffi_type ffi_type_uint32
    cdef ffi_type ffi_type_sint32
    cdef ffi_type ffi_type_uint64
    cdef ffi_type ffi_type_sint64
    cdef ffi_type ffi_type_float
    cdef ffi_type ffi_type_double
    cdef ffi_type ffi_type_longdouble
    cdef ffi_type ffi_type_pointer

    cdef ffi_prep_cif(ffi_cif *cif, ffi_abi abi, unsigned int nargs,ffi_type *rtype, ffi_type **atypes)
    cdef ffi_call(ffi_cif *cif, void (*fn)(), void *rvalue, void **avalue)



cdef unsigned int method_list_for_class():
    pyobjc_internal_init()
    cdef id pool = allocAndInitAutoreleasePool()
    cdef id _cls = objc_getRequiredClass("NSString")
    cdef Class cls = <Class>_cls
    cdef unsigned int num_methods = 0
    cdef Method* method_list = class_copyMethodList(cls, &num_methods)
    drainAutoreleasePool(pool)
    return num_methods


# do the initialization!
pyobjc_internal_init()

cpdef test():
    print method_list_for_class()

def parse_signature(bytes signature):
    parts = re.split('(\d+)', signature)[:-1]
    signature_return = parts[0:2]
    parts = parts[2:]
    signature_args = zip(parts[0::2], parts[1::2])
    return signature_return, signature_args



cpdef convert_objctype_arg(signature, arg):
    sig, offset = signature
    if sig == 'c':
        return <char> bytes(arg)
    elif sig == 'i':
        return <int> int(arg)
    elif sig == 's':
        return <short> int(arg)
    elif sig == 'l':
        return <long> int(arg)
    elif sig == 'q':
        return <long long> long(arg)
    elif sig == 'C':
        return <unsigned char> bytes(arg)
    elif sig == 'I':
        return <unsigned int> int(arg)
    elif sig == 'S':
        return <unsigned short> int(arg)
    elif sig == 'L':
        return <unsigned long> long(arg)
    elif sig == 'Q':
        return <unsigned long long> long(arg)
    elif sig == 'f':
        return <float> float(arg)
    elif sig == 'd':
        return <double> float(arg)
    elif sig == 'B':
        v = False
        if arg:
            v = True
        return <unsigned char> v
    else:
        return arg
    """
    elif sig == '*':
        return arg
    elif sig == '@':
        return arg
    elif sig == '#':
        return arg
    elif sig == ':':
        return arg
    """



cdef ffi_type* convert_objctype_to_ffitype(signature):
    sig, offset = signature
    if sig == 'c':
        return &ffi_type_uint8
    elif sig == 'i':
        return &ffi_type_sint32
    elif sig == 's':
        return &ffi_type_sint16
    elif sig == 'l':
        return &ffi_type_sint32
    elif sig == 'q':
        return &ffi_type_sint64
    elif sig == 'C':
        return &ffi_type_uint8
    elif sig == 'I':
        return &ffi_type_uint32
    elif sig == 'S':
        return &ffi_type_uint16
    elif sig == 'L':
        return &ffi_type_uint32
    elif sig == 'Q':
        return &ffi_type_uint64
    elif sig == 'f':
        return &ffi_type_float
    elif sig == 'd':
        return &ffi_type_double
    elif sig == 'B':
        return &ffi_type_sint8
    elif sig == '*':
        return &ffi_type_pointer
    elif sig == '@':
        return &ffi_type_pointer
    elif sig == '#':
        return &ffi_type_pointer
    elif sig == ':':
        return &ffi_type_pointer
    #TODO: missing encodings:
    #[array type]	An array
    #{name=type...}	A structure
    #(name=type...)	A union
    #bnum	A bit field of num bits
    #^type	A pointer to type
    #?	An unknown type (among other things, 
    #   this code is used for function pointers)


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

        cdef id pool = allocAndInitAutoreleasePool()
        cdef bytes name = self.name

        cdef ffi_cif cif
        cdef ffi_status f_status
        cdef void *f_result
        cdef ffi_type* f_result_type
        cdef void **f_args
        cdef ffi_type **f_arg_types
        cdef int index
        cdef size_t size
        
        # create array of ffi_type describing type of each argument
        size = sizeof(ffi_type) * len(self.signature_args)
        f_arg_types = <ffi_type **>malloc(size)
        if f_arg_types == NULL:
            raise MemoryError()

        # populate f_args_type array for FFI prep and keep track
        # of arg sizees to allocate f_args array while we are at it
        index = 0
        for arg in self.signature_args:
            f_arg_types[index] = convert_objctype_to_ffitype(arg)
            index = index + 1
        
        # FFI PREP 
        # the first 2 args is from us: class or instance + selector
        # but they are included in signature args
        # TODO static!
        f_result_type = convert_objctype_to_ffitype(self.signature_return)
        f_status = ffi_prep_cif(&cif, FFI_DEFAULT_ABI,
                len(self.signature_args),f_result_type, f_arg_types)
        if f_status != FFI_OK:
            free(f_args)
            raise ObjcException('Unable to prepare the method...')
        
        #allocate result buffer
        f_result = malloc(f_result_type.size)
        if f_result == NULL:
            raise MemoryError()



        # allocate f_args
        f_args = <void**>malloc(sizeof(void*) * len(self.signature_args))
        if f_args == NULL:
            raise MemoryError()

        #populate f_args
        f_args[0] = &self.o_instance
        f_args[1] = sel_registerName(self.name)

        cdef char cv
        cdef int iv
        cdef short sv
        cdef unsigned long long ullv
        #...
        
        for index in range(2, len(self.signature_args)):
            arg = args[index]
            sig, offset = self.signature_args[index]
            if sig == 'c':
                cv = bytes(arg)
                f_args[index] = &cv
            elif sig == 'i':
                iv =  int(arg)
                f_args[index] = &iv
            elif sig == 's':
                sv =  int(arg)
                f_args[index] = &sv
            elif sig == 'Q':
                ullv =  long(arg)
                f_args[index] = &ullv
        """
        ffi_call(&cif, <void(*)()>objc_msgSend, f_result, f_args)
        """
        drainAutoreleasePool(pool)
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
        #self.o_instance = class_createInstance(self.o_cls, 0);
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


