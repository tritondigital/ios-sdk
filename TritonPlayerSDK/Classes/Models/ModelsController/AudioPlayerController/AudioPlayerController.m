//
//  AudioPlayerController.m
//  FLVStreamPlayerLib
//
//  Created by Thierry Bucco on 09-04-23.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//

#import "AudioPlayerController.h"
#import "AudioPlayer.h"
#import "FLVAudioTag.h"
#import "FLVAudioTagData.h"
#import "Logs.h"

@implementation AudioPlayerController

@synthesize audioPlayer;
@synthesize operationInProgress;
@synthesize isExecuting;
@synthesize lowDelay;


//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// initWithDelegate
/// PUBLIC API - called by TDFLVPlayer's initWithSettings: method on the TritonPlayer thread
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (id)initWithDelegate:(id)inDelegate
{	
	self = [super init];
	if (self)
	{
		// Add operations to a operation queue
		audioPlayerDelegate = inDelegate;
	}
	return self;
}


// Should be called ONLY when we are about to release this object. This method will stop the audio player thread and
// release the audioPlayer so that ARC can correctly get rid of this object; once we return this object will be unusable.
// Note that changing sub-objects to correctly use weak references for their delegates would probably be a better
// solution, but for the sake of expediency this approach will be used for now.
-(void)willBeDeleted
{
	[audioPlayer cancel];

	while (self.isExecuting == YES)
	{
		usleep(100);
	}

	audioPlayer = nil;
}


//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// dealloc
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=


//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// start
/// Called by FLVStream's connection:didReceiveResponse: handler. This runs on the TritonPlayer thread, since it's
/// the active thread when we call the FLVStream object's start method, where the NSURLConnection is opened.
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)start
{
	@synchronized(self)
	{
		self.operationInProgress = TRUE;
		
		self.audioPlayer = [[AudioPlayer alloc] init];
		
		[audioPlayer setDelegate:audioPlayerDelegate];
		[audioPlayer setIsExecutingDelegate:self];

        PLAYER_LOG(@"AudioPlayerController->play");
        audioPlayer.lowDelay = self.lowDelay;
        audioPlayer.bitrate = self.bitrate;
		[audioPlayer start];
	}
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// addAudioTag
/// PUBLIC API - called by the FLVDispatcher's dispatchNewTag: method on the TritonPlayer thread
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)addAudioTag:(FLVAudioTag *)inTag
{
	if (inTag && inTag.audioTagData)
	{
		@synchronized(self)
		{
			[audioPlayer parseAndPlayData:inTag.audioTagData.audioData];
		}
	}
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// stop
/// PUBLIC API - called by the FLVStream's closeConnection method, on an NSOperationQueue's thread
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)stop
{
	@synchronized(self)
	{
        PLAYER_LOG(@"AudioPlayerController->stop");
		
		self.operationInProgress = TRUE;
		[audioPlayer cancel];
	}
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// getAudioQueue
/// PUBLIC API 
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (AudioQueueRef)getAudioQueue
{
	@synchronized(self)
	{
		return [audioPlayer getAudioQueue];
	}
}


/// PUBLIC API - called by the FLVDispatcher's dispatchNewTag: method on the TritonPlayer thread
- (void)setbitrate:(UInt32)aBitrate
{
    audioPlayer.bitrate = aBitrate;
    self.bitrate = aBitrate;
}

/// PUBLIC API - called by the FLVPlayer on the TritonPlayer thread
-(void)setlowDelay:(SInt32)aLowDelay;
{
	self.lowDelay = (aLowDelay > 60) ? 60 : (aLowDelay < 0) ? -1 : aLowDelay;
}


#pragma mark - Notification

/// PUBLIC API - callback from AudioPlayer on the TritonPlayer-AudioPlayer thread (during either startup or cleanup)
- (void)isExecutingNotificationReceived:(BOOL)value
{
	@synchronized(self)
	{
		BOOL audioPlayerisExecuting = value;
		
        FLOG(@"isExecuting : %d",audioPlayerisExecuting);
		
		if (audioPlayerisExecuting == NO)
		{
			FLOG(@"self.isExecuting = NO");
			
			self.isExecuting = FALSE;
			[audioPlayerDelegate isExecutingNotificationReceived:NO]; // streamController
			
            FLOG(@"Release audioPlayer");

			[audioPlayer setDelegate:nil];
			audioPlayer = nil;
		}
		else
		{
            FLOG(@"self.isExecuting = YES");
						
			self.isExecuting = YES;
			[audioPlayerDelegate isExecutingNotificationReceived:YES]; // streamController
		}
		
		self.operationInProgress = FALSE;
    }
}

@end
