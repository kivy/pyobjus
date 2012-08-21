__all__ = ('ObjcClass', 'ObjcMethod', 'MetaObjcClass', 'ObjcException')

import re

cdef extern from *:
    ctypedef char* const_char_ptr "const char*"

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

cdef extern from "ffi.h":
    pass

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


cdef ffi_type *convert_objctype_to_ffitype(signature):
    sig, offset = signature
    if sig == 'c':
        return &ffi_type_uint8 
    elif sig == 'i':
        return &ffi_type_sint32
    elif sig == 's':
        return &ffi_type_sint16
    # ...
    elif sig == 'Q':
        return &ffi_type_uint64
    elif sig == '@':
        return &ffi_type_pointer
    elif sig == '#':
        return &ffi_type_pointer
    elif sig == ':':
        return &ffi_type_pointer

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
        self.name = name
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
        cdef id ret
        cdef bytes name = self.name

        cdef ffi_cif cif
        cdef ffi_type *f_args
        cdef ffi_status f_status
        cdef void *func_values, *func_result
        cdef int rc, index

        f_args = <ffi_type *>malloc(sizeof(ffi_type) * len(args))
        if f_args == NULL:
            raise MemoryError()
        for index, arg in args:
            f_args[index] = convert_objctype_to_ffitype(arg)

        # the first 2 args is from us: class or instance + selector
        # TODO static!
        f_status = ffi_prep_cif(&cif, FFI_DEFAULT_ABI, len(args) + 2,
                convert_objctype_to_ffitype(self.signature_return),
                f_args)

        if f_status != FFI_OK:
            free(f_args)
            raise ObjcException('Unable to prepare the method...')

        func_values = malloc()
        func_result = malloc(sizeof_from_objctype(self.signature_return))

        ffi_call(&cif, objc_msgSend, func_result, func_values)

        


        drainAutoreleasePool(pool)

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


