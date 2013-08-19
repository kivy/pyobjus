#import "CArrayTestlib.h"

@implementation CArrayTestlib
{
    int values[10];
}

- (id) init
{
    self = [super init];
    if (self)
    { }
    
    NSLog(@"Constructing object.");
    return self;
}


- (void) setIntValues:(int[10])val_arr
{
    NSLog(@"Setting values...");
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



@end
