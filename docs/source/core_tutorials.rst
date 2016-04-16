.. _core_tutorials:

Pyobjus API tutorial
====================

This part of documentation covers tutorials related to API of pyobjus

Using dylib_manager
-------------------

You need to load code into pyobjus so it can actually find the appropriate
class with the autoclass function.

Maybe you want to write some Objective C code, and you want to load it into
pyobjus, or you want to use some exising `.dylib` or sommething similar. 

These problems can be solved using the pyobjus dylib_manager. Currently it has
a few functions, so let's see what we can do with them.

make_dylib and load_dylib functions
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

For the first example, let's say that we want to write our class in Objective
C, and after that we want to load that class into pyobjus. Okay, let's write
a class::

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

The next step is to make a .dylib for this class, and load that .dylib into
pyobjus. Suppose that we have previously saved this code into an `objc_lib.m`
file.

With pyobjus you can compile `objc_lib.m` into `objc_lib.dylib` in the
following way::

    make_dylib('objc_lib.m', frameworks=['Foundation'], options=['-current_version', '1.0'])

Here, we are asking pyobjus to link `objc_lib.m` with the Foundation framework,
and that we want to set the `-current_version` option to `1.0`. You can also
specify others frameworks and options if you want by just adding these
elements to array.

The previous command will create an `objc_lib.dylib` file in the same directory
as the `objc_lib.m` file. If you want to save it to another directory
or with a different name, you can call `make_dylib` in this way::

    make_dylib('objc_lib.m', frameworks=['Foundation'], out='/path/to/dylib/dylib_name.dylib')

After you make a .dylib with make_dylib function, you can load the code from
the .dylib into pyobjus on following way::

    load_dylib('objc_lib.dylib')

    # or if you specified anothed loation and name for .dylib
    # load_dylib('/path/to/dylib/dylib_name.dylib')

Great, we have created a .dylib, loaded it into pyobjus and can now use the
ObjcClass from our `objc_lib.m` file::

    ObjcClass = autoclass('ObjcClass')
    o_instance = ObjcClass.alloc().init()
    o_instance.printFromObjectiveC()

This will output with::

    >>> Hello from Objective C

load_framework function
~~~~~~~~~~~~~~~~~~~~~~~

There often can be situations when you need to load classes into pyobjus which
don't belong to the Foundation framework. For example, say you want to load a
class from the AppKit framework.

In these cases you can use the load_framework function of dylib_manager.

So let's see one simple example of using this function::

    from pyobjus.dylib_manager import load_framework, INCLUDE
    load_framework(INCLUDE.AppKit)

You may wonder what INCLUDE is, and can we load all Frameworks in this way?
So INCLUDE is an enum, which contains paths to various Frameworks. Currently,
INCLUDE contains paths to the following frameworks::

    Accelerate = '/System/Library/Frameworks/Accelerate.framework',
    Accounts = '/System/Library/Frameworks/Accounts.framework',
    AddressBook = '/System/Library/Frameworks/AddressBook.framework',
    AGL = '/System/Library/Frameworks/AGL.framework',
    AppKit = '/System/Library/Frameworks/AppKit.framework',
    AppKitScripting = '/System/Library/Frameworks/AppKitScripting.framework',
    AppleScriptKit = '/System/Library/Frameworks/AppleScriptKit.framework',
    AppleScriptObjC = '/System/Library/Frameworks/AppleScriptObjC.framework',
    AppleShareClientCore = '/System/Library/Frameworks/AppleShareClientCore.framework',
    AppleTalk = '/System/Library/Frameworks/AppleTalk.framework',
    ApplicationServices = '/System/Library/Frameworks/ApplicationServices.framework',
    AudioToolbox = '/System/Library/Frameworks/AudioToolbox.framework',
    AudioUnit = '/System/Library/Frameworks/AudioUnit.framework',
    AudioVideoBridging = '/System/Library/Frameworks/AudioVideoBridging.framework',
    Automator = '/System/Library/Frameworks/Automator.framework',
    AVFoundation = '/System/Library/Frameworks/AVFoundation.framework',
    CalendarStore = '/System/Library/Frameworks/CalendarStore.framework',
    Carbon = '/System/Library/Frameworks/Carbon.framework',
    CFNetwork = '/System/Library/Frameworks/CFNetwork.framework',
    Cocoa = '/System/Library/Frameworks/Cocoa.framework',
    Collaboration = '/System/Library/Frameworks/Collaboration.framework',
    CoreAudio = '/System/Library/Frameworks/CoreAudio.framework',
    CoreAudioKit = '/System/Library/Frameworks/CoreAudioKit.framework',
    CoreData = '/System/Library/Frameworks/CoreData.framework',
    CoreFoundation = '/System/Library/Frameworks/CoreFoundation.framework',
    CoreGraphics = '/System/Library/Frameworks/CoreGraphics.framework',
    CoreLocation = '/System/Library/Frameworks/CoreLocation.framework',
    CoreMedia = '/System/Library/Frameworks/CoreMedia.framework',
    CoreMediaIO = '/System/Library/Frameworks/CoreMediaIO.framework',
    CoreMIDI = '/System/Library/Frameworks/CoreMIDI.framework',
    CoreMIDIServer = '/System/Library/Frameworks/CoreMIDIServer.framework',
    CoreServices = '/System/Library/Frameworks/CoreServices.framework',
    CoreText = '/System/Library/Frameworks/CoreText.framework',
    CoreVideo = '/System/Library/Frameworks/CoreVideo.framework',
    CoreWiFi = '/System/Library/Frameworks/CoreWiFi.framework',
    CoreWLAN = '/System/Library/Frameworks/CoreWLAN.framework',
    DirectoryService = '/System/Library/Frameworks/DirectoryService.framework',
    DiscRecording = '/System/Library/Frameworks/DiscRecording.framework',
    DiscRecordingUI = '/System/Library/Frameworks/DiscRecordingUI.framework',
    DiskArbitration = '/System/Library/Frameworks/DiskArbitration.framework',
    DrawSprocket = '/System/Library/Frameworks/DrawSprocket.framework',
    DVComponentGlue = '/System/Library/Frameworks/DVComponentGlue.framework',
    DVDPlayback = '/System/Library/Frameworks/DVDPlayback.framework',
    EventKit = '/System/Library/Frameworks/EventKit.framework',
    ExceptionHandling = '/System/Library/Frameworks/ExceptionHandling.framework',
    ForceFeedback = '/System/Library/Frameworks/ForceFeedback.framework',
    Foundation = '/System/Library/Frameworks/Foundation.framework',
    FWAUserLib = '/System/Library/Frameworks/FWAUserLib.framework',
    GameKit = '/System/Library/Frameworks/GameKit.framework',
    GLKit = '/System/Library/Frameworks/GLKit.framework',
    GLUT = '/System/Library/Frameworks/GLUT.framework',
    GSS = '/System/Library/Frameworks/GSS.framework',
    ICADevices = '/System/Library/Frameworks/ICADevices.framework',
    ImageCaptureCore = '/System/Library/Frameworks/ImageCaptureCore.framework',
    ImageIO = '/System/Library/Frameworks/ImageIO.framework',
    IMServicePlugIn = '/System/Library/Frameworks/IMServicePlugIn.framework',
    InputMethodKit = '/System/Library/Frameworks/InputMethodKit.framework',
    InstallerPlugins = '/System/Library/Frameworks/InstallerPlugins.framework',
    InstantMessage = '/System/Library/Frameworks/InstantMessage.framework',
    IOBluetooth = '/System/Library/Frameworks/IOBluetooth.framework',
    IOBluetoothUI = '/System/Library/Frameworks/IOBluetoothUI.framework',
    IOKit = '/System/Library/Frameworks/IOKit.framework',
    IOSurface = '/System/Library/Frameworks/IOSurface.framework',
    JavaFrameEmbedding = '/System/Library/Frameworks/JavaFrameEmbedding.framework',
    JavaScriptCore = '/System/Library/Frameworks/JavaScriptCore.framework',
    JavaVM = '/System/Library/Frameworks/JavaVM.framework',
    Kerberos = '/System/Library/Frameworks/Kerberos.framework',
    Kernel = '/System/Library/Frameworks/Kernel.framework',
    LatentSemanticMapping = '/System/Library/Frameworks/LatentSemanticMapping.framework',
    LDAP = '/System/Library/Frameworks/LDAP.framework',
    MediaToolbox = '/System/Library/Frameworks/MediaToolbox.framework',
    Message = '/System/Library/Frameworks/Message.framework',
    NetFS = '/System/Library/Frameworks/NetFS.framework',
    OpenAL = '/System/Library/Frameworks/OpenAL.framework',
    OpenCL = '/System/Library/Frameworks/OpenCL.framework',
    OpenDirectory = '/System/Library/Frameworks/OpenDirectory.framework',
    OpenGL = '/System/Library/Frameworks/OpenGL.framework',
    OSAKit = '/System/Library/Frameworks/OSAKit.framework',
    PCSC = '/System/Library/Frameworks/PCSC.framework',
    PreferencePanes = '/System/Library/Frameworks/PreferencePanes.framework',
    PubSub = '/System/Library/Frameworks/PubSub.framework',
    Python = '/System/Library/Frameworks/Python.framework',
    QTKit = '/System/Library/Frameworks/QTKit.framework',
    Quartz = '/System/Library/Frameworks/Quartz.framework',
    QuartzCore = '/System/Library/Frameworks/QuartzCore.framework',
    QuickLook = '/System/Library/Frameworks/QuickLook.framework',
    QuickTime = '/System/Library/Frameworks/QuickTime.framework',
    Ruby = '/System/Library/Frameworks/Ruby.framework',
    RubyCocoa = '/System/Library/Frameworks/RubyCocoa.framework',
    SceneKit = '/System/Library/Frameworks/SceneKit.framework',
    ScreenSaver = '/System/Library/Frameworks/ScreenSaver.framework',
    Scripting = '/System/Library/Frameworks/Scripting.framework',
    ScriptingBridge = '/System/Library/Frameworks/ScriptingBridge.framework',
    Security = '/System/Library/Frameworks/Security.framework',
    SecurityFoundation = '/System/Library/Frameworks/SecurityFoundation.framework',
    SecurityInterface = '/System/Library/Frameworks/SecurityInterface.framework',
    ServerNotification = '/System/Library/Frameworks/ServerNotification.framework',
    ServiceManagement = '/System/Library/Frameworks/ServiceManagement.framework',
    Social = '/System/Library/Frameworks/Social.framework',
    StoreKit = '/System/Library/Frameworks/StoreKit.framework',
    SyncServices = '/System/Library/Frameworks/SyncServices.framework',
    System = '/System/Library/Frameworks/System.framework',
    SystemConfiguration = '/System/Library/Frameworks/SystemConfiguration.framework',
    Tcl = '/System/Library/Frameworks/Tcl.framework',
    Tk = '/System/Library/Frameworks/Tk.framework',
    TWAIN = '/System/Library/Frameworks/TWAIN.framework',
    vecLib = '/System/Library/Frameworks/vecLib.framework',
    VideoDecodeAcceleration = '/System/Library/Frameworks/VideoDecodeAcceleration.framework',
    VideoToolbox = '/System/Library/Frameworks/VideoToolbox.framework',
    WebKit = '/System/Library/Frameworks/WebKit.framework',
    XgridFoundation = '/System/Library/Frameworks/XgridFoundation.framework'


If the Framework path which you want to load isn't present in the INCLUDE enum,
you can specify it manually. Let's say that the path to AppKit isn't available
via the INCLUDE enum. You could load the Framework in the following way::

    load_framework('/System/Library/Frameworks/AppKit.framework')


Using struct types
------------------

Pyobjus currently support ``NSRange``, ``NSPoint``, ``NSSize`` and ``NSRect``
structures. They are defined via the ``ctypes.Structure`` type.

Consider the following. You have an Objective C class with the name ObjcClass
and a useRange: method of that class which is defined in this way::

    - (void) useRange:(NSRange)r {
        printf("location: %ld, length: %ld\n", r.location, r.length);
    }

So, if you want to call this method from Python, you can do something like
this::

    from pyobjus.objc_py_types import NSRange
    from pyobjus import autoclass

    ObjcClass = autoclass('ObjcClass')
    o_cls = ObjcClass.alloc().init()
    range = NSRange(10, 20)
    o_cls.useRange_(range)

This will output::

    >>> location: 10, length: 20

A simmilar situation occurs when returning and using Objective C structure
types. Let's say that our ObjcClass has another method with the name
makeRange::

    - (NSRange) makeRange {
        NSRange range;
        range.length = 123;
        range.location = 456;
        return range;
    }

Using this method from Python is really simple. Let's say that we have included
it from the previous Python code example::

    range = o_cls.makeRange()
    print range.length
    print range.location

And this will output::

    >>> 123
    >>> 456

As you can see, dealing with Objective C structs from pyobjus is simple.

Let's see how to create a ``NSRect`` type::

    point = NSPoint(30, 50)
    size = NSSize(60, 70)
    rect = NSRect(point, size)

Dealing with pointers
---------------------

As you know, C has a very powerful feature with name pointers. Objective C is
a superset of the C language, so Objective C also has this great feature.

But wait, we are using Python, so how we can deal with pointers from Python???

Passing pointers
~~~~~~~~~~~~~~~~

Relax, pyobjus is doing that job for you. I think the best way to explain is to
show some concrete examples of that. So, let's expand our ObjcClass class with
another method::

    - (void) useRangePtr:(NSRange*)r_p {
        NSRange r = r_p[0];
        printf("location: %ld, length: %ld\n", r.location, r.length);
    }

In previous examples you have seen how to create an ``NSRange`` from Python,
and you have sent values of the ``NSRange`` type. But now we have a situation
when the method accepts a pointer to that type.

With pyobjus, you can call a method in the following way::

    range = NSRange(40, 80)
    o_cls.useRangePtr_(range)

And this will output::

    >>> location:40, length: 80

So what has happened here? We pass the argument in the same way as with
the ``useRange:`` method.

Pyobjus knows if a method accepts pointers to a type, or accepts values of that
type. If a method accepts a pointer to a type, pyobjus will make a pointer to
that type, point it to your type and pass that pointer to the method for you.
So with this, you don't need to care whether argument types are pointers or
values.

You can also return pointers to types from Objective C methods. Let's add
another method to ObjcClass::

    - (NSRange*) makeRangePtr {
        NSRange *r_p = malloc(sizeof(NSRange));
        NSRange r;
        r.length = 123;
        r.location = 567;
        *r_p = r;
        return r_p;
    }

As you can see, this method creates a ``NSRange`` pointer, assigns a value to
it, and at the end, it returns a pointer to the user. From Python, you can
consume this method in this way::

    range_ptr = o_cls.makeRangePtr()
    # let we see actual type of returned object
    print range_ptr

This will output following::

    >>> <pyobjus.ObjcReferenceToType object at 0x10f34bcb0>

So here we can see another type -> ObjcReferenceToType. When we have a method
which returns a pointer to some type, pyobjus will wrap that pointer with an
ObjcReferenceToType object. This object contains the actual address of the C
pointer. We can now pass that type to a function which accepts pointers.

Example::

    # note that range_ptr is of ObjcReferenceToType type
    o_cls.useRangePtr_(range_ptr)

But you may now wonder how to dereference the pointer to get the actual value?

The answer is....by using a dereference function.

Dereferencing pointers
~~~~~~~~~~~~~~~~~~~~~~

To dereference pointer use dereference function::

    from pyobjus import dereference

If function returns pointer to some known type, with other words, type isn't void*, you can use dereference function in this way::

    range_ptr = o_cls.makeRangePtr()
    range = dereference(range_ptr)

Pyobjus will parse returned signature from method signature, so it will know in which type to convert pointer value.
If you return void pointer, you will need to specify type in which you want to pyobjus convert actual value on which pointer points.

Now we can add method::

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

Notice that you can specify ``of_type`` optional argument although methods returns ``NSRange`` pointer. 
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

Those already listed types are placed inside pyobjus module, so you can import them in following way::

    from pyobjus import ObjcChar, ObjcInt # etc...

Inside ``pyobjus.objc_py_types`` module are placed structs and unions types. This is list of them::

    'NSRange',
    'NSPoint',
    'NSRect',
    'NSSize'

You can import them with::

    from pyobjus.objc_py_types import NSRange # etc...

Objective C <-> pyobjus literals
--------------------------------

If you are fammiliar with Objective C literals, then you know that is great feature, because literals reduces amount of code to write.
You may wonder is there some equvivalent with pyobjus. The answer is YES.

I think that next example will illustrate how to use pyobjus literals, and what are the Objective C equvivalents::

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

Let's say that we have defined following structures in our ObjcClass.

Note that we haven't specify type of structs, so their types will be missing in method signatures::

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

Let's play. Suppose that we have defined following objective c method::

    - (unknown_str) makeUnknownStr {
        unknown_str str;
        str.a = 10;
        str.rect = NSMakeRect(20, 30, 40, 50);
        str.u_str.a = 2.0;
        str.u_str.b = 4;
        return str;
    }

Purpose of this method is to make unknown type struct, and adding some values to it's members
If you see debug logs of pyobjus, you will notice that method returns following type::

    {?=ii{CGRect={CGPoint=dd}{CGSize=dd}}{?=fi{CGRect={CGPoint=dd}{CGSize=dd}}}}

From this we can see that method returns some type, which contains two integers, and two structs. One struct
is ``CGRect``, and another is some unknown type, which contains float, integer and ``CGRect`` struct
So, if user haven't defined this struct, pyobjus can generate this type for him. Let's call this function::

    ret_type = o_cls.makeUnknownStr()

But wait, how will pyobjus know about field names in struct, because from method signature we know 
only types, not actual names? Well, pyobjus will generate some 'random' names in alphabetical order.

In our case, first member will have name 'a', second will have name 'b', and third name ``CGRect``,
which is used because can help user as indicator of type if actual type is missing. Last one is another 
unknown type, so pyobjus will generate name for him and it will have name 'c'. 

Notice that in case of ``CGRect``, memeber will have ``origin`` and ``size`` members, because it is already defined, 
and we know info about its members. But for last member, pyobjus will continue recursive generating names 
for its members.

Maybe you are asking yourself now, how will you know actual generated name, so pyobjus will help you with this.
There is ``getMembers`` function, which returns name and type of some field in struct::

    print ret_type.getMembers()

Python will output with::

    >>> [('a', <class 'ctypes.c_int'>), ('b', <class 'ctypes.c_int'>), ('CGRect', <class 'pyobjus.objc_py_types.NSRect'>), ('c', <class 'pyobjus.objc_py_types.UnknownType'>)]

If you want to provide your name fields, you can do in this way::

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
Pyobjus uses ctypes structures, so we can get actual pointer to C structure from Python object,
but if we want to get correct values of passed arg, we need to cast pointer to appropriate type.

If type is defined in ``pyobjus/objc_cy_types.pxi`` pyobjus will convert it for us, but if it isn't, we will need to convert
it by ourselfs. For example internally in Objective C method where we are passing struct value. Lets see example of this::

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

Let's say that we want to get Class type for ``NSString`` instance...

We can use following::

    NSString = autoclass('NSString')
    text = NSString.alloc().init()
    text.oclass()

This will return::

    <pyobjus.ObjcClass object at 0x1057361b0>

So, now we can use isKindOfClass: method::

    text.isKindOfClass_(NSString)

This will output ``True``. Let's see another example::

    NSArray = autoclass('NSArray')
    text.isKindOfClass_(NSArray)

And this will output ``False``.

So, as you can see, if you want to use ``class`` with pyobjus, you will need to use ``some_object.oclass()`` method.

Using @selector
---------------

There may be situations when you need to use ``@selector``, which is Objective C feature. With pyobjus you can also get SEL type for method. Let's say that we want to get SEL for init method::

    from pyobjus import selector
    selector('init')

This will output with::

    <pyobjus.ObjcSelector object at 0x1057361c8>

So, as you can see, instead of using this ``@selector(init)`` with Objective C, you will use ``selector('init')`` with pyobjus and Python to get SEL type for some method.

If you want get SEL for ``initWithUTF8String:`` you can use::

    selector('initWithUTF8String:')

Other cases are the same for all methods.

Using enum types
----------------

Pyobjus currently support ``NSComparisonResult`` and ``NSStringEncoding`` enums. If you want to use some others, you need to expand pyobjus with additional types by adding then into ``pyobjus/objc_py_types.py`` file.

But, let we see how to use supported enum types with pyobjus. Consider following example::

    from pyobjus import autoclass, objc_str
    from pyobjus.objc_py_types import NSComparisonResult

    def enum_example():
        text = objc_str('some text')
        text_to_compare = objc_str('some text')
        if text.compare_(text_to_compare) == NSComparisonResult.NSOrderedSame:
            print 'the same strings'

        text_to_compare = objc_str('text')
        if text.compare_(text_to_compare) == NSComparisonResult.NSOrderedAscending:
            print 'NSOrderedAscending strings'

    if __name__ == '__main__':
        enum_example()

You can see that we use ``NSComparisonResult`` enum in above example to compare two strings. Enum is defined in this way::

    NSComparisonResult = enum("NSComparisonResult", NSOrderedAscending=-1, NSOrderedSame=0, NSOrderedDescending=1)

The first argument of ``enum`` function is name of new enum type, and rest of arguments are fields declarations of that enum. As you can see it is preety simple to declare enum with pyobjus, so you can add new enum types to pyobjus.

Using vararg methods
--------------------

As you know, Objective C support vararg (Variable Arguments) methods, so it will be great if you can use vararg methods from pyobjus. Fortunately you can.

Let's we say that we want to use ``arrayWithObjects:`` method, which is one of varargs methods::

    from pyobjus import autoclass, objc_str

    NSArray = autoclass('NSArray')
    array = NSArray.arrayWithObjects_(objc_str('first string'), objc_str('second string'), None)

    text = array.objectAtIndex_(1)
    print text.UTF8String()

As you can see, last argument of varargs methods must be ``None``.

Using C array
-------------

In this section we will explain how to use C array from pyobjus.

Let's say that we made library ``CArrayTestlib.dylib``, which contains test functions for C array. Let's load it::

    import ctypes
    from pyobjus import autoclass, selector, dereference, CArray, CArrayCount
    from pyobjus.dylib_manager import load_dylib

    load_dylib('CArrayTestlib.dylib', usr_path=False)
    CArrayTestlib = autoclass("CArrayTestlib")
    _instance = CArrayTestlib.alloc()

Now we can call ``setIntValues:`` method::

    - (void) setIntValues:(int[10])val_arr
    {
        NSLog(@"Setting int array values...");
        memcpy(self->values, val_arr, sizeof(int) * 10);
        NSLog(@"Values copied...");
    }

on this way::

    nums = [0, 2, 1, 5, 4, 3, 6, 7, 8, 9] 
    array = (ctypes.c_int * 10)(*nums)  
    _instance.setIntValues_(array)

We can also return array values of this function::

    - (int*) getIntValues
    {
        if (!self->values)
        {
            NSLog(@"Values have not been set.");
            return NULL;
        }
        else
            return self->values;
    }

on this way::

    returned_PyList = dereference(_instance.getIntValues(), of_type=CArray, return_count=10)
    print returned_PyList

Note that here we passing ``return_count`` optional argument, which holds number of array items which are retured from ``getIntValues`` method.

But what if we don't know array count? In that case we need to have some argument in which method will put array count value.

Consider following method::

    - (int*) getIntValuesWithCount:(unsigned int*) n
    {
        NSLog(@" ... ... [+] getIntValuesWithCount(n=%zd)", n);
        NSLog(@" ... ... [+] *n=%zd", *n);
        if (!self->values)
        {
            NSLog(@"Values have not been set");
            return NULL;
        }
        else
        {
            *n = 10;
            NSLog(@" ... ... [+] getIntValuesWithCount(n=%zd)", n);
            NSLog(@" ... ... [+] *n=%zd", *n);
            return self->values;
        }
    }

First argument of this function will contain array count when return statement is reached. So let's call it::

    returned_PyList_withCount = dereference(_instance.getIntValuesWithCount_(CArrayCount), of_type=CArray)
    print returned_PyList_withCount

Pyobjus will internally read from that argument and convert returned C array to python array.

If method returns values/ArrayCount over reference and you don't provide ``CArrayCount``
on the right position in the method signature, you will get ``IndexError: tuple index out of range``
or segmentation fault, so don't forget to provide ``CArrayCount`` on the right position.

You may wonder, can you use multidimensional arrays from pyobjus? Yes, you can. Consider following method::

    - (void) set2DIntValues: (int[10][10]) val_arr
    {
        NSLog(@"Setting 2D int array values...");
        memcpy(self->int_2d_arr, val_arr, sizeof(int) * 10 * 10);
        NSLog(@"Values copied...");
    }
    - (int*) get2DIntValues
    {
        if (!self->int_2d_arr)
        {
            NSLog(@"Values have not been set for int 2d array.");
            return NULL;
        }
        else
        {
            return (int*)self->int_2d_arr;
        }
    }

To call this method first we need to make multidimensional array from python in this way::

    twoD_array = [
        [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
        [11, 12, 13, 14, 15, 16, 17, 18, 19, 20],
        [21, 22, 23, 24, 25, 26, 27, 28, 29, 30],
        [31, 32, 33, 34, 35, 36, 37, 38, 39, 40],
        [41, 42, 43, 44, 45, 46, 47, 48, 49, 50],
        [51, 52, 53, 54, 55, 56, 57, 58, 59, 60],
        [61, 62, 63, 64, 65, 66, 67, 68, 69, 70],
        [71, 72, 73, 74, 75, 76, 77, 78, 79, 80],
        [81, 82, 83, 84, 85, 86, 87, 88, 89, 90],
        [91, 92, 93, 94, 95, 96, 97, 98, 99, 100]
    ]

This will be representation of ``int[10][10]``, so let's call above method::

    _instance.set2DIntValues_(twoD_array)
    returned_2d_list = dereference(_instance.get2DIntValues(), of_type=CArray, partition=[10,10])
    print returned_2d_list

You can see optional ``partition`` argument of dereference function. Arguments contains format of C array. In this case it is ``[10, 10]``.

You can find additional examples on this `link <https://github.com/ivpusic/pyobjus/blob/master/examples/using_carray.py>`_.