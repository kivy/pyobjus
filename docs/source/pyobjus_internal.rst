.. _pyobjus_internal:

How Pyobjus works?
==================

.. module:: pyobjus

This part of the documentation introduces a basic understanding of how pyobjus
works.

autoclass function
------------------

So, autoclass is the heart of pyobjus. With this function, you load Objective C
classes into pyobjus which then constructs a Python wrapper around these
objects.

Let's say that we are in the situation where we need to load a NSString class
belonging to the Foundation framework.

You can load external code into pyobjus using the ``load_framework`` function,
or by using ``load_dylib``. The ``load_framework`` function uses NSBundle for
loading the framework into pyobjus, and the ``load_dylib`` function uses ctypes
for loading external .dylib objects into pyobjus.

Notice that you don't need to explicitly load the Foundation framework into
pyobjus because the Foundation framework is loaded by default. But if you want
AppKit, for example, you can do something like this::

    from pyobjus.dylib_manager import load_framework, INCLUDE
    load_framework(INCLUDE.AppKit)

This will load code from the AppKit framework into pyobjus, so now we can use
these classes.

But let's return to our NSString class from the Foundation framework. To load
this class, type the following::

    from pyobjus import autoclass
    NSString = autoclass('NSString')

What happened here? So, pyobjus will call the ``class_copyMethodList`` function
of the Objective C runtime. After that, it will create an ObjcMethod Python
object for every method attached to the class as well as an ObjcProperty for
every attached property. It will then return a Python representation of the
NSString class with both ObjcMethod and ObjcProperty objects attached.

So, maybe you don't want to use all the properties of the NSString class. In
that case, you can call the ``autoclass`` function in the following way::

    NSString = autoclass('NSString', copy_properties=False)

Perhaps you want to save memory and gather some speed with the autoclass method.
In that case, you can specify exactly which methods you want to load. Say you
want to load only the init and alloc methods of NSString. You can do that by
running the following lines of code::

    NSString = autoclass('NSString',
                         load_class_methods=['alloc'],
                         load_instance_methods=['init'])

So, as you can suppose, if you want to load only few of class methods, you need to specify it with 
load_class_methods optional argument, and if you want to load only few of instance methods, 
you can specify it with load_instance_methods optional arg.

So, if you want to load alloc class method and all instance methods, you can do that in this way::

    NSString = autoclass('NSString', load_class_methods=['alloc'])

But, maybe in the some point you want to have all methods available again with NSString class. 
Okey, pyobjus can do that for you. You need to call ``autoclass`` method in this way::

    NSString = autoclass('NSString', reset_autoclass=True)

Calling Objective C methods
---------------------------

So, I suppose that you find appropriate way to load Objective C class with autoclass function.
After that you need to consider this.

In native Objective C you can do this::

    NSString *string = [[NSString alloc] init];

In pyobjus is simmilar situation. Let's say that we loaded NSString in following way::

    NSString = autoclass('NSString')

Now ``NSString`` object contains all `class` methods of NSString Objective C class.
Are you wondering how to get `instance` methods? I can answer you that question...In the same way like in the native Objective C.

So let's do this:::

    print NSString.alloc()

This will output::

    >>> <__main__.NSPlaceholderString object at 0x10b372e90>
    
So, as you can see, we have allocated object, and we can now call instance methods, like ``init``::

    print NSString.alloc().init()

This will output with::

    >>> <__main__.__NSCFConstantString object at 0x10b4827d0>

You can also view list of available methods with Python ``dir`` function::

    # view class methods
    print dir(NSString)
    # view instance methods
    print dir(NSString.alloc())


For now, we know how to use autoclass method, and how to use class/instance method of loaded class.
As far as you know, in comparison with Python, Objective C has maybe little syntax when you are passing arguments to it.
So, how pyobjus deals with this?

With Objective C you can declare following function::

    - (void) sumNumber:(int)a and:(int)b { ... }

Internally this method will be translated into ``sumNumber:and:``, because that's actual method name.
Okey, now things are little clearer. 

So, if you remember, pyobjus will call ``class_copyMethodList`` which will return this method too, 
and it will make ObjcMethod object for it. So if you want to call this method from Python you will maybe suppose to call it in this way sumNumber:and:(3, 5), but that's wrong way to call Objective C method with pyobjus.
Pyobjus will internally convert every `:` into `_`, so now we can call 
it with Python in this way::

    sumNumber_and_(3, 5)

So, if there is Objective C method declared in this way::

    - (void) sumNumber:(int)a and:(int)b andAlso:(int)c { ... }

You will call this method with pyobjus in the way:: 

    sumNumber_and_andAlso_(1, 2, 3)

So far we know how to call Objective C methods with pyobjus, and how to pass arguments to them. 
Let's try do that with NSString class with `stringWithUTF8String:` class method::

    text = NSString.stringWithUTF8String_('some string')
    print text.UTF8String()

This we call `stringWithUTF8String:` class method, and after that `UTF8String:` instance method. As you can see on
output, we will get `some string`, so we can see that method is making NSString instance, and correctly calling and returning values of methods, which belongs to NSString class.


Using Objective C properties
----------------------------

So, you may wonder if you can use Objective C properties with pyobjus, and if you could, how?

Using Objective C properties is really simple. Let's first make Objective C class::

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
Later we will explain ``dylib_manager``, so for now, we will use its functions to load above class into pyobjus::

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

Here you can see that setting Objective C property is very similar as we set it in native Objective C code.

You may be wondering how pyobjus deal with Objective C properties.
Pyobjus is calling getters and setters of property, because in Objective C there are default names 
for getters/setters. 
    
So for the mentioned property, getter will be `some_objc_prop`, and setter
`setSome_objc_prop`. I suppose that you can figure out in which way Objective C generate names 
for getters and setters for properties. So getter will have the same name as property has, and setter will be constructed in a following way: on the property name will be added prefix set, 
and first letter of property will be capitalized, and we add rest of letters, and result of that is the name of
property setter.

Basically, that's about how pyobjus manage, and how to use pyobjus properties. 
It is really simple and intuitive.