from pyobjus import autoclass

NSString = autoclass('NSString')
NSArray = autoclass("NSArray")
NSDictionary = autoclass("NSDictionary")

string_object = NSString.stringWithUTF8String_("some text for NSDictionary")
string_key = NSString.stringWithUTF8String_("someKey")

array_object = NSArray.arrayWithObject_(string_object)
array_key = NSArray.arrayWithObject_(string_key)

# we are passing array with objects and keys
dictionary = NSDictionary.dictionaryWithObjects_forKeys_(array_object, array_key)

returned_nsstring = dictionary.objectForKey_(array_key.objectAtIndex_(0))
str_value = returned_nsstring.UTF8String()
print str_value
