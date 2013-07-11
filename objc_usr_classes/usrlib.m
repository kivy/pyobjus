#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/objc-runtime.h>

@interface Car : NSObject {
}

- (void)drive;

- (void)driveWithCari:(int*)carid;
- (void)driveWithCars:(short*)carid;
- (void)driveWithCard:(double*)carid;
- (void)driveWithCarl:(long*)carid;

- (int*)makeCarIdint;
- (short*)makeCarIdshort;
- (double*)makeCarIddouble;
- (long*)makeCarIdlong;
- (float*)makeCarIdfloat;
- (long long*)makeCarIdlonglong;

- (unsigned char)makeCarIduChar;
//- (char)makeCarIdChar;

@end

@implementation Car

- (void)drive {
    NSLog(@"Driving! Vrooooom!");
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

- (void)print {
    printf("selector printed me!\n");
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

- (void) useRangePtr:(NSRange*)r_p {
    NSRange r = r_p[0];
    
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
    NSObject *ob = [[NSObject alloc] init];
    BOOL b = [s isKindOfClass:[st class]];
    printf("%d", b);
}

@end


int main() {
    Car *c = [[Car alloc] init];
    [c drive];
    unsigned long long *ptr;
    ptr = malloc(1000);
    printf("%p %p\n", (unsigned long long*)ptr, (void*)ptr);

    [c driveWithCarc:[c makeCarIdChar]];
    SEL s = [c makeSelector];
    [c useSelector:s];
    SEL *s_p = malloc(sizeof(16));
    *s_p = s;
    [c useSelectorPtr:s_p];
    [c useRangePtr:[c makeRangePtr]];
    Class *_cls = malloc(sizeof(Class));
    Class __cls = [NSArray class];
    *_cls = __cls;
    int *a = malloc(sizeof(int));
    *a = 2345;
    [c voidToInt:(void*)a];
    float *b = malloc(sizeof(float));
    *b = 233232.33;
    [c voidToFloat:(void*)b];
    char *chr = malloc(sizeof(char));
    chr = "iv";
    char **ch = malloc(sizeof(char*));
    ch[0] = chr;
    [c voidToStr:(void*)*ch];
    NSRange *rn = malloc(sizeof(NSRange));
    rn[0].length = 123;
    rn[0].location = 432;
    [c useRangeVoidPtr:(void*)rn];
    NSString *str = @"ivan";
    [c useClassInstVoidPtr:(void*)str];
    [c useClassVoidPtr:(void*)[Car class]];
    Class ocls = [c class];
    NSString *desc = [ocls description];
    NSObject *ob = [[NSObject alloc] init];
    printf("%f\n", [c makeDouble]);
    char *enc = @encode(NSRange);
    void *p_s = [c makeSelectorVoidPtr];
    [c useSelectorVoidPtr:p_s];
    printf("End of program!");
}

