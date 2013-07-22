Pyobjus
=======

Python module to access Objective-C class as Python class, using Objective-C runtime reflection.

(Work in progress.)

Quick overview
--------------

```python
import ctypes
ctypes.CDLL(‘/System/Library/Frameworks/AppKit.framework/Versions/C/Resources/BridgeSupport/AppKit.dylib’)

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
```
