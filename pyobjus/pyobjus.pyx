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

