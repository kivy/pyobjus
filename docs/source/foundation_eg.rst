.. _foundation_eg:

Foundation framework examples
=============================

.. module:: pyobjus

This part of the documentation covers examples of using classes from foundation framework.

NSArray example
---------------

Here is an example of using NSArray class::

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

This will output::

    >>> string value of returned object --> some text for NSArray
    >>> return value of containsObject method --> True

NSArray with pyobjus literals
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If you want, you can use sommething like Objective C literals to create NSArray::

    from pyobjus import objc_arr, objc_str

    array = objc_arr(objc_str('some string'), objc_str('some other string'))
    print array

As you can see here, ``objc_arr(...)`` is equvivalent to ``autoclass('NSArray').arrayWithObjects_(...)``, 
and this will output::

    >>> <__main__.__NSArrayI object at 0x10a22d350>

NSDictionary example
--------------------

Here is an example of using NSDictoinary class::

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
    
This will output::

    >>> some text for NSDictionary

NSDictionary with pyobjus literals
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

We can use pyobjus `literals` also with NSDictionary class.

So let's add two elements to dictionary. The first one has key 'first_key', and value @'string value of first key', and the second one has key 'second_key', with value NSArray::

    from pyobjus import objc_dict, objc_str, objc_arr

    dictionary = objc_dict({
        'first_key': objc_str('string value of first key'),
        'second_key': objc_arr(objc_str('string element of NSArray'))
    })

    first_key_value = dictionary.objectForKey_(objc_str('first_key'))
    second_key_value = dictionary.objectForKey_(objc_str('second_key'))

    print first_key_value
    print second_key_value

This will output::

    >>> <__main__.__NSCFString object at 0x101025d10>
    >>> <__main__.__NSArrayI object at 0x101169290>

So, if you want to call for eg. UTF8String method of NSString object, which resides in 'first_key', you simply can call::

    str_val = first_key_value.UTF8String()
    print 'String value is: {0}'.format(str_val)

This will output::

    >>> String value is: string value of first key

NSMutableArray example
----------------------

This class is often usefull if you need to add elements after you create array. So let's see example of using this class with pyobjus::

    from pyobjus import autoclass

    NSString = autoclass('NSString')
    NSMutableArray = autoclass("NSMutableArray")

    array = NSMutableArray.arrayWithCapacity_(5)
    text_val_one = NSString.alloc().initWithUTF8String_("some text for NSMutableArray")
    text_val_two = NSString.alloc().initWithUTF8String_("some other text for NSMutableArray")

    # we add some objects to NSMutableArray
    array.addObject_(text_val_one)
    array.addObject_(text_val_one)
    array.addObject_(text_val_two)

    count = array.count()
    print "count of array before object delete -->", count

    # then we remove some of them
    array.removeObjectAtIndex_(0)
    array.removeObject_(text_val_two)

    count = array.count()
    print "count of array after object delete -->", count

    returnedObject = array.objectAtIndex_(0)
    value = returnedObject.UTF8String()
    print "string value of returned object -->", value

    # call method which accepts multiple arguments
    array.insertObject_atIndex_(text_val_two, 1)
    returnedObject = array.objectAtIndex_(1)
    value = returnedObject.UTF8String()
    print "string value of returned object at index 1 -->", value

This will output::

    >>> number of array before object delete --> 3
    >>> number of array after object delete --> 1
    >>> string value of returned object --> some text for NSMutableArray
    >>> string value of returned object at index 1 --> some other text for NSMutableArray

NSMutableDictionary example
---------------------------

As with this class above, you can also with this class add and delete elements and after you've created object.::

    from pyobjus import autoclass

    NSString = autoclass('NSString')
    NSMutableDictionary = autoclass("NSMutableDictionary")

    # notice that you can instead of this line use objc_str('some text for NSDictoinary')
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

    # let's return some object
    returned_nsstring = mutable_dictionary.objectForKey_(string_key)

    # we can iterate over dict values
    enumerator = mutable_dictionary.objectEnumerator()
    obj = enumerator.nextObject()
    while obj:
        str_value = obj.UTF8String()
        print str_value
        obj = enumerator.nextObject()

So this will output::

    >>> some other text for NSDictionary
    >>> some text for NSDictionary

Other
-----

Other examples are located on this `link <https://github.com/kivy/pyobjus/tree/master/examples>`_.