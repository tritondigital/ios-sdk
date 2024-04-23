//
//  TDMediaPlayer.h
//  Triton iOS SDK
//
//  Copyright (c) 2015 Triton Digital. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TDMediaPlayback.h"

extern NSString *const SettingsMediaPlayerUserAgentKey;
extern NSString *const SettingsMediaPlayerSBMURLKey;
extern NSString *const SettingsMediaPlayerStreamURLKey;

@class CuePointEvent;
@class TDMediaPlayer;

@interface TDMediaPlayer : NSObject<TDMediaPlayback>

-(instancetype)initWithSettings:(NSDictionary *)settings;

-(void)updateSettings:(NSDictionary *)settings;

-(void)play;
-(void)stop;
-(void)pause;
-(void)mute;
-(void)unmute;
-(void)setVolume:(float)volume;
-(void)changePlaybackRate:(float)rate;

@end
