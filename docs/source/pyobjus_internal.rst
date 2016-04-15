.. _pyobjus_internal:

How does Pyobjus work?
======================

.. module:: pyobjus

This part of the documentation introduces a basic understanding of how pyobjus
works.

The autoclass function
----------------------

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
NSString class with all the ObjcMethod and ObjcProperty objects attached.

So, maybe you don't want to use all the properties of the NSString class. In
that case, you can call the ``autoclass`` function in the following way::

    NSString = autoclass('NSString', copy_properties=False)

Perhaps you want to save memory and gather some speed with the autoclass method.
In that case, you can specify exactly which methods you want to load. Say you
want to load only the init and alloc methods of NSString. You can do that as
follows::

    NSString = autoclass('NSString',
                         load_class_methods=['alloc'],
                         load_instance_methods=['init'])

If you want to load only a few of the class methods, you can specify these with
the *load_class_methods* optional argument. If you want to load only a few
instance methods, you can specify these with the *load_instance_methods*
optional argument.

So, say you want to load only the *alloc* class method and all instance
methods, you can do that this way::

    NSString = autoclass('NSString', load_class_methods=['alloc'])

But, maybe at some point you want to have all the NSString class methods
available again. Okay, pyobjus can do that for you. You just need to call
the ``autoclass`` method this way::

    NSString = autoclass('NSString', reset_autoclass=True)

Calling Objective C methods
---------------------------

So, suppose that you find an appropriate way to load an Objective C
class via the autoclass function. After that, you need to consider the
following. In Objective C, you can do this::

    NSString *string = [[NSString alloc] init];

In pyobjus, we have a similar scenario. Say that we loaded a ``NSString``
in the following way::

    NSString = autoclass('NSString')

Now the ``NSString`` object contains all the `class` methods of the
``NSString`` Objective C class. Are you wondering how to get the `instance`
methods? We can answer that question. In the same way as the native Objective
C class.

So let's do this:::

    print NSString.alloc()

This will output::

    >>> <__main__.NSPlaceholderString object at 0x10b372e90>
    
We now have an allocated object and can call it's instance methods, like
``init``::

    print NSString.alloc().init()

This will output::

    >>> <__main__.__NSCFConstantString object at 0x10b4827d0>

You can also view the list of available methods with the Python ``dir``
function::

    # view class methods
    print dir(NSString)
    # view instance methods
    print dir(NSString.alloc())

So now we know how to use autoclass methods and how to access the class/instance
methods of the loaded Objective C classes. In comparison to Python, Objective C
has some additional syntax when you are passing arguments. How does pyobjus
deal with this?

With Objective C, you can declare a function as follows::

    - (void) sumNumber:(int)a and:(int)b { ... }

Internally, this method will be translated to ``sumNumber:and:`` because that's
the actual method name. Okay, now things are little clearer.

So, if you remember, pyobjus calls the ``class_copyMethodList`` and will
provide an ObjcMethod object for it. So, if you want to call this method from
Python, you might suppose you can call it in this way::

    sumNumber:and:(3, 5)

but that's wrong way to call Objective C methods using pyobjus.
Pyobjus will internally convert every `:` into `_`, so now we can call 
it with Python in this way::

    sumNumber_and_(3, 5)

So, if there is Objective C method declared in this way::

    - (void) sumNumber:(int)a and:(int)b andAlso:(int)c { ... }

You will call this method with pyobjus in the way:: 

    sumNumber_and_andAlso_(1, 2, 3)

So far we know how to call Objective C methods with pyobjus, and how to pass
arguments to them. Let's try to do that with an NSString class using the
`stringWithUTF8String:` class method::

    text = NSString.stringWithUTF8String_('some string')
    print text.UTF8String()

Here we call the `stringWithUTF8String:` class method, and after that
the `UTF8String:` instance method. As you can see from the
output, we will get `some string`, so we can see that method is making an
NSString instance, and correctly calling and returning values from these methods
which belong to NSString class.


Using Objective C properties
----------------------------

You may wonder if you can use Objective C properties with pyobjus, and if so,
how?

Using Objective C properties is really simple. Let's first make an Objective C
class::

    #import <Foundation/Foundation.h>

    @interface ObjcClass : NSObject {
    }
    @property (nonatomic) int some_objc_prop;
    @end

    @implementation ObjcClass
    @synthesize some_objc_prop;
    @end

This really simple Objective C class has an Objective C property
``some_objc_prop``. Save it as `test.m` for this example.
Later we will explain ``dylib_manager``, but for now, we will use its functions
to load the above class into pyobjus::

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

Here you can see that setting an Objective C property is very similar to how we
set it in native Objective C code.

You may be wondering how pyobjus deals with Objective C properties?
Pyobjus is calling getters and setters for that property because in Objective C,
there are default names for getters/setters.
    
So for the mentioned property, the getter will be `some_objc_prop`, and the
setter `setSome_objc_prop`. I suppose that you can figure out how Objective C
generate names for getters and setters for properties. The getter will have the
same name as the property, and the setter will be constructed in the following
way: 'set' will be added as a prefix to the property name, the first letter of
property will be capitalized and the rest of letters added. The result of that
is the name of property setter.

Basically, that's how pyobjus manages things, and how to use pyobjus properties.
It is really simple and intuitive.