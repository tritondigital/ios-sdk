//
//  TDMediaPlayback.h
//  TritonPlayerSDK
//
//  Copyright (c) 2015 Triton Digital. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CMTime.h>

#import "TDMediaPlaybackDelegate.h"

@protocol TDMediaPlayback <NSObject>

@property (readonly, assign) NSTimeInterval currentPlaybackTime;
@property (readonly, assign) NSTimeInterval playbackDuration;

-(void)play;

-(void)stop;

@optional

@property (nonatomic, weak) id<TDMediaPlaybackDelegate> delegate;
@property (nonatomic, strong) NSError *error;

-(void)updateSettings:(NSDictionary *)settings;

-(void)pause;

-(void)mute;

-(void)unmute;

-(void)setVolume:(float)volume;

-(void)seekToTimeInterval:(NSTimeInterval) interval;
-(void)seekToTime:(CMTime)time completionHandler:(void (^)(BOOL finished))completionHandler;

-(AudioQueueRef)getAudioQueue;

@required
-(id)addPeriodicTimeObserverForInterval:(CMTime)interval queue:(dispatch_queue_t)queue usingBlock:(void (^)(CMTime time))block;
-(void)removeTimeObserver:(id)observer;

@end
