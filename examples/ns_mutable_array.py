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
