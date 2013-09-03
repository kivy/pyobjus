#import "bridge.h"

@implementation bridge

static const NSTimeInterval accelerometerMin = 0.01;

- (void)startAccel {
    
    self.motionManager = [[CMMotionManager alloc] init];
    self.motionManager.accelerometerUpdateInterval = .2;
    self.motionManager.gyroUpdateInterval = .2;
    
    if ([self.motionManager isAccelerometerAvailable] == YES) {
        [self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
            printf("x: %f\n", accelerometerData.acceleration.x);
            printf("y: %f\n", accelerometerData.acceleration.y);
            printf("z: %f\n", accelerometerData.acceleration.z);
        }];
    }
}

- (void) stopAccel {
    [self.motionManager stopAccelerometerUpdates];
}


@end
