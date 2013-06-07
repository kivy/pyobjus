import ctypes
ctypes.CDLL('/System/Library/Frameworks/AppKit.framework/Versions/C/Resources/BridgeSupport/AppKit.dylib')

from pyobjus import autoclass

# get both nsalert and nsstring class
NSAlert = autoclass('NSAlert')
NSString = autoclass('NSString')

ns = lambda x: NSString().initWithUTF8String_(x)
alert = NSAlert().init()
alert.setMessageText_(ns('Hello world!'))
alert.runModal()


