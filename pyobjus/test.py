import ctypes
ctypes.CDLL("/System/Library/Frameworks/AppKit.framework/Versions/C/Resources/BridgeSupport/AppKit.dylib")

from ctypes import c_int

from pyobjus import autoclass

index = c_int(0)
# get both nsalert and nsstring class
NSString = autoclass('NSString')
#UInteger = autoclass("NSInteger")

# shortcut to mimic the @"hello" in objective C
text = NSString().initWithUTF8String_("THIS IS TEST!!!!!!")

NSArray = autoclass("NSArray")
array = NSArray().arrayWithObject_(text)
count = array.count()
print "COUNT -->", count

returnedObject = array.objectAtIndex_(int(0))
#print "VALUE ->", text.UTF8String()
value = returnedObject.UTF8String()
print value
