from pyobjus import autoclass

NSString = autoclass('NSString')
NSMutableDictionary = autoclass("NSMutableDictionary")

string_object = NSString.stringWithUTF8String_("some text for NSDictionary")
string_key = NSString.stringWithUTF8String_("someKey")

string_object_second = NSString.stringWithUTF8String_("some other text for NSDictionary")
string_key_second = NSString.stringWithUTF8String_("someOtherKey")

objects_dict = {
    string_key: string_object,
    string_key_second: string_object_second
}

mutable_dictionary = NSMutableDictionary.dictionaryWithCapacity_(10)

# we can add objects to dict now
for key in objects_dict:
    mutable_dictionary.setObject_forKey_(objects_dict[key], key)

# let we return some object
returned_nsstring = mutable_dictionary.objectForKey_(string_key)

# we can iterate over dict values
enumerator = mutable_dictionary.objectEnumerator()
obj = enumerator.nextObject()
while obj:
    str_value = obj.UTF8String()
    print str_value
    obj = enumerator.nextObject()
