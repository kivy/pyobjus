from pyobjus import ObjcClass, ObjcMethod, MetaObjcClass

class NSString(ObjcClass):
    __objcclass__ = 'NSString'
    __metaclass__ = MetaObjcClass

    init = ObjcMethod('@16@0:8')
    substringFromIndex_ = ObjcMethod('@24@0:8Q16')
    length = ObjcMethod('Q16@0:8')

a = NSString()
a.init()
a.length()
#print a.substringFromIndex_(6)
