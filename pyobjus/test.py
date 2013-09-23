import ctypes
import os

# LOADING USER DEFINED CLASS (dylib) FROM /objc_usr_classes/ DIR #
os.system('cd ../')
usrlib_dir = os.getcwd() + '/objc_usr_classes/usrlib.dylib'
ctypes.CDLL(usrlib_dir)
# -------------------------------------------------------------- #

from pyobjus import *
from objc_py_types import *

NSArray = autoclass("NSArray")
NSMutableArray = autoclass("NSMutableArray")
NSString = autoclass('NSString')

text = NSString.stringWithUTF8String_("some text from Python")
print text.UTF8String()

test_array = NSArray.alloc().initWithObjects_(text, None)

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
print dereference(val_ptr, of_type=NSRange).length

rng = c.makeRangePtr()
rn = NSRange(23, 43)

c.useRangePtr_withMessage_(rng, "this is some message!")

c.useRangeVoidPtr_(rn)
c.useRangeVoidPtr_(rng)

c.useClassInstVoidPtr_(text)

c.useClassVoidPtr_(c.makeClass())

p = NSValue.valueWithPointer_(range_new)
p_v = p.pointerValue()
print dereference(p_v, of_type=NSRange).location

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
cls = dereference(cls_p, of_type=ObjcClass)
c.driveWithClass_(cls)

s_vp = c.makeSelectorVoidPtr()
sel = dereference(s_vp, of_type=ObjcSelector)
c.useSelector_(sel)
c.useSelectorPtr_(s_vp)

p = NSValue.valueWithPointer_(text)
p_v = p.pointerValue()
print dereference(p_v, of_type=ObjcClassInstance).UTF8String()

pv = NSValue.valueWithPointer_(rect)
rct = pv.pointerValue()
print dereference(rct, of_type=NSRect).origin.x

cls_p = c.oclass()
nsv = NSValue.valueWithPointer_(cls_p)
cls_p = nsv.pointerValue()
cls = dereference(cls_p, of_type=ObjcClass)
c.driveWithClass_(cls)

i_vp = c.makeIntVoidPtr()
print dereference(i_vp, of_type=ObjcInt)

f_vp = c.makeFloatVoidPtr()
print dereference(f_vp, of_type=ObjcFloat)

b_ptr = c.makeBoolPtr()
print dereference(b_ptr)

b_v_ptr = c.makeBoolVoidPtr()
print dereference(b_v_ptr, of_type=ObjcBool)

print c.makeULongLong()

c.useBool_(False)
c.useBoolPtr_(False)
c.useBoolPtr_(b_ptr)

BOOL_ptr = c.makeBOOLPtr_(True)
print dereference(BOOL_ptr)
c.useBOOLPtr_(BOOL_ptr)

BOOL = c.makeBOOL()
print BOOL
c.useBOOL_(BOOL)
c.useBOOLPtr_(BOOL_ptr)

BOOL_v_p = c.makeBOOLVoidPtr()
print dereference(BOOL_v_p, of_type=ObjcBOOL)

union = c.makeUnion()
union_ptr = c.makeUnionPtr()
print dereference(union_ptr).rect.origin.x
print union.rect.origin.x, union.rect.origin.y, union.rect.size.width, union.rect.size.height
c.useUnionPtr_(union_ptr)
c.useUnionPtr_(union)
print union.rect.origin.x

ret_unknown = c.makeUnknownStr(members=['a', 'b', 'rect'])
print ret_unknown.a
print ret_unknown.getMembers()
print ret_unknown.getMembers(only_types=True)
print ret_unknown.getMembers(only_fields=True)
c.useUnknownStr_(ret_unknown)

imp = c.getImp()
c.useImp_withA_andB_(imp, 5, 6)

imp = c.methodForSelector_(selector('getSumOf:and:'))
print c.useImp_withA_andB_(imp, 5, 7)

sign = c.methodSignatureForSelector_(selector("getSumOf:and:"))
print sign.getArgumentTypeAtIndex_(2)
print sign.numberOfArguments()
print c.makeUnknownStr().getMembers()

c.setProp()
print c.propInt
print c.propDouble
print c.propNSString
print c.prop_string
print c.propFloat
print c.propUlnglng

rect = NSRect(NSPoint(4, 4), NSSize(7, 7))
c.propRect = rect
c.propFloatPtr = 123.4
print c.propNsstringDyn
print "-"*80
c.propNsstringDyn = text
print c.propNsstringDyn.UTF8String()
c.propIntCst = 123456321
print c.propIntCst
c.propCstInt = 12344
print dereference(c.propCstInt)
print dereference(c.propFloatPtr)
c.propFloat = 111.333
print c.propFloat
print c.propRect.origin.x
print c.propRect.origin.y
c.propUlnglng = 777777777555
print c.propUlnglng
print c.propInt
c.propNSString = text
print c.propNSString.UTF8String()

c.prop_int_ptr = 223344
print c.prop_int_ptr
print dereference(c.prop_int_ptr)

c.prop_double_ptr = 1010.3030
print dereference(c.prop_double_ptr)

a = autoclass('NSString')
print dir(a)
b = autoclass('NSString', load_class_methods=['alloc'])
print dir(b)
a = autoclass('NSString', reset_autoclass=True)
print dir(a)

print objc_c("C").charValue()
print objc_i(123).intValue()
print objc_ui(32243423).unsignedIntegerValue()
print objc_l(42342342).longValue()
print objc_ll(53453453).longLongValue()
print objc_f(4343.4343).floatValue()
print objc_d(555.3333).doubleValue()
print objc_b(True).boolValue()
print objc_b(False).boolValue()
print objc_str('string literal test!').UTF8String()
print objc_arr(text, objc_str('other string'), objc_i(232343)).objectAtIndex_(2)
print objc_dict({'first': text, 'second': objc_f(3.14)}).objectForKey_(objc_str('second')).floatValue()

text = NSString.stringWithUTF8String_('it works!')
rng = NSRange(0, 3)
r = text.lineRangeForRange_(rng)
print r.location
print r.length
