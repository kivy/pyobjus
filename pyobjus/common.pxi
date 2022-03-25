cdef extern from *:
    ctypedef char* const_char_ptr "const char*"


cdef extern from "string.h":
  char *strcpy(char *dest, char *src)


cdef extern from "CoreFoundation/CoreFoundation.h":
    ctypedef struct CFRange:
        pass


cdef extern from "CoreGraphics/CoreGraphics.h":
    ctypedef struct CGPoint:
        float x
        float y
    ctypedef struct CGSize:
        float width
        float height
    ctypedef struct CGRect:
        CGPoint origin
        CGSize size


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
    id              objc_msgSend(id, SEL, ...)
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


cdef extern from "ffi/ffi.h":
    ctypedef unsigned long  ffi_arg
    ctypedef signed long    ffi_sarg
    ctypedef enum: FFI_TYPE_STRUCT
    ctypedef enum ffi_status:
        FFI_OK = 0,
        FFI_BAD_TYPEDEF,
        FFI_BAD_ABI

    ctypedef enum ffi_abi:
        FFI_FIRST_ABI = 0,
        FFI_SYSV,
        FFI_UNIX64,
        FFI_DEFAULT_ABI,
        FFI_LAST_ABI

    ctypedef struct ffi_cif:
        pass

    ctypedef struct ffi_type:
        size_t size
        unsigned short alignment
        unsigned short type
        ffi_type **elements

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

    cdef void        ffi_call(ffi_cif *cif, void (*fn)(), void *rvalue,
                        void **avalue)

cdef extern from "_runtime.h":
    void  pyobjc_internal_init()
    id    allocAndInitAutoreleasePool()
    void  drainAutoreleasePool(id pool)
    id    objc_msgSend_custom(id obj, SEL sel)
    void  objc_msgSend_stret__safe(id self, SEL selector, ...)
    bool  MACOS_HAVE_OBJMSGSEND_STRET
    ffi_status guarded_ffi_prep_cif_var(ffi_cif *cif, ffi_abi abi,
                                    unsigned int nfixedargs, unsigned int ntotalargs,
                                    ffi_type *rtype, ffi_type **atypes)