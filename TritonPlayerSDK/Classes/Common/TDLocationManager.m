//
//  TDLocationManager.m
//  TritonPlayerSDK
//
//  Created by Carlos Pereira on 2014-12-04.
//  Copyright (c) 2014 Triton Digital. All rights reserved.
//

#import "TDLocationManager.h"
#import "TritonPlayerConstants.h"

@interface TDLocationManager ()<CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) NSTimer *locationTimer;
@property (nonatomic, assign) BOOL initializationDone;
@end

@implementation TDLocationManager

+(instancetype)sharedManager {
    static TDLocationManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

-(instancetype)init {
    self = [super init];
    if (self) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
        _locationManager.distanceFilter = 1;
        _initializationDone = NO;
    }
    return self;
}

- (void) startLocation {
    
    if(!_initializationDone)
    {
     _locationManager.delegate = self;
     // Check for iOS 8. Without this guard the code will crash with "unknown selector" on iOS 7.
     if ([[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationWhenInUseUsageDescription"] || [[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationAlwaysUsageDescription"]) {
        if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
            [self.locationManager requestWhenInUseAuthorization];
        }
        
     } else {
        NSLog(@"Info.plist does not contain NSLocationAlwaysUsageDescription or NSLocationWhenInUseUsageDescription");
     }
        _initializationDone= YES;
   }
    
    [self stopLocation];
    
    self.locationTimer = [NSTimer scheduledTimerWithTimeInterval:kLocationUpdateInterval target:self selector:@selector(timerFired) userInfo:nil repeats:YES];
    [self.locationTimer fire];
}

- (void) stopLocation {
    if(self.locationTimer != nil)
    {
     [self.locationTimer invalidate];
     self.locationTimer = nil;
    }
}

- (void) timerFired {
    if ([self canLocate]) {
        [self.locationManager startUpdatingLocation];
        
    } else {
        [self stopLocation];
    }
}

- (BOOL)canLocate {
    return (([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized) ||
            ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) ||
            ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways) ||
            ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined));
}

#pragma mark - CLLocationManager delegates

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    [self.locationManager stopUpdatingLocation];
    
    self.targetingLocation = [locations lastObject];
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    [self.locationManager stopUpdatingLocation];
}

-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if ([self canLocate]) {
        [self startLocation];
        
    } else {
        [self stopLocation];
    }
}
@end
