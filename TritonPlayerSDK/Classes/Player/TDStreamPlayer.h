//
//  TDStreamPlayer.h
//  TritonPlayerSDK
//
//  Created by Carlos Pereira on 2015-03-12.
//  Copyright (c) 2015 Triton Digital. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TDMediaPlayback.h"

extern NSString *const SettingsStreamPlayerProfileKey;
extern NSString *const SettingsStreamPlayerUserAgentKey;
extern NSString *const SettingsStreamPlayerStreamURLKey;
extern NSString *const SettingsStreamPlayerTimeshiftStreamURLKey;
extern NSString *const SettingsStreamPlayerSBMURLKey;

@class TDPlayerSettings;

typedef NS_ENUM(NSInteger, TDStreamProfile) {
    kTDStreamProfileFLV,
    KTDStreamProfileHLS,
    KTDStreamProfileOther,
    KTDStreamProfileHLSTimeshift
};

@interface TDStreamPlayer : NSObject<TDMediaPlayback>

-(instancetype)initWithSettings:(NSDictionary *)settings;

-(void)updateSettings:(NSDictionary *)settings;

-(void)cancelBackgoundTasks;

-(NSString*) getStreamingUrl;

@end
