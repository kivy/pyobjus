from pyobjus import autoclass, dereference
from pyobjus.dylib_manager import load_dylib

# Let we say, we have defined following union types in Car class
# typedef union testUn {
#   unsigned long long a;
#   unsigned long long b;
#   int c;
# } testUn;

# typedef union test_un_ {
#   NSRange range;
#   NSRect rect;
#   testUn d;
#   int e;
#   int f;
# } test_un_;

load_dylib('testlib.dylib', usr_path=False)
Car = autoclass('Car')
car = Car.alloc().init()

# With pyobjus users can call function which returns union by value
# - (test_un_) makeUnion {
#   test_un_ un;
#   NSRect rect = NSMakeRect(10, 30, 50, 60);
#   un.rect = rect;
#   return un;
# }
union = car.makeUnion()
print union.rect.origin.x, union.rect.origin.y

# Also there is ability to call function which returns pointer to some union type
# - (test_un_*) makeUnionPtr {
#   test_un_ *un = malloc(sizeof(test_un_));
#   NSRect rect = NSMakeRect(10, 30, 50, 60);
#   un->rect = rect;
#   return un;
# }
union_ptr = car.makeUnionPtr()
union_val = dereference(union_ptr)
print union_val.rect.origin.x, union_val.rect.origin.y

# BUT, currently passing unions by value to some function isn't supported,
# because pyobjus use libffi, which doesn't support that feature
# - (void) useUnion:(test_un_)un {
#   // THIS WILL RAISE EXCEPTION IN PYOBJUS
# }
# this would cause ObjcException error! --> c.useUnion_(union)

# FORTUNATELY, passing unions as pointes to some function IS SUPPORTED in pyobjus
# - (void) useUnionPtr:(test_un_*)un_p {
#   test_un_ *un_ = (test_un_*)un_p;
#   test_un_ un = un_[0];
#   printf("values --> %f %f\n", un.rect.origin.x, un.rect.origin.y);
# }
car.useUnionPtr_(union_ptr)

# Because pyobjus internally convert union values to union pointer (if that is needed),
# we can also call this function by passing union value (value will be converted to pointer internally)
car.useUnionPtr_(union)
