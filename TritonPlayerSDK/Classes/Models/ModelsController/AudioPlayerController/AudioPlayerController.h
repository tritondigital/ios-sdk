//
//  AudioPlayerController.h
//  FLVStreamPlayerLib
//
//  Created by Thierry Bucco on 09-04-23.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioQueue.h>
#import <AudioToolbox/AudioFileStream.h>

@class AudioPlayer;
@class FLVAudioTag;

@interface AudioPlayerController : NSObject 
{
	AudioPlayer			*audioPlayer;
	BOOL				active;
	id					audioPlayerDelegate;
	
	BOOL				operationInProgress;
	BOOL				isExecuting;
    SInt32              lowDelay;
}

@property (nonatomic,strong) AudioPlayer *audioPlayer;
@property BOOL operationInProgress;
@property BOOL isExecuting;
@property SInt32 lowDelay;
@property UInt32 bitrate;

- (id)initWithDelegate:(id)inDelegate;

- (void)willBeDeleted;

- (void)start;
- (void)addAudioTag:(FLVAudioTag *)inTag;
- (void)stop;
- (void)isExecutingNotificationReceived:(BOOL)value;
- (AudioQueueRef)getAudioQueue;
- (void)setbitrate:(UInt32)bitrate;
- (void)setlowDelay:(SInt32)lowDelay;

@end
