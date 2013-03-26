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
    text = NSString().initWithUTF8String_('Hello world')
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
your application (ios only).  To preload the framework, you can use ctypes:

    # we want to use NSAlert, but it's not a standard objective-C class
    # so we need to import the framework into the process (desktop)
    # or don't forget to link our app with the framework (ios)
    import ctypes
    ctypes.CDLL('/System/Library/Frameworks/AppKit.framework/Versions/C/Resources/BridgeSupport/AppKit.dylib')
     
Then we can use the NSAlert object::

    from pyobjus import autoclass
 
    # get both nsalert and nsstring class
    NSAlert = autoclass('NSAlert')
    NSString = autoclass('NSString')
     
    # shortcut to mimic the @"hello" in objective C
    ns = lambda x: NSString().initWithUTF8String_(x)
     
    # create an NSAlert object, and show it.
    alert = NSAlert().init()
    alert.setMessageText_(ns('Hello world!'))
    alert.runModal()

