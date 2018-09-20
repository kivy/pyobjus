.. _quickstart:

Quickstart
==========

Eager to get started? This page will give you a good introduction to Pyobjus.
It's assumed you have already installed Pyobjus. If you haven't, head over the
:ref:`installation` section.

The simplest example
--------------------

The simplest Pyobjus example looks something like this::

    from pyobjus import autoclass

    NSString = autoclass('NSString')
    text = NSString.alloc().initWithUTF8String_('Hello world')
    print text.UTF8String() # --> Hello world

Just save it as `test.py` (or something similar) and run it with your Python
interpreter. Make sure not to call your application `pyobjus.py` because it would
conflict with Pyobjus itself::

    $ python test.py
    Hello world

Using classes not in the standard Framework
-------------------------------------------

If you want to use classes other than those available from the linked
framework, you need to preload the framework first, or add the Framework to
your application (iOS only).  To preload the framework, you can use the
pyobjus dylib_manager::

    # We want to use NSAlert, but it's not a standard objective-C class
    # so we need to either import the framework into our process (desktop)
    # or link the framework to our app (iOS)
    from pyobjus.dylib_manager import load_framework, INCLUDE
    load_framework(INCLUDE.AppKit)

    # OR in this way
    # from pyobjus.dylib_manager import load_framework
    # load_framework('/System/Library/Frameworks/AppKit.framework')

    # OR in this way
    # from pyobjus.dylib_manager import load_dylib
    # load_dylib('/System/Library/Frameworks/AppKit.framework/Versions/C/Resources/BridgeSupport/AppKit.dylib')

    # NOTE: there is a "Dynamic library manager" section dedicated explaining how to use dylib_manager functions

Then we can use the NSAlert object::

    from pyobjus import autoclass

    # mimic the constant string operator (@"hello") in objective C
    from pyobjus import objc_str

    # get both nsalert and nsstring class
    NSAlert = autoclass('NSAlert')
    NSString = autoclass('NSString')

    # create an NSAlert object, and show it.
    alert = NSAlert.alloc().init()
    alert.setMessageText_(objc_str('Hello world!'))
    alert.runModal()
