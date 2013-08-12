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

    int_ptr = o_cls.makeIntVoidPtr()
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

If you are fammiliar with Objective C literals you know that is great feature, because reduces amount of code to write.
You may wonder is there some equvivalent with pyobjus. Ansert is, YES.

I thing that next example will illustrate how to use pyobjus literals, and what are the Objective C equvivalents::

    from pyobjus import *

    # In following examples will be demonstrated pyobjus literals feature
    # First line will denote native objective c literals, and second pyobjus literls
    # SOURCE: http://clang.llvm.org/docs/ObjectiveCLiterals.html

    # NSNumber *theLetterZ = @'Z';          // equivalent to [NSNumber numberWithChar:'Z']
    objc_c('Z')

    # NSNumber *fortyTwo = @42;             // equivalent to [NSNumber numberWithInt:42]
    objc_i(42)

    # NSNumber *fortyTwoUnsigned = @42U;    // equivalent to [NSNumber numberWithUnsignedInt:42U]
    objc_ui(42)

    # NSNumber *fortyTwoLong = @42L;        // equivalent to [NSNumber numberWithLong:42L]
    objc_l(42)

    # NSNumber *fortyTwoLongLong = @42LL;   // equivalent to [NSNumber numberWithLongLong:42LL]
    objc_ll(42)

    # NSNumber *piFloat = @3.141592654F;    // equivalent to [NSNumber numberWithFloat:3.141592654F]
    objc_f(3.141592654)

    # NSNumber *piDouble = @3.1415926535;   // equivalent to [NSNumber numberWithDouble:3.1415926535]
    objc_d(3.1415926535)

    # NSNumber *yesNumber = @YES;           // equivalent to [NSNumber numberWithBool:YES]
    objc_b(True)

    # NSNumber *noNumber = @NO;             // equivalent to [NSNumber numberWithBool:NO]
    objc_b(False)

    # NSArray *array = @[ @"Hello", NSApp, [NSNumber numberWithInt:42] ];
    objc_arr(objc_str('Hello'), objc_str('some str'), objc_i(42))

    # NSDictionary *dictionary = @{
    #    @"name" : NSUserName(),
    #    @"date" : [NSDate date],
    #    @"processInfo" : [NSProcessInfo processInfo]
    # };
    objc_dict({
        'name': objc_str('User name'),
        'date': autoclass('NSDate').date(),
        'processInfo': autoclass('NSProcessInfo').processInfo()
    })

    # NSString *string = @"some string";
    objc_str('some string')

I think that you unserstand on which rules are build names for these literals. So we add prefix ``objc_``,
followed with letter/letters which denotes Objective C type, for examples i for ``int``, f for ``float``, arr for ``NSArray``, dict for ``NSDictionary``, etc...


Unknown types
-------------

Let we say that we have defined following structures in our ObjcClass.

Note that we arent specify type of structs, so they types will be missing in method signatures::

    typedef struct {
        float a;
        int b;
        NSRect rect;
    } unknown_str_new;

    typedef struct {
        int a;
        int b;
        NSRect rect;
        unknown_str_new u_str;
    } unknown_str;

Let play know. Suppose that we have defined following objective c method::

    - (unknown_str) makeUnknownStr {
        unknown_str str;
        str.a = 10;
        str.rect = NSMakeRect(20, 30, 40, 50);
        str.u_str.a = 2.0;
        str.u_str.b = 4;
        return str;
    }

Purpose of this method is to make unknown type struct, and assing some values to it's members
If you see debug logs of pyobjus, you will see that method returns following type::

    {?=ii{CGRect={CGPoint=dd}{CGSize=dd}}{?=fi{CGRect={CGPoint=dd}{CGSize=dd}}}}

From this we can see that method returns some type, which contains of two integers, and two structs. One of them
is ``CGRect``, and another is some unknown type, which contains of float, integer and ``CGRect`` struct
So, if user doesn't have defined this struct, pyobjus can generate this type for him. Let's call this function::

    ret_type = o_cls.makeUnknownStr()

But wait, how will pyobjus know about field names in struct, because from method signature we know 
only types, not actual names. Well, pyobjus will generate some 'random' names in alphabetical order.

In our case, first member will have name 'a', second will have name 'b', and third will have name ``CGRect``,
which is used because can help user as indicator of type is actual type is missing. Last one is another 
unknown type, so pyobjus will generate name for him and it will have name 'c'. 

Note that in case of CGRect, that memeber will have origin and size members, because he is already defined, 
and we know info about his members, but for last member, pyobjus will continue recursive generating names 
for it's members

Maybe you are asking yourself know, how you will know actual generated name, so pyobjus will help you about this.
There is getMembers function, which returns name and type of some field in struct::

    print ret_type.getMembers()

Python will output with::

    >>> [('a', <class 'ctypes.c_int'>), ('b', <class 'ctypes.c_int'>), ('CGRect', <class 'pyobjus.objc_py_types.NSRect'>), ('c', <class 'pyobjus.objc_py_types.UnknownType'>)]

If you want to provide your names for fields, you can do on this way::

    ret_type = o_cls.makeUnknownStr(members=['first', 'second', 'struct_field', 'tmp_field'])

And if we now run ``getMembers`` command, it will result with::

    [('first', <class 'ctypes.c_int'>), ('second', <class 'ctypes.c_int'>), ('struct_field', <class 'pyobjus.objc_py_types.NSRect'>), ('tmp_field', <class 'pyobjus.objc_py_types.UnknownType'>)]

If you don't need types, only names, you can call method in following way::

    print ret_type.getMembers(only_fields=True)

Python will output with::

    >>> ['a', 'b', 'CGRect', 'c']

Also, if you want to know only names, you can get it on following way::

    print ret_type.getMembers(only_types=True)

Python will output with::

    >>> [<class 'ctypes.c_int'>, <class 'ctypes.c_int'>, <class 'pyobjus.objc_py_types.NSRect'>, <class 'pyobjus.objc_py_types.UnknownType'>]

If you want to use returned type to pass it as argument to some function there will be some problems. 
Pyobjus is use ctypes structures, so we can get actual pointer to C structure from Python object,
but if we want to get working correct values of passed arg, we need to cast pointer to appropriate type.

If type is defined in ``pyobjus/objc_cy_types.pxi`` pyobjus will convert it for us, but if it isn't, we will need to convert
it by ourselfs, for example internaly in Objective C method where we are passing struct value. Lets see example of this::

    - (void) useUnknownStr:(void*)str_vp {
        unknown_str *str_p = (unknown_str*)str_vp;
        unknown_str str = str_p[0];
        printf("%f\n", str.rect.origin.x);
    }

And from Python::

    o_cls.useUnknownStr_(ret_type)

And Python will output with::

    >>> 20.00

Using class
-----------

As you know, ``class`` is Python keyword, so that might be a problem.

Let's we say that we want to get Class type for NSString instance...

We can use following::

    NSString = autoclass('NSString')
    text = NSString.alloc().init()
    text.oclass()

This will return::

    <pyobjus.ObjcClass object at 0x1057361b0>

So, now we can use isKindOfClass: method::

    text.isKindOfClass_(NSString)

This will output ``True``. Let we see another example::

    NSArray = autoclass('NSArray')
    text.isKindOfClass_(NSArray)

And this will output ``False``.

So, as you can see, if you want to use ``class`` with pyobjus, you will need to use ``some_object.oclass()`` method.

Using @selector
---------------

There may be situations when you need to use ``@selector``, which is Objective C feature. With pyobjus you can also get SEL type for some method. Let's we say that we want to get SEL for init method::

    from pyobjus import selector
    selector('init')

This will output with::

    <pyobjus.ObjcSelector object at 0x1057361c8>

So as you can see instead of using this ``@selector(init)`` with Objective C, you want use ``selector('init')`` with pyobjus and Python to get SEL type for some method.

If you want get SEL for initWithUTF8String: you can use::

    selector('initWithUTF8String:')

Other cases are the same for all methods.

Other
-----

Work in progress...
