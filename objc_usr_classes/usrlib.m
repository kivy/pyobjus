#import <Foundation/Foundation.h>

@interface Car : NSObject {
}

- (void)drive;
- (void)driveWithCar:(double*)carid;
- (int*)makeCarIdint;
- (short*)makeCarIdshort;
- (double*)makeCarIddouble;
- (long*)makeCarIdlong;
- (float*)makeCarIdfloat;
- (long long*)makeCarIdlonglong;

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
    printf("val --> %lf\n", *a);
    return a;
}

- (long*)makeCarIdlong {
    long *a = malloc(sizeof(long));
    *a = (long)12345;
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

- (void)driveWithCar:(double*)carid {
    
    printf("I'm driving car with id: %f\n", *carid);
}

@end


int main() {
    Car *c = [[Car alloc] init];
    [c drive];
    double *d = [c makeCarIdint];
    [c driveWithCar:d];
    printf("bubu %ld %f", d, *d);
}

