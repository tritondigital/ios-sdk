//
//  TDStreamPlayer.m
//  TritonPlayerSDK
//
//  Created by Carlos Pereira on 2015-03-12.
//  Copyright (c) 2015 Triton Digital. All rights reserved.
//

#import "TDStreamPlayer.h"
#import "TDMediaPlayer.h"
#import "TDFLVPlayer.h"
#import "MetadataConfiguration.h"
#import "TritonPlayer.h"
#import "TritonPlayerUtils.h"
#import "TDLocationManager.h"
#import "TDMediaPlaybackDelegate.h"
#import "TritonPlayerConstants.h"
#import "Logs.h"

#import <AVFoundation/AVFoundation.h>


NSString *const SettingsStreamPlayerProfileKey = @"StreamPlayerProfile";
NSString *const SettingsStreamPlayerUserAgentKey = @"StreamPlayerUserAgent";
NSString *const SettingsStreamPlayerStreamURLKey = @"StreamPlayerStreamURL";
NSString *const SettingsStreamPlayerTimeshiftStreamURLKey = @"StreamPlayerTimeshiftStreamURL";
NSString *const SettingsStreamPlayerSBMURLKey = @"StreamPlayerSBMURL";


@interface TDStreamPlayer()<TDMediaPlaybackDelegate>

@property (strong, nonatomic) id<TDMediaPlayback> player;

@property (assign, nonatomic) TDStreamProfile profile;

// Created by TritonPlayer
@property (copy, nonatomic) NSString *userAgent;

// The stream url contains the server, port and mount (with mount suffix if HLS)
@property (copy, nonatomic) NSString *streamURL;

// The stream url contains the server, port and mount for the sbm url
@property (copy, nonatomic) NSString *sbmURL;

// Received directly from the client, used for custom targeting.
@property (copy, nonatomic) NSDictionary *extraQueryParameters;

// Received directly from the client, used for TTAG targeting.
@property (copy, nonatomic) NSArray *tTags;

// Received directly from client to enable or disable adaptive buffering
@property (assign, nonatomic) SInt32 lowDelay;

// The stream token
@property (copy, nonatomic) NSString *token;
@property (assign, nonatomic) BOOL authRegisteredUser;

@property (copy, nonatomic) NSString *authUserId;
@property (copy, nonatomic) NSString *authKeyId;
@property (copy, nonatomic) NSString *authSecretKey;

@property (assign, nonatomic) TDPlayerState state;

@property (nonatomic, strong) NSString* lastStreamingUrl;

@property (nonatomic, strong) NSDictionary* settings;

@property (strong, nonatomic) NSMutableArray<id<TDMediaPlayback>>* oldPlayers;

@property (assign, nonatomic) BOOL timeshiftEnabled;

@property (copy, nonatomic) NSDictionary *dmpSegments;

@property (copy, nonatomic) NSString *listenerIdType;
@property (copy, nonatomic) NSString *listenerIdValue;

@property (assign, nonatomic) BOOL isCloudStreaming;

@end

@implementation TDStreamPlayer

@synthesize currentPlaybackTime;
@synthesize latestPlaybackTime;
@synthesize playbackDuration;
@synthesize delegate;
@synthesize error;

-(instancetype)init {
    return [self initWithSettings:nil];
}

-(instancetype)initWithSettings:(NSDictionary *)settings {
    self = [super init];
    if (self) {
        [self updateSettings:settings];
    }
    
    self.oldPlayers = [[NSMutableArray alloc] init];
    return self;
}

-(void)updateSettings:(NSDictionary *)settings {
    
    if (settings)
    {
      self.settings = settings;
      self.userAgent = settings[SettingsStreamPlayerUserAgentKey];
      self.streamURL = settings[SettingsStreamPlayerStreamURLKey];
      self.sbmURL = settings[SettingsStreamPlayerSBMURLKey];
      self.extraQueryParameters = settings[SettingsStreamParamsExtraKey];
      self.tTags = settings[SettingsTtagKey];
      self.lowDelay = [settings[SettingsLowDelayKey] intValue];
      self.token = settings[StreamParamExtraAuthorizationTokenKey];
        self.authUserId = settings[StreamParamExtraAuthorizationUserId];
        self.authRegisteredUser = settings[StreamParamExtraAuthorizationRegisteredUser];
        self.authKeyId = settings[StreamParamExtraAuthorizationKeyId];
        self.authSecretKey = settings[StreamParamExtraAuthorizationSecretKey];
        self.timeshiftEnabled = settings[SettingsTimeshiftEnabledKey];
        self.dmpSegments = settings[SettingsDmpHeadersKey];
        self.listenerIdType = settings[StreamParamExtraListenerIdType];
        self.listenerIdValue = settings[StreamParamExtraListenerIdValue];
        self.isCloudStreaming = settings[SettingsStreamCloudStreaming];

    
      // Set the correct profile. If profile is kTDStreamProfileOther, try to obtain the type by looking at the url suffix.
      self.profile = [settings[SettingsStreamPlayerProfileKey] integerValue];
    
      if (self.profile == KTDStreamProfileOther) {
            if ([self.streamURL hasSuffix:@".flv"]) {
                self.profile = kTDStreamProfileFLV;
                
            } else if ([self.streamURL hasSuffix:@".m3u8"]) {
                self.profile = KTDStreamProfileHLS;
            }
        }
        
    }
    self.lastStreamingUrl = nil;
}

- (void) createPlayer
{
    
	if (self.profile == kTDStreamProfileFLV) {
        if (self.settings) {
            self.player = [[TDFLVPlayer alloc] initWithSettings:self.settings];
        } else {
            self.player = [[TDFLVPlayer alloc] init];
        }
       
       NSLog(@"Stream FLV player created");
    }
    else
    {
       self.player = [[TDMediaPlayer alloc] init];
    }

    [self.oldPlayers addObject:self.player];
}

- (void)dealloc
{
    if ([self.player isKindOfClass:[TDFLVPlayer class]])
    {
     [(TDFLVPlayer*)self.player willBeDeleted];
    }
}

-(void)play {
    self.lastStreamingUrl = nil;
    
    if(self.state != kTDPlayerStatePaused)
    {
       // [self stop];
    }
    
		if (self.player == nil) {
            [self createPlayer];
		}
		else
		{
			if ([self.player isKindOfClass:[TDFLVPlayer class]])
			{
                
               // [(TDFLVPlayer*)self.player willBeDeleted];
                
                [self createPlayer];
			}
			else
			{
				if (self.profile == kTDStreamProfileFLV)
				{
					self.player = [[TDFLVPlayer alloc] init];
				}
			}
		}

    self.player.delegate = self;
    
    if ([self canChangeStateWithAction:kTDPlayerActionPlay]) {
        
        if (self.state != kTDPlayerStatePaused) {
            
            self.token = [TritonPlayerUtils generateJWTToken:self.extraQueryParameters andAuthKeyId:self.authKeyId andAuthUserId:self.authUserId andAuthRegisteredUser:self.authRegisteredUser andToken:self.token andAuthSercterKey:self.authSecretKey];
            
            NSString *queryParameters = [TritonPlayerUtils targetingQueryParametersWithLocation:[TDLocationManager sharedManager].targetingLocation andExtraParameters:self.extraQueryParameters andListenerIdType:self.listenerIdType andListenerIdValue:self.listenerIdValue withTtags:self.tTags andToken:self.token andIsCloudStreaming:self.isCloudStreaming];
            
            if ([queryParameters rangeOfString:@"banners"].location == NSNotFound) {
                if (queryParameters.length != 0) {
                    queryParameters = [queryParameters stringByAppendingString:@"&"];
                }
                
                queryParameters = [queryParameters stringByAppendingString:@"banners=none"];
            }
						
            
            BOOL removePercentEncoding = FALSE;
            if ([self.streamURL containsString:@"/;"]) {
                removePercentEncoding = TRUE;
            }
						//concat all query params
            NSURLComponents *url = [[NSURLComponents alloc]  initWithString:self.streamURL];
						NSArray *tdQueryParams = [queryParameters componentsSeparatedByString:@"&"];
						NSMutableArray<NSURLQueryItem *> *queryItems = [[NSMutableArray alloc] initWithArray:[url queryItems]] ;
						NSArray *kv = nil;
						
						for(NSString * param in tdQueryParams){
								kv = [param componentsSeparatedByString:@"="];
								[queryItems addObject:[[NSURLQueryItem alloc] initWithName:[kv objectAtIndex:0] value:[kv objectAtIndex:1]]];
						}
						
						[url setQueryItems:queryItems];
						NSMutableString *connectingToURL = [NSMutableString stringWithFormat:@"%@",
                                                            ((removePercentEncoding) ? [[url string] stringByRemovingPercentEncoding] : [url string]) ];
            
            if (self.profile == kTDStreamProfileFLV) {
                [self.player updateSettings:@{SettingsFLVPlayerUserAgentKey : self.userAgent,
                                              SettingsFLVPlayerStreamURLKey : connectingToURL,
                                              SettingsLowDelayKey : [NSNumber numberWithInt:self.lowDelay],
                                              SettingsDmpHeadersKey: self.dmpSegments
                                              }];
                
            } else if (self.profile == KTDStreamProfileHLS){
                [self.player updateSettings:@{SettingsMediaPlayerUserAgentKey : self.userAgent,
                                              SettingsMediaPlayerStreamURLKey : connectingToURL,
                                              SettingsMediaPlayerSBMURLKey : self.sbmURL ?: @"",
                                              SettingsDmpHeadersKey: self.dmpSegments,
                                              SettingsStreamCloudStreaming: @(self.isCloudStreaming)
                                            }];
            } else if (self.profile == KTDStreamProfileHLSTimeshift){
                [self.player updateSettings:@{SettingsMediaPlayerUserAgentKey : self.userAgent,
                                              SettingsMediaPlayerStreamURLKey : connectingToURL,
                                              SettingsDmpHeadersKey: self.dmpSegments
                                            }];
            } else {
                [self.player updateSettings:@{SettingsMediaPlayerStreamURLKey : connectingToURL,
                                              SettingsDmpHeadersKey: self.dmpSegments
                                            }];
            }
            
            self.lastStreamingUrl = connectingToURL;
        }
        
        [self updateStateMachineForAction:kTDPlayerActionPlay];
        [self.player play];
        
    }
}

-(void)stop {
		[self.player stop];
		[self updateStateMachineForAction:kTDPlayerActionStop];
}

-(void)pause {
        if (self.profile == KTDStreamProfileOther) {
            [self.player pause];
            
            [self updateStateMachineForAction:kTDPlayerActionPause];
            
        } else {
            [self.player stop];
            
            [self updateStateMachineForAction:kTDPlayerActionStop];
        }
}

-(void)changePlaybackRate:(float)rate {
    if (self.player) {
        [self.player changePlaybackRate:rate];
    } else {
        NSLog(@"AVPlayer is not initialized");
    }
}

-(void)seekToTimeInterval:(NSTimeInterval)interval {
    if ([self.player respondsToSelector:@selector(seekToTimeInterval:)]) {
        [self.player seekToTimeInterval:interval];
    }
}

-(void)seekToTime:(CMTime)time completionHandler:(void (^)(BOOL))completionHandler {
    if ([self.player respondsToSelector:@selector(seekToTime:completionHandler:)]) {
        [self.player seekToTime:time completionHandler:completionHandler];
    }
}

- (void)setAllowsExternalPlayback:(BOOL)allow {
    
    if ([self.player respondsToSelector:@selector(setAllowsExternalPlayback:)]) {
        [self.player setAllowsExternalPlayback:allow];
    }
}

-(void)cancelBackgoundTasks {
    if (self.profile == kTDStreamProfileFLV) {
        [(TDFLVPlayer*)self.player cancelBackgoundTasks];
    }
}

#pragma mark - AudioQueue

-(AudioQueueRef)getAudioQueue {
    if ([self.player respondsToSelector:@selector(getAudioQueue)]) {
        return [self.player getAudioQueue];
        
    } else {
        return nil;
    }
}

#pragma mark - AudioPlayer

-(void)mute {
    [self.player mute];
}

-(void)unmute {
    [self.player unmute];
}

-(void)setVolume:(float)volume {
    [self.player setVolume:volume];
}

-(NSTimeInterval)currentPlaybackTime {
    return [self.player currentPlaybackTime];
}

-(CMTime)latestPlaybackTime{
    return [self.player latestPlaybackTime];
}

-(NSTimeInterval)playbackDuration {
    return [self.player playbackDuration];
}

-(id)addPeriodicTimeObserverForInterval:(CMTime)interval queue:(dispatch_queue_t)queue usingBlock:(void (^)(CMTime))block {
    return [self.player addPeriodicTimeObserverForInterval:interval queue:queue usingBlock:block];
}

-(void)removeTimeObserver:(id)observer {
    [self.player removeTimeObserver:observer];
}

#pragma mark - TDMediaPlaybackDelegate methods

-(void)mediaPlayer:(id<TDMediaPlayback>)player didReceiveCuepointEvent:(CuePointEvent *)cuePointEvent {
    if ([self.delegate respondsToSelector:@selector(mediaPlayer:didReceiveCuepointEvent:)]) {
        [self.delegate mediaPlayer:self didReceiveCuepointEvent:cuePointEvent];
    }
}

-(void)mediaPlayer:(id<TDMediaPlayback>)player didReceiveAnalyticsEvent:(AVPlayerItemAccessLogEvent *)analyticsEvent {
    if ([self.delegate respondsToSelector:@selector(mediaPlayer:didReceiveAnalyticsEvent:)]) {
        [self.delegate mediaPlayer:self didReceiveAnalyticsEvent:analyticsEvent];
    }
}

-(void)mediaPlayer:(id<TDMediaPlayback>)player didReceiveMetaData:(NSDictionary *)metaData {
		if ([self.delegate respondsToSelector:@selector(mediaPlayer:didReceiveMetaData:)]) {
				[self.delegate mediaPlayer:self didReceiveMetaData:metaData];
		}
}

-(void)mediaPlayer:(id<TDMediaPlayback>)player didChangeState:(TDPlayerState)newState {
    switch (newState) {
            
        // Just advance to the next state
        case kTDPlayerStatePlaying:
        case kTDPlayerStateCompleted:
            [self updateStateMachineForAction:kTDPlayerActionJumpToNextState];

           while([self.oldPlayers count] > 1) {
                if ([self.oldPlayers[0] isKindOfClass:[TDFLVPlayer class]])
                {
                    [(TDFLVPlayer*)self.oldPlayers[0] willBeDeleted];
                }
                [self.oldPlayers[0] stop];
                [self.oldPlayers removeObjectAtIndex:0];
            }
           
            break;
            
        case kTDPlayerStateError:
            self.error = player.error;
            [self updateStateMachineForAction:kTDPlayerActionError];
            break;
            
        default:
            break;
    }
    
}

-(void)mediaPlayer:(id<TDMediaPlayback>)player didReceiveInfo:(TDPlayerInfo)info andExtra:(NSDictionary *)extra {
    if ([self.delegate respondsToSelector:@selector(mediaPlayer:didReceiveInfo:andExtra:)]) {
        [self.delegate mediaPlayer:self didReceiveInfo:info andExtra:extra];
    }
}

- (void)mediaPlayer:(id<TDMediaPlayback>)player didPlayBuffer:(AudioBufferList *)buffer {
    if ([self.delegate respondsToSelector:@selector(mediaPlayer:didPlayBuffer:)]) {
        [self.delegate mediaPlayer:self didPlayBuffer:buffer];
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
                nextState = kTDPlayerStateStopped;
                
            }
            break;
            
        case kTDPlayerActionJumpToNextState:
            if (self.state == kTDPlayerStateConnecting) {
                nextState = kTDPlayerStatePlaying;
                
            } else if ( (self.state == kTDPlayerStatePlaying) && (self.profile == KTDStreamProfileOther)) {
                nextState = kTDPlayerStateCompleted;
                
            }
            break;
            
        case kTDPlayerActionError:
            if (self.state != kTDPlayerStateError) {
                nextState = kTDPlayerStateError;
                
            }
            break;
            
        case kTDPlayerActionPause:
            if (self.state == kTDPlayerStatePlaying || self.state == kTDPlayerStateConnecting) {
                nextState = kTDPlayerStatePaused;
                
            }
            break;
    }
    
    return nextState;
}

-(void)updateStateMachineForAction:(TDPlayerAction)action {
    
    TDPlayerState nextState = [self nextStateForAction:action];
    
    // If state changed, send the delegate a callback message
    if (self.state != nextState) {
        self.state = nextState;
        
        PLAYER_LOG(@"Changed state to: %@", [TritonPlayer toStringState:self.state]);
        
        // Clear error
        if (self.state != kTDPlayerStateError) {
            self.error = nil;
        }
        
        if ([self.delegate respondsToSelector:@selector(mediaPlayer:didChangeState:)]) {
            [self.delegate mediaPlayer:self didChangeState:self.state];
        }
    }
}


-(NSString*) getStreamingUrl
{
    return self.lastStreamingUrl;
}
@end
