#import <Foundation/Foundation.h>

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

- (void) useRangePtr:(NSRange*)r_p {
    NSRange r = r_p[0];
    
    printf("location: %ld, length %ld\n", r.location, r.length);
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

- (void) useSelector:(SEL)sel {
    [self performSelector:sel];
}

- (void)driveWithClass:(Class*)cls_p {
    printf("class !!!!");
    Class cls = cls_p[0];
    NSString *s = [cls description];
    printf("I'm driving car with class...%s:\n", [s UTF8String]);
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
    chr = "ivan";
    [c voidToStr:(void*)chr];
}

