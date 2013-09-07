.. _api:

API
===

.. module:: pyobjus

This part of the documentation covers all the interfaces of Pyobjus.

Reflection functions
--------------------

.. function:: autoclass(name[, copy_properties=None, load_class_methods=None, load_instance_methods=None, reset_autoclass=None])

    Get and load Objective C class
    
    :param name: Name of Objective C class which you want to load
    :param copy_properties: Denotes if user want to copy properties of some Objective C class. Default is to copy all properties of some class.
    :type copy_properties: None or Boolean
    :param load_class_methods: If this argument is set to `None`, all class methods will be loaded. But user can also specify class methods which he want to load, for eg. `load_class_methods=['alloc']`.
    :type load_class_methods: None or List
    :param load_instance_methods: If this argument is set to `None`, all instance methods will be loaded. You can also specify which instance methods to load, eg. `load_instance_methods=['init']`.
    :type load_instance_methods: None or List
    :param reset_autoclass: If this argument is set to True, and previously you restricted loading of some methods, when you call autoclass function with this argument for some class, all methods will be loaded again.
    :type reset_autoclass: None or Boolean
    :rtype: Return a :class:`ObjClass` that represent the class passed from `name`.

    >>> from pyobjus import autoclass
    >>> autoclass('NSString')
    <class '__main__.NSString'>


Utility functions
-----------------

.. function:: selector(objc_method)

    Get the selector for method spcified with objc_method parameter

    :param objc_method: Name of Objective C method for which we want to get SEL
    :type objc_method: String
    :rtype: ObjcSelector, which is Python representation for Objective C SEL type


.. function:: dereference(objc_reference[, of_type=None, return_count=None, partition=None])

    Dereference C pointer to get actual values

    :param objc_reference: `ObjcReferenceToType` Python representation of C pointer
    :param of_type: If function which you call returns value, for example, int, float, etc., in that case pyobjus can figure out type in which to convert. But if you returnes void pointer for eg. then you need to specify type in which you want to convert. Example of this is: `dereference(someObjcReferenceToType, of_type=ObjcInt)`
    :param return_count: When you are returning C array, you can/need specify number of returned values with this argument.
    :type return_count: Integer
    :param partition: when you want to dereference multidimentional array, you need to spcify dimentions. Provide list with numbers which denotes dimensions. For `int array[10][10]`, you need to specify `partition=[10, 10]`
    :rtype: Actual value for some `ObjcReferenceToType` type

.. function:: objc_c(some_char)

    Initialize `NSNumber` with `Char` type.

    :param some_char: Char parameter
    :rtype: NSNumber.numberWithChar: Python representation


.. function:: objc_i(some_int)

    Initialize `NSNumber` with `Int` type.

    :param some_int: Int parameter
    :rtype: NSNumber.numberWithInt: Python representation


.. function:: objc_ui(some_unsigned_int)

    Initialize `NSNumber` with `Unsigned Int` type.

    :param some_unsigned_int: Unsigned Int parameter
    :rtype: NSNumber.numberWithUnsignedInt: Python representation


.. function:: objc_l(some_long)

    Initialize `NSNumber` with `Long` type.

    :param some_char: Long parameter
    :rtype: NSNumber.numberWithLong: Python representation


.. function:: objc_ll(some_long_long)

    Initialize `NSNumber` with `Long Long` type.

    :param some_long_long: Long Long parameter
    :rtype: NSNumber.numberWithLongLong: Python representation


.. function:: objc_f(some_float)

    Initialize `NSNumber` with `Float` type.

    :param some_float: Float parameter
    :rtype: NSNumber.numberWithFloat: Python representation


.. function:: objc_d(some_double)

    Initialize `NSNumber` with `Double` type.

    :param some_double: Double parameter
    :rtype: NSNumber.numberWithDouble: Python representation


.. function:: objc_b(some_bool)

    Initialize `NSNumber` with `Bool` type.

    :param some_char: Bool parameter
    :rtype: NSNumber.numberWithBool: Python representation


.. function:: objc_str(some_string)

    Initialize `NSNumber` with `NSString` type.

    :param some_float: String parameter
    :rtype: NSString.stringWithUTF8String: Python representation


.. function:: objc_arr(some_array)

    Initialize `NSArray` type

    :param some_array: List of parameters. For eg: 
    
    .. code-block:: python

        objc_arr(objc_str('Hello'), objc_str('some str'), objc_i(42))


    :rtype: NSArray Python representation


.. function:: objc_dict(some_dict)

    Initialize `NSDictionary` type 

    :param some_dict: Dict parameter. For eg:
    
    .. code-block:: python

        objc_dict({
            'name': objc_str('User name'),
            'date': autoclass('NSDate').date(),
            'processInfo': autoclass('NSProcessInfo').processInfo()
        })

    :rtype: NSDictionary Python representation

Pyobjus types
-------------

.. class:: ObjcChar

.. class:: ObjcInt

    Python Int representation

.. class:: ObjcShort

.. class:: ObjcFloat

TODO: other types...


Objective-C signature format
----------------------------

Objective C signatures have a special format that could be difficult to
understand at first. Let's see in details. A signature is in the format::

    <return type><offset0><argument1><offset1><argument2><offset2><...>

The offset represent how much byte the previous argument is from the start of the memory.

All the types for any part of the signature can be one of:

* c = represent a char
* i = represent an int
* s = represent a short
* l = represent a long (l is treated as a 32-bit quantity on 64-bit programs.)
* q = represent a long long
* c = represent an unsigned char
* i = represent an unsigned int
* s = represent an unsigned short
* l = represent an unsigned long
* q = represent an unsigned long long
* f = represent a float
* d = represent a double
* b = represent a c++ bool or a c99 _bool
* v = represent a void
* `*` = represent a character string (char *)
* @ = represent an object (whether statically typed or typed id)
* # = represent a class object (class)
* : = represent a method selector (sel)
* [array type] = represent an array
* {name=type...} = represent a structure
* (name=type...) = represent a union
* bnum = represent a bit field of num bits
* ^ = represent type a pointer to type
* ? = represent an unknown type (among other things, this code is used for function pointers)

