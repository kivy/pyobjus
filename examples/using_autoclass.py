from pyobjus import autoclass

# First we load NSString into pyobjus
NSString = autoclass('NSString')

# Then we can call some class methods of NSString
text = NSString.stringWithUTF8String_('some string')

# Now we can call instance methods
print text.UTF8String()

# If you want to improve performance of you app, consider following
print dir(NSString)

# As you can see, there is a lot of methods which pyobjus is loaded for us.
# If we don't need all of them, we can load only those which we need. Eg:
NSString = autoclass('NSString', load_class_methods=['alloc'], \
    load_instance_methods=['init', 'initWithString:', 'UTF8String'])

# So if we now see content on NSString object, we wil see that we have much less subobjects in NSString 
print dir(NSString)
instance = NSString.alloc()

# we limited instance method which will be load also
print dir(instance)

# because we haven't loaded initWithUTF8String: method, this will raise exception
try:
    instance.initWithUTF8String_('some string')
except:
    print "EXCEPTION!"

# But we loaded initWithString: method, so we can use that one
print instance.initWithString_(text).UTF8String()

# And if you want to reset autoclass caching system, so we can use all methods in next steps, 
# you simply need to run this line of code
NSString = autoclass('NSString', reset_autoclass=True)
print dir(NSString)
text = NSString.stringWithUTF8String_('some string')
print text.UTF8String()
print dir(NSString.alloc())
