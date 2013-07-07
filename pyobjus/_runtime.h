#include <objc/runtime.h>
#include <objc/objc-runtime.h>
#include <stdio.h>
#include <dlfcn.h>
#include <string.h>

static void pyobjc_internal_init() {	

    static void *foundation = NULL;
    static void *user_framework = NULL;

    chdir("cd ../");
    char *cwd;
    if ((cwd = getcwd(NULL, 64)) == NULL) {
        perror("pwd");
        exit(2);
    }
    // user lib for testing method signatures
    strcat(cwd, "/objc_usr_classes/usrlib.dylib");

    if ( foundation == NULL ) {
        foundation = dlopen(
        "/Groups/System/Library/Frameworks/Foundation.framework/Versions/Current/Foundation", RTLD_LAZY);
        if ( foundation == NULL ) {
            printf("Got dlopen error on Foundation\n");
            return;
        }
    }

	if ( user_framework == NULL ) {
		user_framework = dlopen(
			cwd, RTLD_LAZY);
		if ( user_framework == NULL ) {
			printf("Got dlopen error on user framework\n");
			return;
		}
	}
    free(cwd);
}

id allocAndInitAutoreleasePool() {
  Class NSAutoreleasePoolClass = (Class)objc_getClass("NSAutoreleasePool");
  id pool = class_createInstance(NSAutoreleasePoolClass, 0);
  return objc_msgSend(pool, sel_registerName("init"));
}

void drainAutoreleasePool(id pool) {
  (void)objc_msgSend(pool, sel_registerName("drain"));
}
