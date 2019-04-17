//
//  TDAnalyticsTracker.h
//  TritonPlayerSDK
//
//  Created by Mahamadou KABORE on 2016-04-26.
//  Copyright © 2016 Triton Digital. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface TDAnalyticsTracker : NSObject


+(instancetype)sharedTracker;
+(instancetype)sharedTracker:(BOOL) isTritonApp;
-(void) initialize;
-(void) addType:(NSString*) type;
-(NSTimeInterval) stopTimer;
-(void) startTimer;


//Streaming Connection
-(void) trackStreamingConnectionSuccessWithMount:(NSString*) mount withBroadcaster:(NSString*) broadcaster withLoadTime: (NSTimeInterval) loadTime;
-(void) trackStreamingConnectionUnavailableWithMount:(NSString*) mount withBroadcaster:(NSString*) broadcaster withLoadTime: (NSTimeInterval) loadTime;
-(void) trackStreamingConnectionErrorWithMount:(NSString*) mount withBroadcaster:(NSString*) broadcaster withLoadTime: (NSTimeInterval) loadTime;
-(void) trackStreamingConnectionGeoblockedWithMount:(NSString*) mount withBroadcaster:(NSString*) broadcaster withLoadTime: (NSTimeInterval) loadTime;
-(void) trackStreamingConnectionFailedWithMount:(NSString*) mount withBroadcaster:(NSString*) broadcaster withLoadTime: (NSTimeInterval) loadTime;

//Ad Preroll
-(void) trackAdPrerollSuccessWithFormat:(NSString*) adFormat isVideo:(BOOL) isvideo withLoadTime: (NSTimeInterval) loadTime;
-(void) trackAdPrerollErrorWithFormat:(NSString*) adFormat isVideo:(BOOL) isvideo withLoadTime: (NSTimeInterval) loadTime;

//On demand
-(void) trackOnDemandSuccess;
-(void) trackOnDemandError;
@end