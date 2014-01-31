cdef extern from "stdarg.h":
    ctypedef struct va_list:
        pass
    ctypedef struct fake_type:
        pass
    void va_start(va_list, void* arg)
    void* va_arg(va_list, fake_type)
    void va_end(va_list)
    fake_type id_type "id"

cdef extern from "objc/objc.h":

    ctypedef enum: YES
    ctypedef enum: NO

cdef extern from "objc/runtime.h":

    ctypedef signed char BOOL

    ctypedef struct objc_selector:
        pass
    ctypedef objc_selector* SEL

    ctypedef struct objc_ivar:
        pass
    ctypedef objc_ivar* Ivar

    cdef struct objc_method_description:
        SEL name
        char* types

    ctypedef struct objc_property:
        pass
    ctypedef objc_property* objc_property_t
    ctypedef objc_property* Property

    ctypedef void* id
    ctypedef void* Class
    ctypedef void* Method
    ctypedef void* Protocol

    ctypedef id(*IMP)(id, SEL, ...)

    id              objc_allocateClassPair(Class superclass, const_char_ptr name, size_t extraBytes)
    id              objc_getClass(const_char_ptr name)
    id              objc_getRequiredClass(const_char_ptr)
    id              objc_msgSend(id, objc_selector *, ...)
    void            objc_msgSend_stret(id self, SEL selector, ...)
    void            objc_registerClassPair(Class cls)

    BOOL            class_addMethod(Class cls, SEL name, IMP imp, const char *types)
    id              class_createInstance(Class cls, unsigned int)
    Method*         class_copyMethodList(Class cls, unsigned int *outCount)
    const_char_ptr  class_getName(Class cls)
    Method          class_getClassMethod(Class cls, SEL selector)
    Method          class_getInstanceMethod(Class aClass, SEL aSelector)
    Method          class_getSuperclass(Class cls)
    Ivar*           class_copyIvarList(Class cls, unsigned int *outCount)
    objc_property_t* class_copyPropertyList(Class cls, unsigned int *outCount)
    Ivar            class_getInstanceVariable(Class cls, const_char_ptr name)

    Protocol*       objc_getProtocol(const_char_ptr name)

    const_char_ptr  ivar_getName(Ivar ivar)
    const_char_ptr  ivar_getTypeEncoding(Ivar ivar)

    SEL             sel_registerName(char *)
    const_char_ptr  sel_getName(SEL)

    SEL             method_getName(Method)
    const_char_ptr  method_getTypeEncoding(Method)
    const_char_ptr  method_copyArgumentType(Method method, int)
    objc_method_description* method_getDescription(Method m)

    Class           object_getClass(id obj)
    const_char_ptr  object_getClassName(id obj)
    id              object_getIvar(id object, Ivar ivar)
    Ivar            object_getInstanceVariable(id obj, const_char_ptr name, void **outValue)
    Ivar            object_setInstanceVariable(id obj, const_char_ptr name, void *value)
    void            object_setIvar(id object, Ivar ivar, id value)

    const_char_ptr  property_getAttributes(objc_property_t property)
    const_char_ptr  property_getName(objc_property_t property)
    objc_method_description* protocol_copyMethodDescriptionList(Protocol *p, BOOL isRequiredMethod, BOOL isInstanceMethod, unsigned int *outCount)

cdef extern from "_runtime.h":
    void  pyobjc_internal_init()
    id    allocAndInitAutoreleasePool()
    void  drainAutoreleasePool(id pool)
