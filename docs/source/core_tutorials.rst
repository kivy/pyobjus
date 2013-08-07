.. _core_tutorials:

Pyobjus API tutorial
====================

This part of documentation covers tutorials related to API of pyobjus

Using dylib_manager
-------------------

As you now, you need to load code into pyobjus to it can actually find appropriate class with autoclass function.

Maybe you want to write some Objective C code, and you want to load it into pyobjus, or you want
to use some exising .dylib or sommething similar. 

This problems will solve pyobjus dylib_manager. Currently it has few functions, so let we see what we can do with 
them.

make_dylib and load_dylib functions
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

For the first example, let we say that we want to write our class in Objective C, and after that we want
to load that class into pyobjus. Okey, let write class::

    #import <Foundation/Foundation.h>

    @interface ObjcClass : NSObject {
    }
    - (void) printFromObjectiveC;
    @end

    @implementation ObjcClass

    - (void) printFromObjectiveC {
            printf("Hello from Objective C\n");
    }

    @end

Next step is to make .dylib for this class, and load that .dylib into pyobjus. Suppose that we save previous code 
into `objc_lib.m` file.

With pyobjus you can compile `objc_lib.m` into `objc_lib.dylib` in the following way::

    make_dylib('objc_lib.m', frameworks=['Foundation'], options=['-current_version', '1.0'])

With this we say to pyobjus to link `objc_lib.m` with Foundation framework, and we also say that we want to set
`-current_version` option to `1.0`. You can also specify others frameworks and options if you want, 
just add elements to array.

Previous command will result with `objc_lib.dylib` file in the same directory as the `objc_lib.m` file.
If you want to save it to another dir, and with different name, you can call make_dylib on this way::

    make_dylib('objc_lib.m', frameworks=['Foundation'], out='/path/to/dylib/dylib_name.dylib')

After you make .dylib with make_dylib function, you can load code from .dylib into pyobjus on following way::

    load_dylib('objc_lib.dylib')

    # or if you specified anothed loation and name for .dylib
    # load_dylib('/path/to/dylib/dylib_name.dylib')

Great, we have .dylib create, loaded into pyobjus, we can use ObjcClass from our `objc_lib.m` file::

    ObjcClass = autoclass('ObjcClass')
    o_instance = ObjcClass.alloc().init()
    o_instance.printFromObjectiveC()

This will output with::

    >>> Hello from Objective C

load_framework function
~~~~~~~~~~~~~~~~~~~~~~~

There often can be situations when you need to load classes into pyobjus which don't beolngs to 
Foundation framework, for example you want to load class from AppKit framework.

In that cases you have available load_framework function of dylib_manager.

So let see one simple example of using this function::

    from pyobjus.dylib_manager import load_framework, INCLUDE
    load_framework(INCLUDE.AppKit)

You may wonder what is the INCLUDE, and can we load all Frameworks on this way?
So INCLUDE is enum, which contains paths to Frameworks. Currently INCLUDE contains paths to following frameworks::

    Foundation = '/System/Library/Frameworks/Foundation.framework',
    AppKit = '/System/Library/Frameworks/AppKit.framework',
    UIKit = '/System/Library/Frameworks/UIKit.framework',
    CoreGraphich = '/System/Library/Frameworks/CoreGraphics.framework',
    CoreData = '/System/Library/Frameworks/CoreData.framework'

If Framework path which you want to load isn't present in INCLUDE enum, you can specify it manualy.
Let we say that path to AppKit isn't available via INCLUDE enum. You can load Framework on following way::

    load_framework('/System/Library/Frameworks/AppKit.framework')
