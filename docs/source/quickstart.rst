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
framework, preload the framework with ``load_framework``. The same call is
used on macOS and iOS::

    # NSAlert is in AppKit, which is not loaded by default
    from pyobjus.dylib_manager import load_framework, INCLUDE
    load_framework(INCLUDE.AppKit)

``INCLUDE`` holds the bundle path for some common frameworks.
``INCLUDE.AppKit`` is ``/System/Library/Frameworks/AppKit.framework``.
A framework that is not in ``INCLUDE`` is loaded by passing its bundle path,
for example ``/System/Library/Frameworks/Metal.framework``.

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
