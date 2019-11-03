#include <objc/runtime.h>
#include <objc/message.h>
#include <stdio.h>
#include <dlfcn.h>
#include <string.h>

static void pyobjc_internal_init() {	

    static void *foundation = NULL;
    if ( foundation == NULL ) {
        foundation = dlopen(
        "/System/Library/Frameworks/Foundation.framework/Versions/Current/Foundation", RTLD_LAZY);
        if ( foundation == NULL ) {
           // Load from the most likely path fails. Log and try alternative
            char *msg = dlerror();
            printf("Got dlopen error on Foundation: %s\n", msg);

            foundation = dlopen(
            "/Groups/System/Library/Frameworks/Foundation.framework/Versions/Current/Foundation", RTLD_LAZY);
            if ( foundation == NULL ) {
                // 2nd fail
                msg = dlerror();
                printf("Got fallback dlopen error on Foundation: %s\n", msg);
                return;
            }
        }
    }
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
