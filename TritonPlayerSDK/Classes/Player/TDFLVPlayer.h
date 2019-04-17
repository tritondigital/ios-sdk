//
//  TDFLVPlayer.h
//  TritonPlayerSDK
//
//  Created by Carlos Pereira on 2015-03-11.
//  Copyright (c) 2015 Triton Digital. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TDMediaPlayback.h"
#import "TDMediaPlaybackDelegate.h"
#import "FLVDispatcher.h"

extern NSString *const SettingsFLVPlayerUserAgentKey;
extern NSString *const SettingsFLVPlayerStreamURLKey;
extern NSString *const SettingsFLVPlayerReferrerURLKey;
extern NSString *const SettingsFLVPlayerSecIdKey;

@class FLVTag;

@interface TDFLVPlayer : NSObject<TDMediaPlayback,TDFLVMetaDataDelegate>

@property (assign, nonatomic) BOOL isExecuting;

-(instancetype)initWithSettings:(NSDictionary *)settings;

-(void)updateSettings:(NSDictionary *)settings;

-(void)willBeDeleted;

-(void)play;

-(void)stop;

-(void)cancelBackgoundTasks;
-(void)setStreamHeader:(NSData *)headerData;
-(void)sendTagToDispatcher:(FLVTag *)inTag;
@end
