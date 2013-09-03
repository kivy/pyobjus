#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
#import <UIKit/UIKit.h>

@interface bridge : NSObject

@property (strong, nonatomic) CMMotionManager *motionManager;

@end
