//
//  TDFLVPlayer.m
//  TritonPlayerSDK
//
//  Created by Carlos Pereira on 2015-03-11.
//  Original version by Thierry Bucco in 2009
//
//  Copyright (c) 2015 Triton Digital. All rights reserved.
//

#import "TDFLVPlayer.h"
#import "FLVStream.h"
#import "FLVDecoder.h"
#import "FLVHeader.h"
#import "AudioPlayerController.h"
#import "CuePointEventController.h"
#import "AudioPlayer.h"
#import "TritonPlayerConstants.h"

#import "Logs.h"

NSString *const SettingsFLVPlayerUserAgentKey = @"FLVPlayerUserAgent";
NSString *const SettingsFLVPlayerStreamURLKey = @"FLVPlayerStreamURL";
NSString *const SettingsFLVPlayerReferrerURLKey = @"FLVPlayerReferrerURL";
NSString *const SettingsFLVPlayerSecIdKey = @"FLVPlayerSecId";

static UInt32 bufferTime = kLowDelaySecondsStart+1;

@interface TDFLVPlayer ()

@property (copy, nonatomic) NSString *userAgent;
@property (copy, nonatomic) NSString *streamURL;

// Content protection
@property (copy, nonatomic) NSString *secId;
@property (copy, nonatomic) NSString *secReferrerURL;

@property (strong, nonatomic) FLVStream *flvStream;
@property (strong, nonatomic) FLVDispatcher *flvDispather;
@property (strong, nonatomic) FLVDecoder *flvDecoder;
@property (strong, nonatomic) AudioPlayerController	*audioPlayerController;
@property (strong, nonatomic) CuePointEventController *cuePointEventController;

@property (assign, nonatomic) BOOL streamStoppedNotificationAlreadySent;
@property (assign, nonatomic) SInt32 lowDelay;
@property (assign, nonatomic) SInt32 bitrate;

@property (nonatomic, copy) NSDictionary* dmpSegments;

@property (assign, nonatomic) TDPlayerState state;

@end

@implementation TDFLVPlayer

@synthesize currentPlaybackTime;
@synthesize latestPlaybackTime;
@synthesize playbackDuration;
@synthesize delegate;
@synthesize error = _error;

-(instancetype)init {
    return [self initWithSettings:nil];
}

-(instancetype)initWithSettings:(NSDictionary *)settings {
    self = [super init];
    if (self) {
        [self updateSettings:settings];
        
        self.cuePointEventController = [[CuePointEventController alloc] initWithDelegate:self];
        self.audioPlayerController = [[AudioPlayerController alloc] initWithDelegate:self]; // for buffering notification
        self.flvStream = [[FLVStream alloc] initWithDelegate:self andAudioPlayerController:self.audioPlayerController secID:self.secId secReferrerURL:self.secReferrerURL lowDelay:self.lowDelay];
    
        self.flvDispather = [[FLVDispatcher alloc] initWithCuePointEventController:self.cuePointEventController andAudioPlayerController:self.audioPlayerController];
        [self.flvDispather setTDFLVMetaDataDelegate:self];
				
        self.flvDecoder = [[FLVDecoder alloc] initWithStreamController:self];
        self.flvStream.flvDecoder = self.flvDecoder;
        
        [self.audioPlayerController setlowDelay:self.lowDelay];
        [self.audioPlayerController setbitrate:self.bitrate];
        
        self.state = kTDPlayerStateStopped;
    }
    return self;
}

-(void)updateSettings:(NSDictionary *)settings {
    if(settings)
    {
        self.userAgent = settings[SettingsFLVPlayerUserAgentKey];
        self.streamURL = settings[SettingsFLVPlayerStreamURLKey];
        self.secId = settings[SettingsFLVPlayerSecIdKey];
        self.secReferrerURL = settings[SettingsFLVPlayerReferrerURLKey];
        self.lowDelay = [settings[SettingsLowDelayKey] intValue];
        self.bitrate = [settings[SettingsBitrateKey] intValue];
        self.dmpSegments = settings[SettingsDmpHeadersKey];
    }
}


// Should be called ONLY when we are about to release this object. This method will release all private sub-objects
// so that ARC can correctly get rid of this object, so once we return this object will be unusable.
// Note that changing all sub-objects to correctly use weak references for their delegates would probably be a better
// solution, but for the sake of expediency this approach will be used for now.
-(void)willBeDeleted
{
	// This object has its own sub-objects plus runs a thread, so clean it up first
	[self.audioPlayerController willBeDeleted];
	
	self.flvDecoder = nil;
	self.flvDispather = nil;
	self.flvStream = nil;
	self.audioPlayerController = nil;
	self.cuePointEventController = nil;
}


-(void)play {
    if ([self canChangeStateWithAction:kTDPlayerActionPlay]) {
        [self updateStateMachineForAction:kTDPlayerActionPlay];
        [self.flvStream setDmpSegments:self.dmpSegments];
        [self.flvStream setUserAgent:self.userAgent];
        if ( self.lowDelay > 0 || self.lowDelay == -1 )
        {
            if ( self.lowDelay > 0 )
                bufferTime = self.lowDelay + 1;
            
            NSArray *lines = [self.streamURL componentsSeparatedByString: @"\?"];
            NSString *newUrl = [NSString stringWithFormat:@"%@?burst-time=%u&%@", lines[0], (unsigned int)bufferTime, lines[1]];
            NSLog(@"%@",newUrl);
            [self.flvStream setStreamURL:newUrl];
        }
        else
        {
            [self.flvStream setStreamURL:self.streamURL];
        }
        
        [self.flvStream start];
       
    }
}

-(void)stop {
        [self updateStateMachineForAction:kTDPlayerActionStop];
        [self.flvStream stop];
}

-(void)seekToTimeInterval:(NSTimeInterval)interval {
}

-(void)mute {
    [self.audioPlayerController.audioPlayer mute];
}

-(void)unmute {
    [self.audioPlayerController.audioPlayer unmute];
}

-(void)setVolume:(float)volume {
    if(self.audioPlayerController)
    {
     [self.audioPlayerController.audioPlayer setVolume:volume];
    }
}

-(void)sendTagToDispatcher:(FLVTag *)inTag {
    if(self.flvDispather && inTag)
    {
        @try{
     [self.flvDispather dispatchNewTag:inTag];
        }@catch (NSException * e)
        {
            FLOG(@"Exception : %@ : %@", [e name], [e reason]);
        }
        
    }
}

-(void)setStreamHeader:(NSData *)headerData {
    if(self.flvStream && headerData)
    {
       // FLV stream header, comes from FLVDecoder
       self.flvStream.flvHeader = [[FLVHeader alloc] initWithData:headerData];
    }
}

-(void)cancelBackgoundTasks {
    [self.flvStream cancelBackgoundTasks];
}

-(id)addPeriodicTimeObserverForInterval:(CMTime)interval queue:(dispatch_queue_t)queue usingBlock:(void (^)(CMTime))block {
    return nil; // Not supported
}

-(void)removeTimeObserver:(id)observer {
}

#pragma mark - AudioQueue

-(AudioQueueRef)getAudioQueue {
    return [self.audioPlayerController getAudioQueue];
}

#pragma mark - FLVStream Delegate

-(void)connectingToStreamNotification:(NSNotification *)notification {
}

-(void)connectedToStreamNotification:(NSNotification *)notification {
    if ([self.delegate respondsToSelector:@selector(mediaPlayer:didReceiveInfo:andExtra:)]) {
        [self.delegate mediaPlayer:self didReceiveInfo:kTDPlayerInfoConnectedToStream andExtra:nil];
    }
}

-(void)connectionFailedNotification:(NSNotification *)notification {
    NSError *error = [NSError errorWithDomain:TritonPlayerDomain code:TDPlayerHostNotFoundError userInfo:nil];
    self.error = error;
    [self updateStateMachineForAction:kTDPlayerActionError];
}

-(void)streamStoppedNotification:(NSNotification *)notification {
    [self updateStateMachineForAction:kTDPlayerActionStop];
}

#pragma mark - AudioPlayerController Delegate

-(void)audioPlayerBuffering:(NSString*)percentage {
    if ([self.delegate respondsToSelector:@selector(mediaPlayer:didReceiveInfo:andExtra:)]) {
        [self.delegate mediaPlayer:self didReceiveInfo:kTDPlayerInfoBuffering andExtra:@{InfoBufferingPercentageKey : percentage}];
    }
}

-(void)audioPlayerPlaying:(NSNotification *)notification {
    // Move to playing state
    [self updateStateMachineForAction:kTDPlayerActionJumpToNextState];
}

-(void)audioPlayerStopped:(NSNotification *)notification {
    [self updateStateMachineForAction:kTDPlayerActionStop];
}

-(void)audioPlayerBufferTimeout:(NSNumber*)bufferTimeInSeconds {
    bufferTime = [bufferTimeInSeconds intValue];
    NSError *error = [NSError errorWithDomain:TritonPlayerDomain code:TDPlayerHostNotFoundError userInfo:nil];
    self.error = error;
    [self updateStateMachineForAction:kTDPlayerActionError];
}

-(void)audioPlayerDidPlayBuffer:(AudioBufferList *)buffer {
    if ([self.delegate respondsToSelector:@selector(mediaPlayer:didPlayBuffer:)]) {
        [self.delegate mediaPlayer:self didPlayBuffer:buffer];
    }
}

#pragma mark - CuePointEventController delegate

-(void)executeCuePointEvent:(CuePointEvent *)inCuePointEvent {
    if ([self.delegate respondsToSelector:@selector(mediaPlayer:didReceiveCuepointEvent:)]) {
        [self.delegate mediaPlayer:self didReceiveCuepointEvent:inCuePointEvent];
    }
}

#pragma mark - TDFLVMetaDataDelegate
-(void) didReceiveMetaData: (NSDictionary *)metaData
{
		if ([self.delegate respondsToSelector:@selector(mediaPlayer:didReceiveMetaData:)]) {
				[self.delegate mediaPlayer:self didReceiveMetaData:metaData];
		}
}


#pragma mark - KVO

-(void)isExecutingNotificationReceived:(BOOL)value
{
    // isPlaying property has changed
    FLOG(@"flvStream.isExecuting %d", self.flvStream.isExecuting);
    FLOG(@"audioPlayerController.isExecuting %d", self.audioPlayerController.isExecuting);
    
    BOOL isExecutingValue = value;
    if (isExecutingValue == NO)
	{
        if (self.flvStream.isExecuting == NO)
		{
            FLOG(@"flvStream.isExecuting = NO");
            
            [self.cuePointEventController removeAllCuePointsEvents];
        }

		// stream is stopped, we clear the decoder
		@synchronized(self)
		{
			[self.flvDecoder clear];
		}

        if ((self.flvStream.isExecuting == NO) && (self.audioPlayerController.isExecuting == NO) )
		{
            self.isExecuting = NO;
            
            FLOG(@"observeValueForKeyPath :: isExecuting == NO");
            
            // audio is stopped and stream we send notification
            if (self.streamStoppedNotificationAlreadySent == NO)
			{
                [self streamStoppedNotification:nil];
                self.streamStoppedNotificationAlreadySent = TRUE;
			}
        }
    }
	else
	{
        if ((self.flvStream.isExecuting == TRUE) && (self.audioPlayerController.isExecuting == TRUE))
		{
            FLOG(@"self.isExecuting = YES");
            
            self.isExecuting = YES;
            self.streamStoppedNotificationAlreadySent = FALSE;
        }
    }
}

#pragma mark - State machine

-(BOOL)canChangeStateWithAction:(TDPlayerAction) action {
    return [self nextStateForAction:action] != self.state;
}

// Returns the next state for an action. This doesn't change the state.
-(TDPlayerState)nextStateForAction:(TDPlayerAction)action {
    TDPlayerState nextState = self.state;
    
    switch (action) {
        case kTDPlayerActionPlay:
            if (self.state == kTDPlayerStateStopped || self.state == kTDPlayerStateError || self.state == kTDPlayerStateCompleted || self.state == kTDPlayerStatePaused) {
                nextState = kTDPlayerStateConnecting;
            }
            break;
            
        case kTDPlayerActionStop:
            if (self.state != kTDPlayerStateStopped) {
                if ( nextState !=  kTDPlayerStateError )
                    bufferTime = kLowDelaySecondsStart+1;
                nextState = kTDPlayerStateStopped;
                
            }
            break;
            
        case kTDPlayerActionJumpToNextState:
            if (self.state == kTDPlayerStateConnecting) {
                nextState = kTDPlayerStatePlaying;
                
            } else if (self.state == kTDPlayerStatePlaying) {
                nextState = kTDPlayerStateCompleted;
                
            }
            break;
            
        case kTDPlayerActionError:
            if (self.state != kTDPlayerStateError) {
                nextState = kTDPlayerStateError;
                
            }
            break;
            
        case kTDPlayerActionPause:
            if (self.state == kTDPlayerStatePlaying) {
                nextState = kTDPlayerStatePaused;
                
            }
            break;
    }
    
    return nextState;
}

-(void)updateStateMachineForAction:(TDPlayerAction)action
{
    TDPlayerState nextState = [self nextStateForAction:action];
    
    // If state changed, send the delegate a callback message
    if (self.state != nextState) {
        self.state = nextState;
        
        PLAYER_LOG(@"Changed state to: %@", [TritonPlayer toStringState: self.state]);
        
        // Clear error
        if (self.state != kTDPlayerStateError) {
            self.error = nil;
        }
        
        if ([self.delegate respondsToSelector:@selector(mediaPlayer:didChangeState:)]) {
            [self.delegate mediaPlayer:self didChangeState:self.state];
        }
    }
}

@end
