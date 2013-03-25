from pyobjus import ObjcClass, ObjcMethod, MetaObjcClass

class NSString(ObjcClass):
    __objcclass__ = 'NSString'
    __metaclass__ = MetaObjcClass

    init = ObjcMethod('@16@0:8')
    substringFromIndex_ = ObjcMethod('@24@0:8Q16')
    length = ObjcMethod('Q16@0:8')
    initWithUTF8String_ = ObjcMethod('@24@0:8r*16', selectors=('bytes', ))

a = NSString()
ret = a.initWithUTF8String_('hello world')
print 'a.initWithUTF8String() ->', ret
#ret = a.init()
#print 'a.init() ->', ret
l = ret.length()
print 'a.length() ->', l
print a.substringFromIndex_(6)
