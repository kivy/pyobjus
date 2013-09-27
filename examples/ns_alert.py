from pyobjus import autoclass
from pyobjus.dylib_manager import load_framework, INCLUDE

load_framework(INCLUDE.AppKit)

# get both nsalert and nsstring class
NSAlert = autoclass('NSAlert')
NSString = autoclass('NSString')

ns = lambda x: NSString.alloc().initWithUTF8String_(x)
alert = NSAlert.alloc().init()
alert.setMessageText_(ns('Hello world from python!'))
alert.addButtonWithTitle_(NSString.stringWithUTF8String_("OK"))
alert.addButtonWithTitle_(NSString.stringWithUTF8String_("Cancel"))
alert.runModal()
