cdef extern from "objc/runtime.h":

    ctypedef struct objc_selector:
        pass
    ctypedef objc_selector* SEL
    ctypedef void* id
    ctypedef void* Class
    ctypedef void* Method

    id              objc_getClass(const_char_ptr name)
    id              objc_getRequiredClass(const_char_ptr)
    id              objc_msgSend(id, objc_selector *, ...)


    id              class_createInstance(Class cls, unsigned int)
    Method*         class_copyMethodList(Class cls, unsigned int *outCount)
    const_char_ptr  class_getName(Class cls)
    Method          class_getClassMethod(Class cls, SEL selector)
    Method          class_getSuperclass(Class cls)

    SEL             sel_registerName(char *)
    const_char_ptr  sel_getName(SEL)
    
    SEL             method_getName(Method)
    const_char_ptr  method_getTypeEncoding(Method)
    const_char_ptr  method_copyArgumentType(Method method, int)

    Class           object_getClass(id obj)
    const_char_ptr  object_getClassName(id obj)

cdef extern from "_runtime.h":
    void  pyobjc_internal_init()
    id    allocAndInitAutoreleasePool()
    void  drainAutoreleasePool(id pool)

# Needed for vararg methods --> Currently NOT working
#cdef extern from "stdarg.h":
#    ctypedef struct va_list:
#        pass
#    ctypedef struct objc_type:
#        pass
#    void va_start(va_list, id arg)
#    void *va_arg(va_list, objc_type)
#    void va_end(va_list)
#    void va_copy(va_list, va_list)
#    objc_type id_type "id"



