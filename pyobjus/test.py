import ctypes
ctypes.CDLL("/System/Library/Frameworks/AppKit.framework/Versions/C/Resources/BridgeSupport/AppKit.dylib")

from pyobjus import autoclass, selector, cast_manager, ObjcClassInstance
from objc_py_types import *

NSArray = autoclass("NSArray")
NSString = autoclass('NSString')
NSMutableArray = autoclass("NSMutableArray")

text = NSString.stringWithUTF8String_("some text")

newText = NSString.stringWithUTF8String_("text")
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

ns_range_result = text.rangeOfString_(newText)
print "location -->", ns_range_result.location
print "length -->", ns_range_result.length

NSData = autoclass('NSData')


range_new = NSRange(5, 3)
r = text.lineRangeForRange_(range_new)
print "loc -->", r.length
print "loc -->", r.location

NSValue = autoclass('NSValue')
rect = NSRect(NSPoint(3, 5), NSSize(320, 480))

ns_rect = NSValue.valueWithRect_(rect)
rv = ns_rect.rectValue()
print rv.origin.x
print rv.origin.y

point = NSPoint(4, 8)
print point.x

pt = NSValue.valueWithPoint_(point)
p = pt.pointValue()
print p.x

rng = NSRange(9, 10)
rg = NSValue.valueWithRange_(rng)
r = rg.rangeValue()
print r.location

sz = NSSize(320, 480)
ssz = NSValue.valueWithSize_(sz)
s = ssz.sizeValue()
print s.width

print text.substringWithRange_(range_new).UTF8String()
print ssz.objCType()

res = text.compare_(newText)

if res == NSComparisonResult.NSOrderedAscending:
    print "NSOrderedAscending"

range_new.length = 5
p = NSValue.valueWithPointer_(range_new)
val_ptr = p.pointerValue()
print cast_manager(val_ptr, NSRange).length

p = NSValue.valueWithPointer_(text)

p_v = p.pointerValue()
print cast_manager(p_v, ObjcClassInstance).UTF8String()
