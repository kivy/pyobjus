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
    const_char_ptr class_getName(Class cls)

    SEL sel_registerName(char *)
    SEL method_getName(Method)
    const_char_ptr sel_getName(SEL)
    const_char_ptr method_getTypeEncoding(Method)

    Class    object_getClass(id obj)
    const_char_ptr object_getClassName(id obj)


cdef extern from "_runtime.h":
    void  pyobjc_internal_init()
    id    allocAndInitAutoreleasePool()
    void  drainAutoreleasePool(id pool)

