from pyobjus import ObjcClass, ObjcMethod, MetaObjcClass

class NSString(ObjcClass):
    __objcclass__ = 'NSString'
    __metaclass__ = MetaObjcClass

    init = ObjcMethod('@16@0:8')
    substringFromIndex_ = ObjcMethod('@24@0:8Q16')

a = NSString()
a.init()
print a.substringFromIndex_(6)
