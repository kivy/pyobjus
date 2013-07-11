import ctypes
ctypes.CDLL("/System/Library/Frameworks/AppKit.framework/Versions/C/Resources/BridgeSupport/AppKit.dylib")

from pyobjus import *
from objc_py_types import *

NSArray = autoclass("NSArray")
NSString = autoclass('NSString')
NSMutableArray = autoclass("NSMutableArray")

text = NSString.stringWithUTF8String_("some text")
print text.UTF8String()
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

point = NSPoint(4, 8)
print point.x

pt = NSValue.valueWithPoint_(point)
p = pt.pointValue()
print p.x

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

car = autoclass('Car')
c = car.alloc().init()
r = c.makeCarIdint()
print r.type
c.driveWithCari_(r)
c.driveWithCari_(542354)

sh = c.makeCarIdshort()
c.driveWithCars_(sh)
c.driveWithCars_(32000)

lng = c.makeCarIdlong()
c.driveWithCarl_(lng)
c.driveWithCarl_(435342)

uchr = c.makeCarIduChar()
c.driveWithCaruc_(uchr)
c.driveWithCaruc_(102)

ch = c.makeCarIdChar()
c.driveWithCarc_(ch)

sel = c.makeSelector()
ssl = selector("print")
c.useSelector_(ssl)

sel_p = c.makeSelectorPtr()
c.useSelectorPtr_(ssl)
print c.respondsToSelector_(ssl)

c.voidToFloat_(12.35)
c.voidToStr_("iv")

p = NSValue.valueWithPointer_(range_new)
val_ptr = p.pointerValue()
print dereference(val_ptr, type=NSRange).length

rng = c.makeRangePtr()
rn = NSRange(23, 43)

c.useRangePtr_(rn)
c.useRangePtr_(rng)

c.useRangeVoidPtr_(rn)
c.useRangeVoidPtr_(rng)

c.useClassInstVoidPtr_(text)

c.useClassVoidPtr_(c.makeClass())

p = NSValue.valueWithPointer_(range_new)
p_v = p.pointerValue()
print dereference(p_v, type=NSRange).location

rng = NSRange(9, 10)
rg = NSValue.valueWithRange_(rng)
r = rg.rangeValue()
print r.location

cls = c.makeClass()
cl = c.oclass()
print cl
c.useClassVoidPtr_(cl)

NSObject = autoclass('NSObject')
objc_class = NSString.oclass()
print text.isKindOfClass_(NSObject.oclass())

print c.makeDouble()

r = NSRect(NSPoint(30, 50), NSSize(320, 480))
ns_rect = NSValue.valueWithRect_(r)
rv = ns_rect.rectValue()
print rv.origin.x
print rv.origin.y

rng = c.makeCarIddouble()
print rng
print dereference(rng)

rng =  c.makeRangePtr()
print dereference(rng).length

rct = c.makeRectPtr()
rect = dereference(rct)

print rect.origin.x
print rect.origin.y
print rect.size.width
print rect.size.height

cls_p = c.makeClassVoidPtr()
cls = dereference(cls_p, type=ObjcClass)
c.driveWithClass_(cls)

s_vp = c.makeSelectorVoidPtr()
sel = dereference(s_vp, type=ObjcSelector)
c.useSelector_(sel)
c.useSelectorPtr_(s_vp)

p = NSValue.valueWithPointer_(text)
p_v = p.pointerValue()
print dereference(p_v, type=ObjcClassInstance).UTF8String()

pv = NSValue.valueWithPointer_(rect)
rct = pv.pointerValue()
print dereference(rct, type=NSRect).origin.x

cls_p = c.oclass()
nsv = NSValue.valueWithPointer_(cls_p)
cls_p = nsv.pointerValue()
cls = dereference(cls_p, type=ObjcClass)
c.driveWithClass_(cls)

i_vp = c.makeIntVoidPtr()
print dereference(i_vp, type=ObjcInt)

f_vp = c.makeFloatVoidPtr()
print dereference(f_vp, type=ObjcFloat)
