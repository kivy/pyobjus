__all__ = ('ObjcClass', 'ObjcMethod', )

import re

cdef extern from *:
    ctypedef char* const_char_ptr "const char*"

cdef extern from "objc/runtime.h":
    
    ctypedef void* id
    ctypedef void* Class
    ctypedef void* Method

    id objc_getClass(const_char_ptr name)
    id objc_getRequiredClass(const_char_ptr)
    Method* class_copyMethodList(Class cls, unsigned int *outCount)

cdef extern from "common.h":
    void preload()
    id allocAndInitAutoreleasePool()
    void drainAutoreleasePool(id pool)

cdef unsigned int method_list_for_class():
    preload()
    cdef id pool = allocAndInitAutoreleasePool()
    cdef id _cls = objc_getRequiredClass("NSString")
    cdef Class cls = <Class>_cls
    cdef unsigned int num_methods = 0
    cdef Method* method_list = class_copyMethodList(cls, &num_methods)
    drainAutoreleasePool(pool)
    return num_methods


cpdef test():
    print method_list_for_class()

cdef parse_signature(bytes signature):
    parts = re.split('(\d±)', signature)[:-1]
    signature_return = parts[0:2]
    parts = parts[2:]
    signature_args = zip(parts[0::2], parts[1::2])
    return signature_return, signature_args


cdef class ObjcMethod(object):
    cdef bytes name
    cdef bytes signature
    cdef object signature_return
    cdef object signature_args

    def __cinit__(self, signature, **kwargs):
        pass

    def __init__(self, signature, **kwargs):
        super(ObjcMethod, self).__init__()
        self.signature = <bytes>signature
        self.signature_return, self.signature_args = parse_signature(signature)

    cdef void set_resolve_info(self, bytes name) except *:
        self.name = name

    cdef void ensure_method(self) except *:
        pass

    def __call__(self, *args):
        self.ensure_method()


cdef class ObjcClass(object):
    def __cinit__(self, *args, **kwargs):
        pass

    def __init__(self, *args, **kwargs):
        super(ObjcClass, self).__init__()

        if 'noinstance' not in kwargs:
            self.call_constructor(args)
            self.resolve_methods()
            self.resolve_fields()

    cdef void instanciate_from(self, o_self) except *:
        self.o_self = o_self
        self.resolve_methods()
        self.resolve_fields()

    cdef void call_constructor(self, args) except *:
        pass

    cdef void resolve_methods(self) except *:
        cdef ObjcMethod om
        for name, value in self.__class__.__dict__.iteritems():
            if isinstance(value, ObjcMethod):
                om = value
                om.set_resolve_info(name)

    cdef void resolve_fields(self) except *:
        pass

