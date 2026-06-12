#include <objc/runtime.h>
#include <objc/message.h>
#include <ffi/ffi.h>
#include <string.h>

static void pyobjc_internal_init() {
    // Foundation lives in the dyld shared cache on iOS 16+ and is linked
    // directly on macOS; dlopen by absolute path always fails there.
    // The ObjC runtime (objc_getClass, etc.) provides Foundation symbols
    // without an explicit dlopen handle, so nothing is needed here.
}

id allocAndInitAutoreleasePool() {
  Class NSAutoreleasePoolClass = (Class)objc_getClass("NSAutoreleasePool");
  id pool = class_createInstance(NSAutoreleasePoolClass, 0);
  return ((id (*)(id, SEL)) objc_msgSend)(pool, sel_registerName("init"));
}

void drainAutoreleasePool(id pool) {
  (void)((id (*)(id, SEL)) objc_msgSend)(pool, sel_registerName("drain")); 
}

id objc_msgSend_custom(id obj, SEL sel){
  return ((id (*)(id, SEL)) objc_msgSend)(obj, sel); 
}

#if TARGET_OS_OSX && TARGET_CPU_X86_64
  void objc_msgSend_stret__safe(id _Nullable self, SEL _Nonnull op){
      ((id (*)(id, SEL)) objc_msgSend_stret)(self, op);
  }

  bool MACOS_HAVE_OBJMSGSEND_STRET = true;
#else
  void objc_msgSend_stret__safe(id _Nullable self, SEL _Nonnull op){
  }

  bool MACOS_HAVE_OBJMSGSEND_STRET = false;
#endif

  ffi_status guarded_ffi_prep_cif_var(ffi_cif *_Nonnull cif, ffi_abi abi, unsigned int nfixedargs,
                                      unsigned int ntotalargs, ffi_type *_Nonnull rtype, ffi_type *_Nonnull *_Nonnull atypes)
  {
    if (ntotalargs > nfixedargs)
    {
      #if TARGET_OS_OSX
      if (__builtin_available(macOS 10.15, *))
      {
        return ffi_prep_cif_var(cif, abi, nfixedargs, ntotalargs, rtype, atypes);
      }
      #elif TARGET_OS_IOS
        return ffi_prep_cif_var(cif, abi, nfixedargs, ntotalargs, rtype, atypes);
      #endif
    }
    return ffi_prep_cif(cif, abi, ntotalargs, rtype, atypes);
  }