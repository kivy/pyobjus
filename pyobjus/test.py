import ctypes
ctypes.CDLL("/System/Library/Frameworks/AppKit.framework/Versions/C/Resources/BridgeSupport/AppKit.dylib")

from pyobjus import autoclass, selector

NSArray = autoclass("NSArray")
NSString = autoclass('NSString')
NSMutableArray = autoclass("NSMutableArray")

text = NSString.stringWithUTF8String_("some text")

newText = text
string_for_static_array = text

static_array = NSArray.arrayWithObject_(string_for_static_array)
static_array_sec = NSArray.arrayWithObject_(newText)
returnedObject = static_array.objectAtIndex_(0)
value = returnedObject.UTF8String()
contain_object = static_array.containsObject_(string_for_static_array)

print "_" * 80
print "string value of returned object -->", value
print "_" * 80

array = NSMutableArray.alloc().initWithCapacity_(5)
newArray = NSMutableArray.arrayWithCapacity_(3)

newArray.addObject_(newText)

array.addObject_(text)
array.addObject_(text)
array.addObject_(newText)

array.removeObjectAtIndex_(0)
array.removeObject_(newText)
array.addObject_(text)
count = array.count()
print "count of array -->", count

sel_one = selector("UTF8String")
sel_two = selector("objectAtIndex:")

print "NSString"
print NSString.instancesRespondToSelector_(sel_one)
print text.respondsToSelector_(sel_one)
print text.respondsToSelector_(sel_two)
print text.respondsToSelector_(selector("init"))
print NSArray.instancesRespondToSelector_(sel_one)

print text.retainCount()

print array.retainCount()
array.release()
print array.retainCount()

array_test = NSArray.arrayWithObjects_(text, newText, text, array, None)
print array_test.count()

array_new = NSArray.arrayWithObjects_(text, newText, None)
array_new = NSArray.arrayWithObjects_(None)
print array_new.count()
array_new = NSArray.arrayWithObjects_(None)
array_new = NSArray.arrayWithObjects_(text, None)
array_new = NSArray.alloc().initWithObjects_(None)
array_new = NSArray.alloc().initWithObjects_(text, None)
print array_new.objectAtIndex_(0).UTF8String()
array_new = NSArray.alloc().initWithObjects_(None)
print array_new.count()
