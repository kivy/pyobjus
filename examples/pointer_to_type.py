from pyobjus import autoclass, dereference, objc_py_types as opy, ObjcSelector
from pyobjus.dylib_manager import load_dylib

load_dylib('testlib.dylib', usr_path=False)
NSString = autoclass('NSString')
NSValue = autoclass('NSValue')
# this is class defined in user dynamic lib (objc_test/testlib.m)
Car = autoclass('Car')
car = Car.alloc().init()

# first, let's call method which returns SEL value...
# - (SEL) makeSelector {
#   SEL sel = @selector(print);
#   return sel;
# }
sel = car.makeSelector()

# then call method useSelector with returned value from previous call
# - (void) useSelector:(SEL)sel {
#   [self performSelector:sel];
# }
car.useSelector_(sel)

# we can also call method which returns pointer to selector -> SEL*
# when we call method which returns pointer to some type, it will be saved into ObjcReferenceToType class instance 
# - (SEL*) makeSelectorPtr {
#   SEL sel = @selector(print);
#   SEL *sel_ptr = malloc(sizeof(SEL));
#   *sel_ptr = sel;
#   return sel_ptr;
# }
sel_ptr = car.makeSelectorPtr()

# we can know use ObjcReferenceToType as argument on method, which accepts pointer to SEL (SEL*)
# - (void) useSelectorPtr:(SEL*)sel_ptr {
# SEL sel = sel_ptr[0];
# [self performSelector:sel];
# }
car.useSelectorPtr_(sel_ptr)

# but what if we have selector value (not reference) and we want to call method which accepts reference, not value?
# Luckily pyobjus is smart enough to figure out that method which we call accepts reference, 
# and also knows are we passing reference or value to some method.
# So if we pass a value, he will by himself convert it to reference to some type which method accepts, 
# and with this user is freed of thinking is method accepting value, or reference to some type
car.useSelectorPtr_(sel)

# As we knows, in native Objective C we can dereference pointer to get actual value on which pointer points
# Pyobjus also have mechanism of dereferencing some pointer. He is also smart enough to know on which type 
# he need to cast value on which pointer points.
sel = dereference(sel_ptr)
print sel

# There is one limitation of dereference function in cases when we have function which returns void pointer (void*)
# But pyobjus can also deal with this situation, user only need to tell pyobjus in which type to convert
# - (void*) makeSelectorVoidPtr {
#   SEL *s = malloc(sizeof(SEL));
#   SEL sel = @selector(print);
#   *s = sel;
#   return (void*)s;
# }
sel_void_ptr = car.makeSelectorVoidPtr()
sel = dereference(sel_void_ptr, of_type=ObjcSelector)
print sel
