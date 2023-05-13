# Pyobjus

Python module for accessing Objective-C classes as Python classes using
Objective-C runtime reflection.

[![Build Status](https://travis-ci.org/kivy/pyobjus.svg?branch=master)](https://travis-ci.org/kivy/pyobjus)
[![Backers on Open Collective](https://opencollective.com/kivy/backers/badge.svg)](#backers) 
[![Sponsors on Open Collective](https://opencollective.com/kivy/sponsors/badge.svg)](#sponsors) 


## Quick overview

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


## Support

If you need assistance, you can ask for help on our mailing list:

* User Group : https://groups.google.com/group/kivy-users
* Email      : kivy-users@googlegroups.com

We also have a Discord server:

[https://chat.kivy.org/](https://chat.kivy.org/)


## Contributing

We love pull requests and discussing novel ideas. Check out our
[contribution guide](http://kivy.org/docs/contribute.html) and
feel free to improve Pyobjus.

The following mailing list and IRC channel are used exclusively for
discussions about developing the Kivy framework and its sister projects:

* Dev Group : https://groups.google.com/group/kivy-dev
* Email     : kivy-dev@googlegroups.com

Discord channel:

* Server     : https://chat.kivy.org
* Channel    : #dev


## License

Pyobjus is released under the terms of the MIT License. Please refer to the
LICENSE file.


## Backers

Thank you to all our backers! 🙏 [[Become a backer](https://opencollective.com/kivy#backer)]

<a href="https://opencollective.com/kivy#backers" target="_blank"><img src="https://opencollective.com/kivy/backers.svg?width=890"></a>


## Sponsors

Support this project by becoming a sponsor. Your logo will show up here with a link to your website. [[Become a sponsor](https://opencollective.com/kivy#sponsor)]

<a href="https://opencollective.com/kivy/sponsor/0/website" target="_blank"><img src="https://opencollective.com/kivy/sponsor/0/avatar.svg"></a>
<a href="https://opencollective.com/kivy/sponsor/1/website" target="_blank"><img src="https://opencollective.com/kivy/sponsor/1/avatar.svg"></a>
<a href="https://opencollective.com/kivy/sponsor/2/website" target="_blank"><img src="https://opencollective.com/kivy/sponsor/2/avatar.svg"></a>
<a href="https://opencollective.com/kivy/sponsor/3/website" target="_blank"><img src="https://opencollective.com/kivy/sponsor/3/avatar.svg"></a>
<a href="https://opencollective.com/kivy/sponsor/4/website" target="_blank"><img src="https://opencollective.com/kivy/sponsor/4/avatar.svg"></a>
<a href="https://opencollective.com/kivy/sponsor/5/website" target="_blank"><img src="https://opencollective.com/kivy/sponsor/5/avatar.svg"></a>
<a href="https://opencollective.com/kivy/sponsor/6/website" target="_blank"><img src="https://opencollective.com/kivy/sponsor/6/avatar.svg"></a>
<a href="https://opencollective.com/kivy/sponsor/7/website" target="_blank"><img src="https://opencollective.com/kivy/sponsor/7/avatar.svg"></a>
<a href="https://opencollective.com/kivy/sponsor/8/website" target="_blank"><img src="https://opencollective.com/kivy/sponsor/8/avatar.svg"></a>
<a href="https://opencollective.com/kivy/sponsor/9/website" target="_blank"><img src="https://opencollective.com/kivy/sponsor/9/avatar.svg"></a>

