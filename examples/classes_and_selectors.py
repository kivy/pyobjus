import ctypes
ctypes.CDLL("/System/Library/Frameworks/AppKit.framework/Versions/C/Resources/BridgeSupport/AppKit.dylib")

from pyobjus import autoclass, selector

NSObject = autoclass("NSObject")
NSArray = autoclass("NSArray")
NSString = autoclass('NSString')

text = NSString.alloc().initWithUTF8String_("some text")
array = NSArray.arrayWithObject_(text)

# equivalent to [NSString class];
objc_class = NSString.oclass()
print NSString.isKindOfClass_(NSObject.oclass())
print NSString.isKindOfClass_(NSArray.oclass())

# equivalent to @selector(UTF8String)
sel_one = selector("UTF8String")
sel_two = selector("objectAtIndex:")

# examples with NSString
print NSString.instancesRespondToSelector_(sel_one)
print text.respondsToSelector_(sel_one)
print text.respondsToSelector_(sel_two)
print text.respondsToSelector_(selector("init"))

# examples with NSArray
print array.respondsToSelector_(sel_one)
print array.respondsToSelector_(sel_two)
