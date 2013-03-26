.. _api:

API
===

.. module:: pyobjus

This part of the documentation covers all the interfaces of Pyobjus.

Reflection functions
--------------------

.. function:: autoclass(name)

    Return a :class:`ObjClass` that represent the class passed from `name`.

    >>> from pyobjus import autoclass
    >>> autoclass('NSString')
    <class '__main__.NSString'>


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

