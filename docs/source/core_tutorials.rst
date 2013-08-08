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


Using struct types
------------------

Pyobjus currently support ``NSRange``, ``NSPoint``, ``NSSize`` and ``NSRect`` structures. They are defined via ``ctypes.Structure`` type.

We will try to find best way to add your types into pyobjus, so that you can make and use functions which returns custom. Currently this is work in progress.

Consider following. You have Objective C class with name ObjcClass, and useRange: method of that class which is defined on this way::

    - (void) useRange:(NSRange)r {
        printf("location: %ld, length: %ld\n", r.location, r.length);
    }

So, if you want to call this method from Python, you can do sommething like this::

    from pyobjus.objc_py_types import NSRange
    from pyobjus import autoclass

    ObjcClass = autoclass('ObjcClass')
    o_cls = ObjcClass.alloc().init()
    range = NSRange(10, 20)
    o_cls.useRange_(range)

This will output with::

    >>> location: 10, length: 20

The simmilar situation is with returning and using Objective C structure types. Let we say that ObjcClass has another method, with name makeRange::

    - (NSRange) makeRange {
        NSRange range;
        range.length = 123;
        range.location = 456;
        return range;
    }

Using this method from Python is really simple. Let we say that we have includes from previous Python code example::

    range = o_cls.makeRange()
    print range.length
    print range.location

And this will output with::

    >>> 123
    >>> 456

As you can see dealing with Objective C structs from pyobjus is simple.

For the end of this section let see how to create NSRect type from example::

    point = NSPoint(30, 50)
    size = NSSize(60, 70)
    rect = NSRect(point, size)

Dealing with pointers
---------------------

As you now C has very powerful feature, with name pointers. Objective C is superset of C language, so it also has this great feature.

But wait, we are in Python, how we can deal with pointers from Python???

Passing pointers
~~~~~~~~~~~~~~~~

Relax, pyobjus is doing job for you here. I think that is the best to view some example of that. So, let we expand our ObjcClass class with another method::

    - (void) useRangePtr:(NSRange*)r_p {
        NSRange r = r_p[0];
        printf("location: %ld, length: %ld\n", r.location, r.length);
    }

In previous examples you saw example of making ``NSRange`` from Python, and you pass value of ``NSRange``. But now we have situation when method expect pointer to some type.

With pyobjus, you can call method on following way::

    range = NSRange(40, 80)
    o_cls.useRangePtr_(range)

And this will output::

    >>> location:40, length: 80

So what hapened here? We passes argument on the same way as with ``useRange:`` method.

Pyobjus will know if method accepts pointer to type, or accepts value. If accepts pointer to type it will make pointer, and put passed value to location on which pointer points,
so with this, you don't need to worry about, is using accepting pointer or actual value, pyobjus will do this conversion for you.

You can also return pointers to types from Objective C methods. Let we add another method to ObjcClass::

    - (NSRange*) makeRangePtr {
        NSRange *r_p = malloc(sizeof(NSRange));
        NSRange r;
        r.length = 123;
        r.location = 567;
        *r_p = r;
        return r_p;
    }

As you can see, this method is making ``NSRange`` pointer, assigning value to is, and at the end, it returns pointer to user.
From Python you can consume this method on this way::

    range_ptr = o_cls.makeRangePtr()
    # let we see actual type of returned object
    print range_ptr

This will output following::

    >>> <pyobjus.ObjcReferenceToType object at 0x10f34bcb0>

So here we can see another type -> ObjcReferenceToType. When we have method which returns pointer to some type, pyobjus will wrap that pointer with ObjcReferenceToType object,
so after return, that object now contains actual address of pointer. We can pass that type to function which accepts pointer to type.

Example::

    # note that range_ptr is of ObjcReferenceToType type
    o_cls.useRangePtr_(range_ptr)

But you may wonder now how to dereference pointer to get actual value?

Answer is....use dereference function

Dereferencing pointers
~~~~~~~~~~~~~~~~~~~~~~

To dereference pointer use dereference function::

    from pyobjus import dereference

If function returns pointer to some known type, with other words, type isn't void* you can use dereference function in this way::

    range_ptr = o_cls.makeRangePtr()
    range = dereference(range_ptr)

Pyobjus will parse return signature from method signature, so it will know in which type to convert pointer value.
If you return void pointer, you will need to specify type in which you want to pyobjus convert actual value on which pointer points.

Let we add method to out ObjcClass::

    - (void*) makeIntVoidPtr {
        int *a = malloc(sizeof(int));
        *a = 12345;
        return (void*)a;
    }

Now we can retrieve value, and dereference it::

    int_ptr = car.makeIntVoidPtr()
    int_val = dereference(int_ptr, of_type=ObjcInt)
    print int_val

This will output with::

    >>> 12345

Note that you can specify ``of_type`` optional argument although methods returns ``NSRange`` pointer. 
With this you will be sure that pyobjus will convert value to that type.

Here is the list of possible types::

    'ObjcChar', 
    'ObjcInt', 
    'ObjcShort', 
    'ObjcLong', 
    'ObjcLongLong', 
    'ObjcUChar', 
    'ObjcUInt', 
    'ObjcUShort', 
    'ObjcULong', 
    'ObjcULongLong', 
    'ObjcFloat', 
    'ObjcDouble', 
    'ObjcBool', 
    'ObjcBOOL', 
    'ObjcVoid', 
    'ObjcString', 
    'ObjcClassInstance', 
    'ObjcClass', 
    'ObjcSelector', 
    'ObjcMethod'

Above types resides inside pyobjus module, so you can import in on following way::

    from pyobjus import ObjcChar, ObjcInt # etc...

Inside ``pyobjus.objc_py_types`` module resides struct and unions types. Currently this is list of them::

    'NSRange',
    'NSPoint',
    'NSRect',
    'NSSize'

You can import them with::

    from pyobjus.objc_py_types import NSRange # etc...

Objective C <-> pyobjus literals
--------------------------------

