Pyobjus
=======

Python module to access Objective-C class as Python class, using Objective-C runtime reflection.

(Work in progress.)

Quick overview
--------------

```python

from pyobjus import autoclass, objc_str
from pyobjus.dylib_manager import load_framework, INCLUDE

# load AppKit framework into pyojbus
load_framework(INCLUDE.AppKit)

# get both nsalert and nsstring class
NSAlert = autoclass('NSAlert')

# create an NSAlert object, and show it.
alert = NSAlert.alloc().init()
alert.setMessageText_(objc_str('Hello world!'))
alert.runModal()
```
