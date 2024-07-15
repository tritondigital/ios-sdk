//
//  TDMediaPlaybackDelegate.h
//  TritonPlayerSDK
//
//  Created by Carlos Pereira on 2015-03-26.
//  Copyright (c) 2015 Triton Digital. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TritonPlayer.h"
#import "CuePointEvent.h"

@protocol TDMediaPlayback;

@protocol TDMediaPlaybackDelegate <NSObject>

-(void)mediaPlayer:(id<TDMediaPlayback>)player didChangeState:(TDPlayerState)newState;
-(void)mediaPlayer:(id<TDMediaPlayback>)player didReceiveCuepointEvent:(CuePointEvent *)cuePointEvent;
-(void)mediaPlayer:(id<TDMediaPlayback>)player didReceiveAnalyticsEvent:(AVPlayerItemAccessLogEvent *)event;
-(void)mediaPlayer:(id<TDMediaPlayback>)player didReceiveCloudStreamInfoEvent:(NSDictionary *)cloudStreamInfoEvent;
@optional

-(void)mediaPlayer:(id<TDMediaPlayback>)player didReceiveInfo:(TDPlayerInfo)info andExtra:(NSDictionary *)extra;
-(void)mediaPlayer:(id<TDMediaPlayback>)player didReceiveMetaData:(NSDictionary *)metaData;
-(void)mediaPlayer:(id<TDMediaPlayback>)player didPlayBuffer:(AudioBufferList *)buffer;
@end
