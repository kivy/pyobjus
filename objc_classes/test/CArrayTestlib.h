#import <Foundation/Foundation.h>

struct foo
{
    int a;
    float b;
};
typedef struct foo bar;


@interface CArrayTestlib : NSObject

- (void) setIntValues: (int[10]) val_arr;
- (int*) getIntValues;
- (void) printIntValues;
- (int*) getIntValuesWithCount: (unsigned int*) n;

- (void) setCharValues: (char[10]) val_arr;
- (char*) getCharValues;
- (char*) getCharValuesWithCount: (unsigned int*) n;

- (void) setShortValues: (short[10]) val_arr;
- (short*) getShortValues;
- (short*) getShortValuesWithCount: (unsigned int*) n;

- (void) setLongValues: (long[10]) val_arr;
- (long*) getLongValues;
- (long*) getLongValuesWithCount: (unsigned int*) n;

- (void) setLongLongValues: (long long[10]) val_arr;
- (long long*) getLongLongValues;
- (long long*) getLongLongValuesWithCount: (unsigned int*) n;

- (void) setFloatValues: (float[10]) val_arr;
- (float*) getFloatValues;
- (float*) getFloatValuesWithCount: (unsigned int*) n;

- (void) setDoubleValues: (double[10]) val_arr;
- (double*) getDoubleValues;
- (double*) getDoubleValuesWithCount: (unsigned int*) n;

- (void) setUIntValues: (unsigned int[10]) val_arr;
- (unsigned int*) getUIntValues;
- (unsigned int*) getUIntValuesWithCount: (unsigned int*) n;

- (void) setUShortValues: (unsigned short[10]) val_arr;
- (unsigned short*) getUShortValues;
- (unsigned short*) getUShortValuesWithCount: (unsigned int*) n;

- (void) setULongValues: (unsigned long[10]) val_arr;
- (unsigned long*) getULongValues;
- (unsigned long*) getULongValuesWithCount: (unsigned int*) n;

- (void) setULongLongValues: (unsigned long long[10]) val_arr;
- (unsigned long long*) getULongLongValues;
- (unsigned long long*) getULongLongValuesWithCount: (unsigned int*) n;

- (void) setUCharValues: (unsigned char[10]) val_arr;
- (unsigned char*) getUCharValues;
- (unsigned char*) getUCharValuesWithCount: (unsigned int*) n;

- (void) setBoolValues: (bool[10]) val_arr;
- (bool*) getBoolValues;
- (bool*) getBoolValuesWithCount: (unsigned int*) n;

- (void) setCharPtrValues: (char*[10]) val_arr;
- (char**) getCharPtrValues;
- (char**) getCharPtrValuesWithCount: (unsigned int*) n;

- (void) setNSNumberValues: (NSNumber *__unsafe_unretained[10]) val_arr;
- (NSNumber *__unsafe_unretained*) getNSNumberValues;
- (NSNumber *__unsafe_unretained*) getNSNumberValuesWithCount: (unsigned int*) n;

- (void) setClassValues: (Class __unsafe_unretained[10]) val_arr;
- (Class*) getClassValues;
- (Class*) getClassValuesWithCount: (unsigned int*) n;

- (void) printSelector;
- (void) setSELValues: (SEL[10]) val_arr;
- (SEL*) getSELValues;
- (SEL*) getSELValuesWithCount: (unsigned int*) n;

- (void) set2DIntValues: (int[10][10]) val_arr;
- (int*) get2DIntValues;
- (int*) get2DIntValuesWithCount: (unsigned int*) n :(unsigned int*) m;

- (bar) initFooBarStruct: (int) a :(float) b;
- (void) setFooBarValues: (bar[10]) val_arr;
- (bar*) getFooBarValues;
- (bar*) getFooBarValuesWithCount: (unsigned int*) n;
@end
