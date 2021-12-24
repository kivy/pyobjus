from pyobjus import autoclass, selector
from pyobjus.dylib_manager import load_dylib

# Let we say that we have defined following structures in our dylib
# Note that we arent specify type of structs, so they types will be missing in method signatures

# typedef struct {
#   float a;
#   int b;
#   NSRect rect;
# } unknown_str_new;

# typedef struct {
#   int a;
#   int b;
#   NSRect rect;
#   unknown_str_new u_str;
# } unknown_str;

load_dylib('testlib.dylib', usr_path=False)
Car = autoclass('Car')
car = Car.alloc().init()

# Let's play know. Suppose that we have defined following objective c method:
# - (unknown_str) makeUnknownStr {
#   unknown_str str;
#   str.a = 10;
#   str.rect = NSMakeRect(20, 30, 40, 50);
#   str.u_str.a = 2.0;
#   str.u_str.b = 4;
#   return str;
# }

# Purpose of this method is to make unknown type struct, and assing some values to it's members
# If you see debug logs of pyobjus, you will see that method returns following type:
# {?=ii{CGRect={CGPoint=dd}{CGSize=dd}}{?=fi{CGRect={CGPoint=dd}{CGSize=dd}}}}

# From this we can see that method returns some type, which contains of two integers, and two structs. One of them
# is CGRect, and another is some unknown type, which contains of float, integer and CGRect struct
# So, if user doesn't have defined this struct, pyobjus can generate this type for him. Let's call this function:
ret_type = car.makeUnknownStr()

ret_type = car.makeUnknownStr(members=['first', 'second', 'struct_field', 'tmp_field'])

# But wait, how will pyobjus know about field names in struct, because from method signature we know 
# only types, not actual names. Well, pyobjus will generate some 'random' names in alphabetical order
# In our case, first member will have name 'a', second will have name 'b', and third will have name CGRect,
# which is used because can help user as indicator of type is actual type is missing. Last one is another 
# unknown type, so pyobjus will generate name for him and it will have name 'c'. 
# Note that in case of CGRect, that memeber will have origin and size members, because he is already defined, 
# and we know info about his members, but for last member, pyobjus will continue recursive generating names 
# for it's members
# Maybe you are asking yourself know, how you will know actual generated name, so pyobjus will help you about this.
# There is getMembers function, which returns name and type of some field in struct.
print ret_type.getMembers()

# If you don't need types, only names, you can call method in following way:
print ret_type.getMembers(only_fields=True)

# Also, if you want to know only names, you can get it on following way
print ret_type.getMembers(only_types=True)

# If you want to use returned type to pass it as argument to some function there will be some problems. 
# Pyobjus is using ctypes structures, so we can get actual pointer to c structure from python object,
# but if we want to get working correct values of passed arg, we need to cast pointer to appropriate type
# If type is defined in pyobjus/objc_cy_types pyobjus will cost it for us, but if it isn't, we will need to convert
# it by ourselfs, for example internally in function where we are passing struct value. Lets see example of this:

# - (void) useUnknownStr:(void*)str_vp {
#   unknown_str *str_p = (unknown_str*)str_vp;
#   unknown_str str = str_p[0];
#   printf("%f\n", str.rect.origin.x);
# }

car.useUnknownStr_(ret_type)

# We can see that we are casting to appropriate type (inside of useUnknownStr_ method)

# Another use-case of unknown type signature is with pointers to implementations of methods. 
# As you known every method has pointer to IMP type, which is actual implementation of that method.
# So, if we need to get IMP of some method, we can do something like this:
imp = car.methodForSelector_(selector('getSumOf:and:'))

# Method signature for return type of this function is ^?, so that is also some unknown type.
# As you knows, when we have IMP of method, we can also pass IMP as argument, and call method behind IMP pointer
# - (int) useImp:(IMP)imp withA:(int)a andB:(int)b {
#   return (int)imp(self, @selector(getSumOf:and:), a, b);
# })
print car.useImp_withA_andB_(imp, 5, 7)
