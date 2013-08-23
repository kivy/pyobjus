#import "CArrayTestlib.h"

@implementation ClassFoo
{
    int a;
}
@end

@implementation CArrayTestlib
{
    int values[10];
    char char_t[10];
    short short_t[10];
    long long_t[10];
    long long longlong_t[10];
    
    float float_t[10];
    double double_t[10];
    
    unsigned int uint_t[10];
    unsigned short ushort_t[10];
    unsigned long ulong_t[10];
    unsigned long long ulonglong_t[10];
    unsigned char uchar_t[10];
    
    bool bool_t[10];
    
    char* char_ptr_arr[10];
    NSNumber * __unsafe_unretained ns_number_arr[10];
    Class class_arr[10];
    SEL sel_arr[10];
    int int_2d_arr[10][10];
    bar foobar_arr[10];
}

- (id) init
{
    self = [super init];
    if (self)
    { }
    
    NSLog(@"Constructing object.");
    return self;
}


//  int[10] array
- (void) setIntValues:(int[10])val_arr
{
    NSLog(@"Setting int array values...");
    memcpy(self->values, val_arr, sizeof(int) * 10);
    NSLog(@"Values copied...");
}

- (int*) getIntValues
{
    if (!self->values)
    {
        NSLog(@"Values have not been set.");
        return NULL;
    }
    else
        return self->values;
}

- (void) printIntValues
{
    if (!values)
        NSLog(@"Values have not been set.");
    else
    {
        NSLog(@"Printing Values...");
        for (int i = 0; i < 10; ++i)
            NSLog(@"%d", self->values[i]);
    }
}

- (int*) getIntValuesWithCount:(unsigned int*) n
{
    NSLog(@" ... ... [+] getIntValuesWithCount(n=%zd)", n);
    NSLog(@" ... ... [+] *n=%zd", *n);
    if (!self->values)
    {
        NSLog(@"Values have not been set");
        return NULL;
    }
    else
    {
        *n = 10;
        NSLog(@" ... ... [+] getIntValuesWithCount(n=%zd)", n);
        NSLog(@" ... ... [+] *n=%zd", *n);
        return self->values;
    }
}


// char[10] array
- (void) setCharValues: (char[10]) val_arr
{
    NSLog(@"Setting char array values...");
    memcpy(self->char_t, val_arr, sizeof(char) * 10);
    NSLog(@"Values copied...");
}

- (char*) getCharValues
{
    if (!self->char_t)
    {
        NSLog(@"Values have not been set.");
        return NULL;
    }
    else
    {
        return self->char_t;
    }
}
- (char*) getCharValuesWithCount: (unsigned int*) n
{
    if (!self->char_t)
    {
        NSLog(@"Values have not been set.");
        return NULL;
    }
    else
    {
        *n = 10;
        return self->char_t;
    }
}


// short[10] array
- (void) setShortValues: (short[10]) val_arr
{
    NSLog(@"Setting short array values...");
    memcpy(self->short_t, val_arr, sizeof(short) * 10);
    NSLog(@"Values copied...");
}
- (short*) getShortValues
{
    if (!self->short_t)
    {
        NSLog(@"Values have not been set.");
        return NULL;
    }
    else
    {
        return self->short_t;
    }
}
- (short*) getShortValuesWithCount: (unsigned int*) n
{
    if (!self->short_t)
    {
        NSLog(@"Values have not been set.");
        return NULL;
    }
    else
    {
        *n = 10;
        return self->short_t;
    }
}


// long[10] array
- (void) setLongValues: (long[10]) val_arr
{
    NSLog(@"Setting long array values...");
    memcpy(self->long_t, val_arr, sizeof(long) * 10);
    NSLog(@"Values copied...");
}
- (long*) getLongValues
{
    if (!self->long_t)
    {
        NSLog(@"Values have not been set.");
        return NULL;
    }
    else
    {
        return self->long_t;
    }
}
- (long*) getLongValuesWithCount: (unsigned int*) n
{
    if (!self->long_t)
    {
        NSLog(@"Values have not been set.");
        return NULL;
    }
    else
    {
        *n = 10;
        return self->long_t;
    }
}


// long long[10] array
- (void) setLongLongValues: (long long[10]) val_arr
{
    NSLog(@"Setting long long array values...");
    memcpy(self->longlong_t, val_arr, sizeof(long long) * 10);
    NSLog(@"Values copied...");

}
- (long long*) getLongLongValues
{
    if (!self->longlong_t)
    {
        NSLog(@"Values have not been set for long long array.");
        return NULL;
    }
    else
    {
        return self->longlong_t;
    }
}
- (long long*) getLongLongValuesWithCount: (unsigned int*) n
{
    if (!self->longlong_t)
    {
        NSLog(@"Values have not been set for long long array.");
        return NULL;
    }
    else
    {
        *n = 10;
        return self->longlong_t;
    }
}


// float[10] array
- (void) setFloatValues: (float[10]) val_arr
{
    NSLog(@"Setting float array values...");
    memcpy(self->float_t, val_arr, sizeof(float) * 10);
    NSLog(@"Values copied...");
}
- (float*) getFloatValues
{
    if (!self->float_t)
    {
        NSLog(@"Values have not been set for float array.");
        return NULL;
    }
    else
    {
        return self->float_t;
    }
}
- (float*) getFloatValuesWithCount: (unsigned int*) n
{
    if (!self->float_t)
    {
        NSLog(@"Values have not been set for float array.");
        return NULL;
    }
    else
    {
        *n = 10;
        return self->float_t;
    }
}


// double[10] array
- (void) setDoubleValues: (double[10]) val_arr
{
    NSLog(@"Setting double array values...");
    memcpy(self->double_t, val_arr, sizeof(double) * 10);
    NSLog(@"Values copied...");
}
- (double*) getDoubleValues
{
    if (!self->double_t)
    {
        NSLog(@"Values have not been set for double array.");
        return NULL;
    }
    else
    {
        return self->double_t;
    }
}
- (double*) getDoubleValuesWithCount: (unsigned int*) n
{
    if (!self->double_t)
    {
        NSLog(@"Values have not been set for double array.");
        return NULL;
    }
    else
    {
        *n = 10;
        return self->double_t;
    }
}


// unsigned int[10] array
- (void) setUIntValues: (unsigned int[10]) val_arr
{
    NSLog(@"Setting unsigned int array values...");
    memcpy(self->uint_t, val_arr, sizeof(unsigned int) * 10);
    NSLog(@"Values copied...");
}
- (unsigned int*) getUIntValues
{
    if (!self->uint_t)
    {
        NSLog(@"Values have not been set for unsigned int array.");
        return NULL;
    }
    else
    {
        return self->uint_t;
    }
}
- (unsigned int*) getUIntValuesWithCount: (unsigned int*) n
{
    if (!self->uint_t)
    {
        NSLog(@"Values have not been set for unsigned int array.");
        return NULL;
    }
    else
    {
        *n = 10;
        return self->uint_t;
    }
}


// unsigned short[10] array
- (void) setUShortValues: (unsigned short[10]) val_arr
{
    NSLog(@"Setting unsigned short array values...");
    memcpy(self->ushort_t, val_arr, sizeof(unsigned short) * 10);
    NSLog(@"Values copied...");
}
- (unsigned short*) getUShortValues
{
    if (!self->ushort_t)
    {
        NSLog(@"Values have not been set for unsigned short array.");
        return NULL;
    }
    else
    {
        return self->ushort_t;
    }
}
- (unsigned short*) getUShortValuesWithCount: (unsigned int*) n
{
    if (!self->ushort_t)
    {
        NSLog(@"Values have not been set for unsigned short array.");
        return NULL;
    }
    else
    {
        *n = 10;
        return self->ushort_t;
    }
}


// unsigned long[10] array
- (void) setULongValues: (unsigned long[10]) val_arr
{
    NSLog(@"Setting unsigned short array values...");
    memcpy(self->ulong_t, val_arr, sizeof(unsigned long) * 10);
    NSLog(@"Values copied...");
}
- (unsigned long*) getULongValues
{
    if (!self->ulong_t)
    {
        NSLog(@"Values have not been set for unsigned long array.");
        return NULL;
    }
    else
    {
        return self->ulong_t;
    }
}
- (unsigned long*) getULongValuesWithCount: (unsigned int*) n
{
    if (!self->ulong_t)
    {
        NSLog(@"Values have not been set for unsigned long array.");
        return NULL;
    }
    else
    {
        *n = 10;
        return self->ulong_t;
    }
}


// unsigned long long[10] array
- (void) setULongLongValues: (unsigned long long[10]) val_arr
{
    NSLog(@"Setting unsigned short array values...");
    memcpy(self->ulonglong_t, val_arr, sizeof(unsigned long long) * 10);
    NSLog(@"Values copied...");
}
- (unsigned long long*) getULongLongValues
{
    if(!self->ulonglong_t)
    {
        NSLog(@"Values have not been set for unsigned long long array.");
        return NULL;
    }
    else
    {
        return self->ulonglong_t;
    }
}
- (unsigned long long*) getULongLongValuesWithCount: (unsigned int*) n
{
    if(!self->ulonglong_t)
    {
        NSLog(@"Values have not been set for unsigned long long array.");
        return NULL;
    }
    else
    {
        *n = 10;
        return self->ulonglong_t;
    }
}


// unsigned char[10] array
- (void) setUCharValues: (unsigned char[10]) val_arr
{
    NSLog(@"Setting unsigned short array values...");
    memcpy(self->uchar_t, val_arr, sizeof(unsigned char) * 10);
    NSLog(@"Values copied...");
}
- (unsigned char*) getUCharValues
{
    if (!self->uchar_t)
    {
        NSLog(@"Values have not been set for unsigned char array.");
        return NULL;
    }
    else
    {
        return self->uchar_t;
    }
}
- (unsigned char*) getUCharValuesWithCount: (unsigned int*) n
{
    if (!self->uchar_t)
    {
        NSLog(@"Values have not been set for unsigned char array.");
        return NULL;
    }
    else
    {
        *n = 10;
        return self->uchar_t;
    }
}


// unsigned bool[10] array
- (void) setBoolValues: (bool[10]) val_arr
{
    NSLog(@"Setting unsigned short array values...");
    memcpy(self->bool_t, val_arr, sizeof(bool) * 10);
    NSLog(@"Values copied...");
}
- (bool*) getBoolValues
{
    if (!self->bool_t)
    {
        NSLog(@"Values have not been set for bool array.");
        return NULL;
    }
    else
    {
        return self->bool_t;
    }
}
- (bool*) getBoolValuesWithCount: (unsigned int*) n
{
    if (!self->bool_t)
    {
        NSLog(@"Values have not been set for bool array.");
        return NULL;
    }
    else
    {
        *n = 10;
        return self->bool_t;
    }
}

// CharPtr array
- (void) setCharPtrValues: (char*[10]) val_arr
{
    NSLog(@"Setting char ptr array values...");
    memcpy(self->char_ptr_arr, val_arr, sizeof(char*) * 10);
    NSLog(@"Value copied...");
}
- (char**) getCharPtrValues
{
    if (!self->char_ptr_arr)
    {
        NSLog(@"Values have not been set for char ptr array.");
        return NULL;
    }
    else
    {
        return self->char_ptr_arr;
    }
}
- (char**) getCharPtrValuesWithCount: (unsigned int*) n
{
    if (!self->char_ptr_arr)
    {
        NSLog(@"Values have not been set for char ptr array.");
        return NULL;
    }
    else
    {
        *n = 10;
        return self->char_ptr_arr;
    }
}


// NSNumber array for [10@] signature
- (void) setNSNumberValues: (NSNumber *__unsafe_unretained[10]) val_arr
{
    NSLog(@"Setting NSNumber array values...");
    memcpy(self->ns_number_arr, val_arr, sizeof(NSNumber*) * 10);
    NSLog(@"Values copied...");
}
- (NSNumber *__unsafe_unretained*) getNSNumberValues
{
    if (!self->ns_number_arr)
    {
        NSLog(@"Values have not been set for NSNumber array.");
        return NULL;
    }
    else
    {
        return self->ns_number_arr;
    }
}
- (NSNumber *__unsafe_unretained*) getNSNumberValuesWithCount: (unsigned int*) n
{
    if (!self->ns_number_arr)
    {
        NSLog(@"Values have not been set for NSNumber array.");
        return NULL;
    }
    else
    {
        *n = 10;
        return self->ns_number_arr;
    }
}


// Class array for [10#] signature
- (void) setClassValues: (Class __unsafe_unretained[10]) val_arr
{
    NSLog(@"Setting Class[10] array values...");
    memcpy(self->class_arr, val_arr, sizeof(Class) * 10);
    NSLog(@"Values copied...");
}
- (Class*) getClassValues
{
    if (!self->class_arr)
    {
        NSLog(@"Values have not been set for Class array.");
        return NULL;
    }
    else
    {
        return self->class_arr;
    }
}
- (Class*) getClassValuesWithCount: (unsigned int*) n
{
    if (!self->class_arr)
    {
        NSLog(@"Values have not been set for Class array.");
        return NULL;
    }
    else
    {
        *n = 10;
        return self->class_arr;
    }
}


// SEL array for [10:] signature
- (void) printSelector
{
    NSLog(@"printSelector");
}
- (void) setSELValues: (SEL[10]) val_arr
{
    NSLog(@"Setting SEL[10] array values...");
    memcpy(self->sel_arr, val_arr, sizeof(SEL) * 10);
    NSLog(@"Values copied...");
}
- (SEL*) getSELValues
{
    if (!self->sel_arr)
    {
        NSLog(@"Values have not been set for SEL array.");
        return NULL;
    }
    else
    {
        return self->sel_arr;
    }
}
- (SEL*) getSELValuesWithCount: (unsigned int*) n
{
    if (!self->sel_arr)
    {
        NSLog(@"Values have not been set for SEL array.");
        return NULL;
    }
    else
    {
        *n = 10;
        return self->sel_arr;
    }
}

// 2D int array for recursion test
- (void) set2DIntValues: (int[10][10]) val_arr
{
    NSLog(@"Setting 2D int array values...");
    memcpy(self->int_2d_arr, val_arr, sizeof(int) * 10 * 10);
    NSLog(@"Values copied...");
}
- (int*) get2DIntValues
{
    if (!self->int_2d_arr)
    {
        NSLog(@"Values have not been set for int 2d array.");
        return NULL;
    }
    else
    {
        return (int*)self->int_2d_arr;
    }
}
- (int*) get2DIntValuesWithCount: (unsigned int*) n :(unsigned int*) m
{
    if (!self->int_2d_arr)
    {
        NSLog(@"Values have not been set for int 2d array.");
        return NULL;
    }
    else
    {
        *n = 10;
        *m = 10;
        return (int*)self->int_2d_arr;
    }
}

// struct foobar array
- (bar) initFooBarStruct: (int) a :(float) b
{
    bar tmp;
    tmp.a = a;
    tmp.b = b;
    return tmp;
}
- (void) setFooBarValues: (bar[10]) val_arr
{
    NSLog(@"Setting foobar array values...");
    memcpy(self->foobar_arr, val_arr, sizeof(bar) * 10);
    NSLog(@"Values copied...");
}
- (bar*) getFooBarValues
{
    if (!self->foobar_arr)
    {
        NSLog(@"Values have not been set for foobar array");
        return NULL;
    }
    else
    {
        return self->foobar_arr;
    }
}
- (bar*) getFooBarValuesWithCount: (unsigned int*) n
{
    if (!self->foobar_arr)
    {
        NSLog(@"Values have not been set for foobar array");
        return NULL;
    }
    else
    {
        *n = 10;
        return self->foobar_arr;
    }
}

@end
