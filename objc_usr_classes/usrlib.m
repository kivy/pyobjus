#import <Foundation/Foundation.h>

@interface Car : NSObject {
}

- (void)drive;
- (void)driveWithCar:(int*)car_id;

@end

@implementation Car

- (void)drive {
    NSLog(@"Driving! Vrooooom!");
}

- (void)driveWithCar:(int*)car_id {
    printf("I'm driving car with id: %d", *car_id);
}

@end

int main() {
    Car *c = [[Car alloc] init];
    [c drive];
}

