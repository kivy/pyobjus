from pyobjus import *

# In following examples will be demonstrated pyobjus literals feature
# First line will denote native objective c literals, and second pyobjus literls
# SOURCE: http://clang.llvm.org/docs/ObjectiveCLiterals.html

# NSNumber *theLetterZ = @'Z';          // equivalent to [NSNumber numberWithChar:'Z']
objc_c('Z')

# NSNumber *fortyTwo = @42;             // equivalent to [NSNumber numberWithInt:42]
objc_i(42)

# NSNumber *fortyTwoUnsigned = @42U;    // equivalent to [NSNumber numberWithUnsignedInt:42U]
objc_ui(42)

# NSNumber *fortyTwoLong = @42L;        // equivalent to [NSNumber numberWithLong:42L]
objc_l(42)

# NSNumber *fortyTwoLongLong = @42LL;   // equivalent to [NSNumber numberWithLongLong:42LL]
objc_ll(42)

# NSNumber *piFloat = @3.141592654F;    // equivalent to [NSNumber numberWithFloat:3.141592654F]
objc_f(3.141592654)

# NSNumber *piDouble = @3.1415926535;   // equivalent to [NSNumber numberWithDouble:3.1415926535]
objc_d(3.1415926535)

# NSNumber *yesNumber = @YES;           // equivalent to [NSNumber numberWithBool:YES]
objc_b(True)

# NSNumber *noNumber = @NO;             // equivalent to [NSNumber numberWithBool:NO]
objc_b(False)

# NSArray *array = @[ @"Hello", NSApp, [NSNumber numberWithInt:42] ];
objc_arr(objc_str('Hello'), objc_str('some str'), objc_i(42))

# NSDictionary *dictionary = @{
#    @"name" : NSUserName(),
#    @"date" : [NSDate date],
#    @"processInfo" : [NSProcessInfo processInfo]
# };
objc_dict({
    'name': objc_str('User name'),
    'date': autoclass('NSDate').date(),
    'processInfo': autoclass('NSProcessInfo').processInfo()
})

# NSString *string = @"some string";
objc_str('some string')
