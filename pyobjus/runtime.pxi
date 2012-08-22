cdef extern from "objc/runtime.h":

    ctypedef struct objc_selector:
        pass


    ctypedef objc_selector* SEL
    ctypedef void* id
    ctypedef void* Class
    ctypedef void* Method

    id       objc_getClass(const_char_ptr name)
    id       objc_getRequiredClass(const_char_ptr)
    id       objc_msgSend(id, objc_selector *, ...)


    id       class_createInstance(Class cls, unsigned int)
    Method*  class_copyMethodList(Class cls, unsigned int *outCount)

    SEL sel_registerName(char *)


cdef extern from "_runtime.h":
    void  pyobjc_internal_init()
    id    allocAndInitAutoreleasePool()
    void  drainAutoreleasePool(id pool)

