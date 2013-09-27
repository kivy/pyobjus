from pyobjus import autoclass

NSString = autoclass('NSString')
NSArray = autoclass("NSArray")

string_for_array = NSString.alloc().initWithUTF8String_("some text for NSArray")
array = NSArray.arrayWithObject_(string_for_array)

returnedObject = array.objectAtIndex_(0)
value = returnedObject.UTF8String()
contain_object = array.containsObject_(string_for_array)

returnedNSStringObject = array.objectAtIndex_(0)
value = returnedNSStringObject.UTF8String()

print "string value of returned object -->", value
print "return value of containsObject method -->", contain_object
