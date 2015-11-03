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

# get nsalert class
NSAlert = autoclass('NSAlert')

# create an NSAlert object, and show it.
alert = NSAlert.alloc().init()
alert.setMessageText_(objc_str('Hello world!'))
alert.runModal()
```

Support
-------

If you need assistance, you can ask for help on our mailing list:

* User Group : https://groups.google.com/group/kivy-users
* Email      : kivy-users@googlegroups.com

We also have an IRC channel:

* Server  : irc.freenode.net
* Port    : 6667, 6697 (SSL only)
* Channel : #kivy

Contributing
------------

We love pull requests and discussing novel ideas. Check out our
[contribution guide](http://kivy.org/docs/contribute.html) and
feel free to improve Pyobjus.

The following mailing list and IRC channel are used exclusively for
discussions about developing the Kivy framework and its sister projects:

* Dev Group : https://groups.google.com/group/kivy-dev
* Email     : kivy-dev@googlegroups.com

IRC channel:

* Server  : irc.freenode.net
* Port    : 6667, 6697 (SSL only)
* Channel : #kivy-dev

License
-------

Pyobjus is released under the terms of the MIT License. Please refer to the
LICENSE file.
