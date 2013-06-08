import ctypes
ctypes.CDLL("/System/Library/Frameworks/AppKit.framework/Versions/C/Resources/BridgeSupport/AppKit.dylib")

from pyobjus import autoclass

NSString = autoclass('NSString')
text = NSString().initWithUTF8String_("some text")
newText = NSString().initWithUTF8String_("some other text")

NSMutableArray = autoclass("NSMutableArray")
array = NSMutableArray().arrayWithCapacity_(5)
newArray = NSMutableArray().arrayWithCapacity_(3)

newArray.addObject_(newText)

array.addObject_(text)
array.addObject_(text)
array.addObject_(newText)

array.removeObjectAtIndex_(0)
array.removeObject_(newText)

count = array.count()
print "count of array -->", count

returnedObject = array.objectAtIndex_(0)
value = returnedObject.UTF8String()
print "string value of returned object -->", value

count = newArray.count()

new_returnedObject = newArray.objectAtIndex_(0)
value = new_returnedObject.UTF8String()

print "-" * 80
print "string value of second returned object -->", value

newArray.removeObject_(new_returnedObject)
count = newArray.count()

print "-" * 80
print "count of newArray -->", count
print "-" * 80




