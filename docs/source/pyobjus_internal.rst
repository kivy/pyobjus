.. _pyobjus_internal:

How Pyobjus works?
==================

.. module:: pyobjus

This part of the documentation introduces basic understanding how pyobjus works

autoclass function
------------------

So, autoclass is the heart of pyobjus. With this function you load Objective C classes into pyobjus, and pyobjus 
internalty set some things for itself.

Let we say that we are in situation where we need to load NSString class which belongs to Foundation framework.

You can load external code into pyobjus by using ``load_framework`` function, or by using ``load_dylib``.
``load_framework`` function use NSBundle for loading framework into pyobjus, and ``load_dylib`` function use ctypes
for loading external .dylib into pyobjus.

Note that you don't need explicitly load Foundation framework into pyobjus, because Foundation framework is loaded by default into pyobjus. But if you want AppKit for example, you can do sommething like this::

    from pyobjus.dylib_manager import load_framework, INCLUDE
    load_framework(INCLUDE.AppKit)

This will load code from AppKit framework into pyobjus, so now we can use these classes. 

But let we return to our NSString class of Foundation framework. To load this class type the following::

    from pyobjus import autoclass
    NSString = autoclass('NSString')

What happened here? So, pyobjus will call ``class_copyMethodList`` function of objective c runtime, and after that it will create ObjcMethod Python object for every class returned with mentioned function, and after that it will return Python representation of NSString, which also contains ObjcMethod, and ObjcProperties objects.

So, maybe you don't want to use properties of NSString class (if they exist at all). In that case you can call ``autoclass`` function of following way::

    NSString = autoclass('NSString', copy_properties=False)

Maybe you want to save memory, and gather some speed with autoclass method. In that case you will need 
to specify methods which you want to load with autoclass. So if you want to load only init and alloc 
methods of NSString, you can run following line of code::

    NSString = autoclass('NSString', load_class_methods=['alloc'], load_instance_methods=['init'])

So as you can suppose, if you want to load only few of class methods, you need to specify it with 
load_class_methods optional argument, and if you want to load only few of instance methods, 
you can specify it with load_instance_methods optional arg.

So, if you want to load alloc class method, and all instance methods you can do that on this way::

    NSString = autoclass('NSString', load_class_methods=['alloc'])

But, maybe on the some point you want to have all methods available again with NSString class. 
Okey, pyobjus can do that for you. You need to call ``autoclass`` method on this way::

    NSString = autoclass('NSString', reset_autoclass=True)

Calling Objective C methods
---------------------------

So, I suppose that you find appropriate way to load Objective C class with autoclass function.
After that you need to consider this.

In native Objective C you can do this::

    NSString *string = [[NSString alloc] init];

In pyobjus is simmilar situation. Let we say that we loaded NSString on following way::

    NSString = autoclass('NSString')

Now ``NSString`` object contains all `class` methods of NSString Objective C class.
You can maybe ask yourself how to get `instance` methods? I can aswer you on that question...On the same way like in the native Objective C.

So let do this:::

    print NSString.alloc()

This will output::

    >>> <__main__.NSPlaceholderString object at 0x10b372e90>
    
So as you can see we have allocated object, and we now can call instance methods, like ``init``::

    print NSString.alloc().init()

This will output with::

    >>> <__main__.__NSCFConstantString object at 0x10b4827d0>

You can also inspect list of available methods with Python ``dir`` function::

    # inspect class methods
    print dir(NSString)
    # inspect instance methods
    print dir(NSString.alloc())


So for now we know how to use autoclass method, and how to use class/instance method of loaded class.
But as you know, Objective C has maybe little syntax when you passing arguments to it, 
in a comparasion with Python, so how pyobjus deal with this?

With Objective C you can declare following function::

    - (void) sumNumber:(int)a and:(int)b { ... }

Internaly this function will be translated into ``sumNumber:and:``, so that's actual function name.
Okey, now things are little clearer. 

So if you remember, pyobjus will call ``class_copyMethodList`` which will return and this method, 
and it will make ObjcMethod object for it. So it you want to call this method from Python you will maybe suppose to call it on this way sumNumber:and:(3, 5), but that's wrong way to call Objective C method with pyobjus.
Pyobjus will internaly convert every `:` into `_`, so we now can call 
it with Python in the way::

    sumNumber_and_(3, 5)

So if there is Objective C method declared on this way::

    - (void) sumNumber:(int)a and:(int)b andAlso:(int)c { ... }

You will call this method with pyobjus in the way:: 

    sumNumber_and_andAlso_(1, 2, 3)

So far we know how to call Objective C methods with pyobjus, and how to pass arguments to them. 
Let try do that with NSString class with `stringWithUTF8String:` class method::

    text = NSString.stringWithUTF8String_('some string')
    print text.UTF8String()

This we call `stringWithUTF8String:` class method, and after that `UTF8String:` instance method. As you can see on
output we will get `some string`, so we can see that method is making NSString instance, and correctly calling and returning values of methods, which belongs to NSString class.


Using Objective C properties
----------------------------

So you may wonder can you use Objective C properties with pyobjus, and if you can, how?

Using Objective C properties is really really simple. Let we first make Objective C class::

    #import <Foundation/Foundation.h>

    @interface ObjcClass : NSObject {
    }
    @property (nonatomic) int some_objc_prop;
    @end

    @implementation ObjcClass
    @synthesize some_objc_prop;
    @end

We can see above really simple Objective C class which Objective C property ``some_objc_prop``. 
Save it as `test.m` for example.
Later we will explain ``dylib_manager``, so for now we will use his functions to load above class into pyobjus::

    from pyobjus.dylib_manager import load_dylib, make_dylib
    from pyobjus import autoclass
    
    # TODO: change path to your
    make_dylib('/path/to/test.m', frameworks=['Foundation'])
    # TODO: change path to your
    load_dylib('/path/to/test.dylib')

    ObjcClass = autoclass('ObjcClass')
    o_cls = ObjcClass.alloc().init()

    # now we can set property value
    o_cls.some_objc_prop = 12345
    # or retrieve value of that property
    print o_cls.some_objc_prop

Here you can see that setting Objective C property is very simmilay as we set it in native Objective C code.

You may ask yourself how pyobjus deal with Objective C properties.
Pyobjus is calling getters and setters of property, because in Objective C there are default names 
for getters/setters. 
    
So For mentioned property, getter will be `some_objc_prop`, and setter
`setSome_objc_prop`. I suppose that you can figure out with which rules Objective C generate names 
for getters and setters for properties. So getter will have the same name as property has, and setter will be constructed in a following way: on the property name will be added prefix set, 
and first letter of property will be capitalized, and we add rest of letters, and result of that is the name of
property setter.

Basicaly that's about how pyobjus manage, and how to use pyobjus properties. 
It is really simple and intuitive.
