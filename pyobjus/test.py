import ctypes
ctypes.CDLL("/System/Library/Frameworks/AppKit.framework/Versions/C/Resources/BridgeSupport/AppKit.dylib")

from pyobjus import autoclass, selector

NSArray = autoclass("NSArray")

NSString = autoclass('NSString')
text = NSString().initWithUTF8String_("some text")

newText = NSString().initWithUTF8String_("some other text")
string_for_static_array = NSString().initWithUTF8String_("some text for NSArray")

static_array = NSArray().arrayWithObject_(string_for_static_array)
static_array_sec = NSArray().arrayWithObject_(newText)
returnedObject = static_array.objectAtIndex_(0)
value = returnedObject.UTF8String()
contain_object = static_array.containsObject_(string_for_static_array)

print "_" * 80
print "string value of returned object -->", value
print "_" * 80

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

newArray.insertObject_atIndex_(new_returnedObject, 0)
count = newArray.count()
print count
ocls = text.oclass()
print array.isKindOfClass_(ocls)

print newText.isKindOfClass_(ocls)
print text.isKindOfClass_(ocls)

ocls = array.oclass()
print text.isKindOfClass_(ocls)

sel_one = selector("UTF8String")
sel_two = selector("objectAtIndex:")

print "NSString"
print text.instancesRespondToSelector_(sel_one)
print text.respondsToSelector_(sel_one)
print text.respondsToSelector_(sel_two)
print text.respondsToSelector_(selector("init"))

print "NSArray"
print array.respondsToSelector_(sel_one)
print array.respondsToSelector_(sel_two)
print array.respondsToSelector_(selector("retain"))
print array.respondsToSelector_(selector("insertObject:atIndex:"))

print static_array.respondsToSelector_(selector("insertObject:atIndex:"))


