//
//  TDLocationManager.h
//  TritonPlayerSDK
//
//  Created by Carlos Pereira on 2014-12-04.
//  Copyright (c) 2014 Triton Digital. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface TDLocationManager : NSObject

@property (nonatomic, strong) CLLocation *targetingLocation;

+(instancetype)sharedManager;
- (void) startLocation;
- (void) stopLocation;

@end
