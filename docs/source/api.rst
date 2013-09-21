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

Global variables
----------------

.. data:: dev_platform

    Platform for which pyobjus is compiled

Pyobjus Objective C types
-------------

.. class:: ObjcChar

    Objective C ``char`` representation

.. class:: ObjcInt

    Objective C ``int`` representation

.. class:: ObjcShort

    Objective C ``short`` representation

.. class:: ObjcLong

    Objective C ``long`` representation 

.. class:: ObjcLongLong

    Objective C ``long long`` representation

.. class:: ObjcUChar

    Objective C ``unsigned char`` representation

.. class:: ObjcUInt

    Objective C ``unsigned int`` representation

.. class:: ObjcUShort

    Objective C ``unsigned short`` representation

.. class:: ObjcULong

    Objective C ``unsigned long`` representation

.. class:: ObjcULongLong

    Objective C ``unsigned long long`` representation

.. class:: ObjcFloat

    Objective C ``float``` representation

.. class:: ObjcDouble

    Objective C ``double`` representation

.. class:: ObjcBool

    Objective C ``bool`` representation

.. class:: ObjcBOOL

    Objective C ``BOOL`` representation

.. class:: ObjcVoid

    Objective C ``void`` representation

.. class:: ObjcString

    Objective C ``char*`` representation

.. class:: ObjcClassInstance

    Representation of Objective C class instance

.. class:: ObjcClass

    Representation of Objective C ``Class``

.. class:: ObjcSelector

    Representation of Objective C ``SEL``

.. class:: ObjcMethod

    Representation of Objective C method

.. class:: CArray

    Representation of Objective C (C) array

.. class:: CArrayCount

    Representation of type, which holds ``outCount*`` for some C array -> number of received array elements

.. exception:: ObjcException

    Representation of some Objective C exception

Structure types
---------------

.. module:: pyobjus.objc_py_types

.. class:: NSRange

    .. cmember:: unsigned long long location

    .. cmember:: unsigned long long length

.. class:: NSPoint

    .. cmember:: double x

    .. cmember:: double y

.. class:: NSSize

    .. cmember:: double width

    .. cmember:: double height

.. class:: NSRect

    .. cmember:: NSPoint origin

    .. cmember:: NSSize size

Enumeration types
-----------------

.. module:: pyobjus.objc_py_types

.. class:: NSComparisonResult

    .. attribute:: NSOrderedAscending = -1
    .. attribute:: NSOrderedSame = 0
    .. attribute:: NSOrderedDescending = 1

.. class:: NSStringEncoding

    .. attribute:: NSASCIIStringEncoding = 1
    .. attribute:: NSNEXTSTEPStringEncoding = 2
    .. attribute:: NSJapaneseEUCStringEncoding = 3
    .. attribute:: NSUTF8StringEncoding = 4
    .. attribute:: NSISOLatin1StringEncoding = 5
    .. attribute:: NSSymbolStringEncoding = 6
    .. attribute:: NSNonLossyASCIIStringEncoding = 7
    .. attribute:: NSShiftJISStringEncoding = 8
    .. attribute:: NSISOLatin2StringEncoding = 9
    .. attribute:: NSUnicodeStringEncoding = 10
    .. attribute:: NSWindowsCP1251StringEncoding = 11
    .. attribute:: NSWindowsCP1252StringEncoding = 12
    .. attribute:: NSWindowsCP1253StringEncoding = 13
    .. attribute:: NSWindowsCP1254StringEncoding = 14
    .. attribute:: NSWindowsCP1250StringEncoding = 15
    .. attribute:: NSISO2022JPStringEncoding = 21
    .. attribute:: NSMacOSRomanStringEncoding = 30
    .. attribute:: NSUTF16StringEncoding = 10
    .. attribute:: NSUTF16BigEndianStringEncoding = 0x90000100
    .. attribute:: NSUTF16LittleEndianStringEncoding = 0x94000100
    .. attribute:: NSUTF32StringEncoding = 0x8c000100
    .. attribute:: NSUTF32BigEndianStringEncoding = 0x98000100
    .. attribute:: NSUTF32LittleEndianStringEncoding = 0x9c000100
    .. attribute:: NSProprietaryStringEncoding = 65536


Dynamic library manager
-----------------------

.. module:: pyobjus.dylib_manager

.. function:: load_dylib(path)

    Function for loading user defined dylib

    :param path: Path to some dylib

.. function:: make_dylib(path [, frameworks=None, out=None, options=None])

    Function for making dylib from Python

    :param path: Path to files 
    :param frameworks: List of frameworks to link with.
    :type frameworks: List
    :param options: List of options for compiler
    :type options: List
    :param out: Out location. Default is to write on location specified by path arg

.. function:: load_framework(framework)

    Function loads Objective C framework via NSBundle

    :param framework: Path to framework
    :type framework: String
    :raises: ``ObjcException`` if framework can't be found

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

