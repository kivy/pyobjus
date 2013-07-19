#import <Foundation/Foundation.h>


@interface Car : NSObject {
}
@end

@implementation Car

/******************** <BIT FIELD TESTS> ***********************/

typedef struct bitfield {
    int a :1;
    int b :1;
} bitfield;

- (bitfield) makeBitField {
    bitfield bf;
    bf.a = 0;
    return bf;
}

/******************* </BIT FIELD TESTS> ***********************/

/******************** <UNION TESTS> ***********************/

typedef union testUn {
    unsigned long long a;
    unsigned long long b;
    int c;
} testUn;

typedef union test_un_ {
    NSRange range;
    NSRect rect;
    testUn d;
    int e;
    int f;
} test_un_;

- (test_un_) makeUnion {
    test_un_ un;
    NSRect rect = NSMakeRect(20, 40, 50, 60);
    un.rect = rect;
    return un;
}

- (test_un_*) makeUnionPtr {
    test_un_ *un = malloc(sizeof(test_un_));
    NSRect rect = NSMakeRect(10, 30, 50, 60);
    un->rect = rect;
    return un;
}

- (void) useUnion:(test_un_)un {
    // THIS WILL RAISE EXCEPTION IN PYOBJUS, BECAUSE IT SEEMS THAT LIBFFI CURRENTLY DOESN'T SUPPORT
    // PASSING UNIONS AS ARGUMENTS BY VALUE
}

- (void) useUnionPtr:(test_un_*)un_p {
    test_un_ un = un_p[0];
    printf("values --> %f %f\n", un.rect.origin.x, un.rect.origin.y);
}

- (bool) useUnionPtrTest:(test_un_*)un_p {
    test_un_ un = un_p[0];
    if(un.rect.origin.x == 20 && un.rect.origin.y == 40)
        return true;
    return false;
}

/******************** </UNION TESTS> ***********************/

/********************* <UNKNOWN TYPE TESTS> ***********************/

typedef struct {
    int a;
    int b;
    NSRect rect;
} unknown_str_new;

typedef struct {
    int a;
    int b;
    NSRect rect;
} unknown_str;

- (unknown_str) makeUnknownStr {
    unknown_str str;
    str.a = 10;
    str.rect = NSMakeRect(20, 30, 40, 50);
    return str;
}

- (void) useUnknownStr:(void*)str_vp {
    unknown_str *str_p = (unknown_str*)str_vp;
    unknown_str str = str_p[0];
    
    printf("%f\n", str.rect.origin.x);
}

/******************** </UNKNOWN TYPE TESTS> ***********************/

- (void)drive {
    NSLog(@"Driving! Vrooooom!");
}

- (void)print {
    printf("selector printed me!\n");
}

- (int*)makeCarIdint {
    int *a = malloc(sizeof(int));
    *a = (int)12345;
    return a;
}

- (short*)makeCarIdshort {
    short *a = malloc(sizeof(short));
    *a = (short)12345;
    return a;
}

- (double)makeDouble {
    double ret = 454.545;
    return ret;
}

- (double*)makeCarIddouble {
    double *a = malloc(sizeof(double));
    *a = 454.545;
    return a;
}

- (long*)makeCarIdlong {
    long *a = malloc(sizeof(long));
    *a = (long)5432;
    return a;
}

- (float*)makeCarIdfloat {
    float *a = malloc(sizeof(float));
    *a = (float)12345;
    return a;
}

- (long long*)makeCarIdlonglong {
    long long *a = malloc(sizeof(long long));
    *a = (long long)12345;
    return a;
}

- (unsigned char)makeCarIduChar {
    unsigned char a = 'i';
    return a;
}

- (char*)makeCarIdChar {
    char *a;
    a = "ivan";
    return a;
}

- (Class*) makeClass {
    Class *cls = malloc(sizeof(Class));
    *cls = [NSString class];
    return cls;
}

- (void*) makeClassVoidPtr {
    Class *cls = malloc(sizeof(Class));
    Class cl = [NSString class];
    *cls = cl;
    return (void*)cls;
}

- (NSRange) makeRange {
    NSRange r;
    r.length = 123;
    r.location = 567;
    return r;
}

- (NSRange*) makeRangePtr {
    NSRange *r_p = malloc(sizeof(NSRange));
    NSRange r;
    r.length = 123;
    r.location = 567;
    *r_p = r;
    return r_p;
}

- (NSRect*) makeRectPtr {
    NSRect *r_p = malloc(sizeof(NSRect));
    NSRect r;
    NSPoint p;
    NSSize s;
    s.width = 840;
    s.height = 600;
    p.x = 234;
    p.y = 542;
    r.origin = p;
    r.size = s;
    *r_p = r;
    return r_p;
}

- (BOOL) makeBOOL {
    return NO;
}

- (BOOL*) makeBOOLPtr:(BOOL)val {
    BOOL *b = malloc(sizeof(BOOL));
    *b = val;
    return b;
}

- (bool*) makeBoolPtr {
    bool *b = malloc(sizeof(bool));
    *b = 1;
    return b;
}

- (void*) makeBoolVoidPtr {
    void *b = malloc(sizeof(bool));
    ((bool*)b)[0] = 0;
    return b;
}

- (void*) makeBOOLVoidPtr {
    BOOL *b = malloc(sizeof(BOOL));
    ((BOOL*)b)[0] = YES;
    return b;
}

- (unsigned long long) makeULongLong {
    unsigned long long l_v = 1232432323234354534;
    return l_v;
}

- (SEL) makeSelector {
    SEL sel = @selector(print);
    return sel;
}

- (SEL*) makeSelectorPtr {
    SEL sel = @selector(print);
    SEL *sel_ptr = malloc(sizeof(SEL));
    *sel_ptr = sel;
    
    return sel_ptr;
}

- (void) useSelectorPtr:(SEL*)sel_ptr {
    SEL sel = sel_ptr[0];
    [self performSelector:sel];
}

- (void*) makeSelectorVoidPtr {
    SEL *s = malloc(sizeof(SEL));
    SEL sel = @selector(print);
    *s = sel;
    return (void*)s;
}

- (void*) makeIntVoidPtr {
    int *a = malloc(sizeof(int));
    *a = 12345;
    return (void*)a;
}

- (void*) makeFloatVoidPtr {
    float *f = malloc(sizeof(float));
    *f = 2343.233322;
    return (void*)f;
}

- (NSRange) useRange:(NSRange)r{
    printf("location: %ld, length %ld\n", r.location, r.length);
    return r;
}

- (void) useRangePtr:(NSRange*)r_p withMessage:(char*)message {
    NSRange r = r_p[0];
    printf("recieved message: %s", message);
    printf("location: %ld, length %ld\n", r.location, r.length);
}

- (void) useRangeVoidPtr:(void*)v_p {
    NSRange *r = (NSRange*)v_p;
    NSRange rng = r[0];
    printf("location: %ld, length %ld\n", rng.location, rng.length);
}

- (void) useClassInstVoidPtr:(void*)v_p {
    NSString *s = (NSString*)v_p;
    printf("Hello from NSString, with value --> %s\n", [s UTF8String]);
}

- (void) useClassVoidPtr:(void*)v_p {
    Class *cls_p = (Class*)v_p;
    [self driveWithClass:cls_p];
}

- (void) useBool:(bool)b_v {
    printf("Method recieved %d value!\n", b_v);
}

- (void) useBoolPtr:(bool*)b_ptr {
    printf("Method recieved %d value\n", *b_ptr);
}

- (void) useBOOL:(BOOL)b_val {
    printf("Method recieved %d value\n", b_val);
}

- (void) useBOOLPtr:(BOOL*)b_ptr {
    printf("Method recieved %d value\n", *b_ptr);
}

- (void) useSelectorVoidPtr:(void*)sel_v_ptr {
    SEL *sel = (SEL*)sel_v_ptr;
    SEL sl = *sel;
    [self performSelector:sl];
}

- (void) useSelector:(SEL)sel {
    [self performSelector:sel];
}

- (void)driveWithClass:(Class*)cls_p {
    Class cls = cls_p[0];
    
    NSString *s = [cls description];
    
    printf("I'm driving car with class...%s\n", [s UTF8String]);
}

- (void)driveWithCarc:(char*)carid {
    printf("I'm driving car with id: %s\n", carid);
}

- (void)driveWithCaruc:(unsigned char)carid {
    printf("I'm driving car with id: %c\n", carid);
}

- (void)driveWithCari:(int*)carid {
    printf("I'm driving car with id: %d\n", *carid);
}

- (void)driveWithCars:(short*)carid {
    printf("I'm driving car with id: %d\n", *carid);
}

- (void)driveWithCard:(double*)carid {
    
    printf("I'm driving car with id: %f\n", *carid);
}

- (void)driveWithCarl:(long*)carid {
    
    printf("I'm driving car with id: %ld\n", *carid);
}

- (void) voidToInt:(void*)v_ptr {
    int *num = (int*)v_ptr;
    printf("value --> %d\n", *num);
}

- (void) voidToFloat:(void*)v_ptr {
    float *num = (float*)v_ptr;
    printf("value --> %f\n", *num);
}

- (void) voidToStr:(void*)v_ptr {
    char *num = (char*)v_ptr;
    printf("value --> %s\n", num);
}

- (void) test_kindOf {
    NSString *s = [[NSString alloc] initWithUTF8String:"ivan"];
    NSString *st = [[NSString alloc] initWithUTF8String:"pusic"];
    BOOL b = [s isKindOfClass:[st class]];
    printf("%d", b);
}
@end

int main() {
    Car *c = [[Car alloc] init];
    unknown_str str = [c makeUnknownStr];
    [c useUnknownStr:(void*)&str];
}