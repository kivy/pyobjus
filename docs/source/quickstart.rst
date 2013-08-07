.. _quickstart:

Quickstart
==========

Eager to get started? This page will give you a good introduction to Pyobjus. It assumes
you have already Pyobjus installed. If you do not, head over the
:ref:`installation` section.

A minimal example
-----------------

A minimal Pyobjus example looks something like this::

    from pyobjus import autoclass

    NSString = autoclass('NSString')
    text = NSString.alloc().initWithUTF8String_('Hello world')
    print text.UTF8String() # --> Hello world

Just save it as `test.py` (or something similar) and run it with your Python
interpreter. Make sure not to call your application `pyobjus.py` because it would
conflict with Pyobjus itself::

    $ python test.py
    Hello world

Using class not in the standard Framework
-----------------------------------------

If you want to use others class that the one accessible from the linked
framework, you need to preload the framework first, or add the Framework to
your application (ios only).  To preload the framework, you can use pyobjus dylib_manager::

    # we want to use NSAlert, but it's not a standard objective-C class
    # so we need to import the framework into the process (desktop)
    # or don't forget to link our app with the framework (ios)
    from pyobjus.dylib_manager import load_framework, INCLUDE
    load_framework(INCLUDE.AppKit)

However, if framework which you want to load into your program isn't available via pyobjus method for easy load of frameworks,
you can use ``load_dylib`` function of ``dylib_manager``. So let we say that previous framework isn't available
via load_framework function, instead of using that function, you can do following::

    load_dylib('/System/Library/Frameworks/AppKit.framework/Versions/C/Resources/BridgeSupport/AppKit.dylib')

So, as you can see we need to find dylib of framework on out computer, then we provide path to .dylib, 
and pyobjus will load it for us.

But if you don't want to search for appropriate .dylib, and framework which you want load isn't available 
via ``INCLUDE`` enum, you can sill use ``load_framework`` function by providing framework path on this way::

    load_framework('/System/Library/Frameworks/AppKit.framework')

Argument of this function you can find on official Apple documentation.

For eg. if you want to load AppKit framework, go to this link:

https://developer.apple.com/library/mac/#documentation/cocoa/reference/ApplicationKit/ObjC_classic/_index.html, 
and at the top of page you will find previous path.     

Then we can use the NSAlert object::

    from pyobjus import autoclass
 
    # get both nsalert and nsstring class
    NSAlert = autoclass('NSAlert')
    NSString = autoclass('NSString')
     
    # shortcut to mimic the @"hello" in objective C
    ns = lambda x: NSString.alloc().initWithUTF8String_(x)
     
    # create an NSAlert object, and show it.
    alert = NSAlert.alloc().init()
    alert.setMessageText_(ns('Hello world!'))
    alert.runModal()
