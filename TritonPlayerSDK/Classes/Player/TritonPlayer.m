#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

#import "TritonPlayer.h"
#import "CuePointEvent.h"
#import "CuePointEventProtected.h"
#import "CuePointEventController.h"
#import "FLVStreamPlayerLibConstants.h"
#import "TritonPlayerConstants.h"
#import "TDReachability.h"
#import "UIDevice+Hardware.h"
#import "Logs.h"
#import "TDLocationManager.h"
#import "TDStreamPlayer.h"
#import "TDStationPlayer.h"
#import "TDMediaPlayer.h"
#import <MediaPlayer/MediaPlayer.h>



NSString *const TritonSDKVersion                        = @"2.7.6"; //TritonSDKVersion

CGFloat   const  kDefaultPlayerDebouncing               = 0.2f; //Default debouncing for the Play action, in seconds

NSString *const TritonPlayerThreadName                  = @"TritonPlayer";

NSString *const SettingsEnableLocationTrackingKey       = @"EnableLocationTracking";
NSString *const SettingsStationNameKey                  = @"StationId";
NSString *const SettingsMountKey                        = @"Mount";
NSString *const SettingsContentURLKey                   = @"ContentURL";
NSString *const SettingsContentTypeKey                  = @"ContentType";
NSString *const SettingsAppNameKey                      = @"AppId"; // Defaults to CustomPlayer1
NSString *const SettingsBroadcasterKey                  = @"BroadcasterId";
NSString *const SettingsStreamParamsExtraKey            = @"StreamParamsExtra";
NSString *const SettingsTtagKey                         = @"TTags";
NSString *const SettingsPlayerServicesRegion            = @"PlayerServicesRegion"; 
NSString *const SettingsLowDelayKey                     = @"LowDelay";
NSString *const SettingsReferrerURLKey                  = @"ReferrerURL";
NSString *const SettingsSecIdKey                        = @"SecId";
NSString *const SettingsDebouncingKey                   = @"DebouncingKey";
NSString *const SettingsExtraForceDisableHLSKey         = @"ExtraForceDisableHLS";
NSString *const SettingsBitrateKey                      = @"MountBitrate";
NSString *const SettingsTimeshiftEnabledKey             = @"TimeshiftEnabled";
NSString *const SettingsDmpHeadersKey                   = @"DmpHeaders";

/// Extra parameters for location targeting

NSString *const StreamParamExtraLatitudeKey             = @"lat";
NSString *const StreamParamExtraLongitudeKey            = @"long";
NSString *const StreamParamExtraPostalCodeKey           = @"postalcode";
NSString *const StreamParamExtraCountryKey              = @"country";

NSString *const StreamParamExtraAgeKey                  = @"age";
NSString *const StreamParamExtraDateOfBirthKey          = @"dob";
NSString *const StreamParamExtraYearOfBirthKey          = @"yob";
NSString *const StreamParamExtraGenderKey               = @"gender";

NSString *const StreamParamExtraCustomSegmentIdKey      = @"csegid";
NSString *const StreamParamExtraBannersKey              = @"banners";

NSString *const StreamParamExtraAuthorizationTokenKey   = @"tdtok";
NSString * const StreamParamExtraAuthorizationUserId         = @"auth_user_id";
NSString * const StreamParamExtraAuthorizationRegisteredUser = @"auth_registered_user";
NSString * const StreamParamExtraAuthorizationKeyId          = @"auth_key_id";
NSString * const StreamParamExtraAuthorizationSecretKey      = @"auth_secret_key";

NSString *const StreamParamExtraDist                     = @"dist";
NSString *const StreamParamExtraDistTimeshift            = @"dist-timeshift";

NSString *const TritonPlayerDomain                      = @"com.tritondigital.error";

NSString *const InfoBufferingPercentageKey              = @"percentage";
NSString *const InfoAlternateMountNameKey               = @"alternateMount";

NSString *const StreamParamExtraListenerIdValue         = @"StreamParamExtraListenerIdValue";
NSString *const StreamParamExtraListenerIdType          = @"StreamParamExtraListenerIdType";
NSString *const SettingsStreamCloudStreaming            = @"SettingsStreamCloudStreaming";

@interface TritonPlayer() <CLLocationManagerDelegate, TDMediaPlaybackDelegate>

@property (nonatomic, weak) id<TritonPlayerDelegate> delegate;

// Stream configuration
@property (nonatomic, copy) NSString *mount;
@property (nonatomic, copy) NSString *stationName;
@property (nonatomic, copy) NSString *broadcaster;
@property (nonatomic, copy) NSString *appName;
@property (nonatomic, assign) PlayerContentType contentType;

@property (nonatomic, copy) NSString *playerServicesRegion;

// Url for on-demand or non provisioned triton stream content
@property (nonatomic, copy) NSString *contentUrl;

// Targeting
@property (nonatomic, assign) BOOL enableLocationTacking;
@property (nonatomic, copy) NSDictionary* extraQueryParameters;
@property (nonatomic, copy) NSDictionary* dmpSegments;
@property (nonatomic, copy) NSArray* tTags;
@property (nonatomic, strong) NSString *token;
@property (nonatomic, assign) BOOL authRegisteredUser;
@property (nonatomic, strong) NSString *authUserId;
@property (nonatomic, strong) NSString *authKeyId;
@property (nonatomic, strong) NSString *authSecretKey;

// These parameters are used for content protection but it's been a while since they are not used. Eventually they may be removed.
@property (nonatomic, strong) NSString *referrerURL;
@property (nonatomic, strong) NSString *secId;

@property (nonatomic, assign) SInt32 lowDelay;
@property (nonatomic, assign) SInt32 bitrate;

@property (nonatomic, assign) BOOL forceDisableHLS;
@property (nonatomic, assign) BOOL timeshiftEnabled;

@property (nonatomic, assign) NSTimeInterval debouncing;

@property (nonatomic, assign) TDPlayerState state;
@property (nonatomic, assign) BOOL volumeStopped;

@property BOOL isCloudStreaming;
@property BOOL isExecuting;
@property BOOL stopStreamThread;
@property BOOL streamFinishedNotificationAlreadySent; // indicate that a notification when a stream has been closed (failed or not)

// stopStreamThread: Used to determine if we should kill the thread AFTER notifications are sent. Setting active to false manually would cause notifications to not be sent.
@property BOOL active;

@property (assign) BOOL shouldResumePlaybackAfterInterruption;

// Can be a TDStationPlayer or a TDStreamPlayer depending on the kind of media being played
@property (nonatomic, strong) id<TDMediaPlayback> mediaPlayer;

@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundTaskIdentifier;
@property (nonatomic, assign) BOOL playerWasInterrupted;

@property (nonatomic, strong) NSError *error;


@property (nonatomic, strong) NSTimer *playDebouncingTimer;
@property (nonatomic, strong) NSOperationQueue *playerOperationQueue;

//Using a property to store the external playback setting because the mediaPlayer instance will be nil when play method is called.
@property (nonatomic, assign) BOOL shouldAllowExternalPlayback;

@property (nonatomic, strong) NSString *listenerIdType;
@property (nonatomic, strong) NSString *listenerIdValue;

@end

@implementation TritonPlayer

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// dealloc
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[AVAudioSession sharedInstance] removeObserver:self forKeyPath:@"outputVolume"];

}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// getAudioQueue
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (AudioQueueRef)getAudioQueue
{
    if ([self.mediaPlayer respondsToSelector:@selector(getAudioQueue)]) {
        return [self.mediaPlayer getAudioQueue];
        
    } else {
        return nil;
    }
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// initWithDelegateAndSettings
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (id)initWithDelegate:(id)inDelegate andSettings:(NSDictionary *)settings
{
	self = [super init];
	if (self)
	{
        UIDeviceHardwareEmptyFunction();
        
        _contentType = PlayerContentTypeOther;
        _state = kTDPlayerStateStopped;
        
        [self configureAudioSession];
        
		_delegate = inDelegate;
        [self updateSettings:settings];
        
        // For debugging during development
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onCreateSimulatedCuePoint) name:@"CreateSimulatedCuePoint" object:nil];
			self.playerOperationQueue = [[NSOperationQueue alloc] init];
			[self.playerOperationQueue setMaxConcurrentOperationCount:1];
    }
	return self;
}

-(void) updateSettings:(NSDictionary *) settings {
    if (settings) {
        
        self.stationName = settings[SettingsStationNameKey];
        self.mount = settings[SettingsMountKey];
        self.contentUrl = settings[SettingsContentURLKey];
        
        NSNumber *contentType = settings[SettingsContentTypeKey];
        if (contentType) {
            self.contentType = [contentType intValue];
        }
        
        NSString *appName = settings[SettingsAppNameKey];
        self.appName = appName ? appName : kDefaultAppName;
        
        self.broadcaster = settings[SettingsBroadcasterKey];
        self.referrerURL = settings[SettingsReferrerURLKey];
        self.secId = settings[SettingsSecIdKey];
        self.enableLocationTacking = [settings[SettingsEnableLocationTrackingKey] boolValue];
        self.forceDisableHLS = [settings[SettingsExtraForceDisableHLSKey] boolValue];
        self.timeshiftEnabled = [settings[SettingsTimeshiftEnabledKey] boolValue];
        
        
        self.lowDelay = [settings[SettingsLowDelayKey] intValue];
        
        if (self.enableLocationTacking) {
            [[TDLocationManager sharedManager] startLocation];
        
        } else {
            [[TDLocationManager sharedManager] stopLocation];
        }
        
        self.extraQueryParameters = settings[SettingsStreamParamsExtraKey];
        
        self.dmpSegments = settings[SettingsDmpHeadersKey];

        self.tTags = settings[SettingsTtagKey];
        
        self.playerServicesRegion = settings[SettingsPlayerServicesRegion];
        if(self.playerServicesRegion == nil)
            self.playerServicesRegion= @"";
        
        self.token = settings[StreamParamExtraAuthorizationTokenKey];
        if(self.token == nil)
            self.token= @"";
        
        self.authUserId = settings[StreamParamExtraAuthorizationUserId];
        if(self.authUserId == nil)
            self.authUserId= @"";
    
        self.authSecretKey = settings[StreamParamExtraAuthorizationSecretKey];
        if(self.authSecretKey == nil)
            self.authSecretKey= @"";
        
        self.authKeyId = settings[StreamParamExtraAuthorizationKeyId];
        if(self.authKeyId == nil)
            self.authKeyId = @"";
        
        CGFloat deb = [settings[SettingsDebouncingKey] floatValue];
        if(deb <= 0)  deb = kDefaultPlayerDebouncing;
        self.debouncing = (NSTimeInterval) deb;

        if ([self.mount isEqualToString:@""]) {
            self.mount = nil;
        }

        self.listenerIdType = settings[StreamParamExtraListenerIdType];
        if(self.listenerIdType == nil)
            self.listenerIdType= @"";
        
        self.listenerIdValue = settings[StreamParamExtraListenerIdValue];
        if(self.listenerIdValue == nil)
            self.listenerIdValue= @"";
        
        self.isCloudStreaming = settings[SettingsStreamCloudStreaming];
        if(self.isCloudStreaming == nil)
            self.isCloudStreaming= NO;
        
    }
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// getLibVersion
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (NSString *)getLibVersion
{
	return kLibVersion;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// isNetworkReachable
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (BOOL)isNetworkReachable
{
	TDReachability *lReachability = [TDReachability reachabilityWithHostName:@"www.apple.com"];
	NetworkStatus lNetStatus = [lReachability currentReachabilityStatus];
	return (lNetStatus != NotReachable);
}

-(CLLocation *)targetingLocation {
    return [TDLocationManager sharedManager].targetingLocation;
}

-(NSDictionary *)extraQueryParameters {
    return _extraQueryParameters ? _extraQueryParameters : @{};
}

-(NSArray *)tTags {
    return _tTags ? _tTags : @[];
}

#pragma  mark - Stream playback and Provisioning

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// start
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)startInThread {
    NSThread* mostRecent = [NSThread currentThread];
    if(mostRecent != nil && [[mostRecent name] isEqualToString:TritonPlayerThreadName])
    {
      [mostRecent cancel];
    }
   
    [NSThread currentThread].name = TritonPlayerThreadName;
    
    @autoreleasepool {
        if (self.mount) {
            
            if (![self.mediaPlayer isKindOfClass:[TDStationPlayer class]]) {
                self.mediaPlayer = [[TDStationPlayer alloc] init];
                self.mediaPlayer.delegate = self;
            }
            
            [self.mediaPlayer updateSettings:@{SettingsStationPlayerUserAgentKey : [self createUserAgentString],
                                               SettingsStationPlayerMountKey : self.mount,
                                               SettingsStationPlayerBroadcasterKey : self.broadcaster,
                                               SettingsStreamParamsExtraKey : self.extraQueryParameters,
                                               SettingsStationPlayerForceDisableHLSkey : @(self.forceDisableHLS),
                                               SettingsTimeshiftEnabledKey : @(self.timeshiftEnabled),
                                               SettingsTtagKey : self.tTags,
                                               SettingsPlayerServicesRegion: self.playerServicesRegion,
                                               StreamParamExtraAuthorizationTokenKey: self.token,
                                               StreamParamExtraAuthorizationKeyId : self.authKeyId,
                                               StreamParamExtraAuthorizationUserId: self.authUserId,
                                               StreamParamExtraAuthorizationSecretKey: self.authSecretKey,
                                               StreamParamExtraAuthorizationRegisteredUser: @(self.authRegisteredUser),
                                               SettingsLowDelayKey : [NSNumber numberWithInt:self.lowDelay],
                                               SettingsDmpHeadersKey: (self.dmpSegments ?: [NSNull null]),
                                               StreamParamExtraListenerIdType: (self.listenerIdType ?: @""),
                                               StreamParamExtraListenerIdValue: self.listenerIdValue
                                               }];
        
        } else {
            if (![self.mediaPlayer isKindOfClass:[TDStreamPlayer class]]) {
                self.mediaPlayer = [[TDStreamPlayer alloc] init];
                self.mediaPlayer.delegate = self;
            }
            
            TDStreamProfile profile;
            
            // Map between PlayerContent and TDStreamProfile
            switch (self.contentType) {
                case PlayerContentTypeFLV:
                    profile = kTDStreamProfileFLV;
                    break;
                    
                case PlayerContentTypeHLS:
                    profile = KTDStreamProfileHLS;
                    break;
                    
                default:
                    profile = KTDStreamProfileOther;
                    break;
            }
            
            [self.mediaPlayer updateSettings:@{SettingsStreamPlayerProfileKey : @(profile),
                                               SettingsStreamPlayerUserAgentKey : [self createUserAgentString],
                                               SettingsStreamParamsExtraKey : self.extraQueryParameters,
                                               SettingsStreamPlayerStreamURLKey : self.contentUrl,
                                               SettingsTtagKey : self.tTags,
                                               StreamParamExtraAuthorizationTokenKey: self.token,
                                               SettingsTimeshiftEnabledKey : @(self.timeshiftEnabled),
                                               StreamParamExtraAuthorizationKeyId : self.authKeyId,
                                               StreamParamExtraAuthorizationUserId: self.authUserId,
                                               StreamParamExtraAuthorizationSecretKey: self.authSecretKey,
                                               StreamParamExtraAuthorizationRegisteredUser: @(self.authRegisteredUser),
                                               SettingsLowDelayKey : [NSNumber numberWithInt:self.lowDelay],
                                               SettingsDmpHeadersKey: (self.dmpSegments ?: [NSNull null])
                                               }];
        }

        if ([self.mediaPlayer isKindOfClass:[TDStationPlayer class]]) {
            [self.mediaPlayer play:self.isCloudStreaming];
        }else{
            [self.mediaPlayer play];
        }
       
        //Set the allowsExternalPlayback flag for the current media player if it's supported.
        [self.mediaPlayer setAllowsExternalPlayback: self.shouldAllowExternalPlayback];
        
        [[NSRunLoop currentRunLoop] addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
        while (_active) {
            CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.090, FALSE);//0.090 instead of 0.30
        }
    }
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// internal Play
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
- (void) internalPlay
{
    @synchronized(self)
	{
        if ([self canChangeStateWithAction:kTDPlayerActionPlay])
		{
            _active = TRUE;
            _stopStreamThread = NO;
            
            TDPlayerState lastState = self.state;
            [self updateStateMachineForAction:kTDPlayerActionPlay];
            
            if (lastState == kTDPlayerStatePaused)
			{
                // Resume paused content
                [self.mediaPlayer play];
			}
			else
			{
                [NSThread detachNewThreadSelector:@selector(startInThread) toTarget:self withObject:nil];
            }
        }
		else
		{
            FLOG(@"Pressing play when state is %zd", self.state);
        }
    }
}


//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// play
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)play
{
	if(self.mount != nil)
    {
        [self stop];
    }
    
    [self setVolumeStopped:NO];
	[self.playerOperationQueue addOperationWithBlock: ^{
    
        float vol = [[AVAudioSession sharedInstance] outputVolume];
        if(vol == 0.0) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                // use weakSelf here
            
                MPVolumeView *volumeView = [[MPVolumeView alloc] init];
                  UISlider *volumeViewSlider = nil;

                  for (UIView *view in volumeView.subviews) {
                    if ([view isKindOfClass:[UISlider class]]) {
                      volumeViewSlider = (UISlider *)view;
                      break;
                    }
                  }

                  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    volumeViewSlider.value = 0.3f;
                  });
            });
        }
        
		if(self.playDebouncingTimer != nil)
		{
			[self.playDebouncingTimer invalidate];
		}
    
		if( [NSThread isMainThread])
		{
			self.playDebouncingTimer = [NSTimer scheduledTimerWithTimeInterval: self.debouncing  target: self  selector: @selector(internalPlay) userInfo: nil repeats: NO];
		}
		else
		{
			self.playDebouncingTimer = [NSTimer timerWithTimeInterval:self.debouncing target:self selector:@selector(internalPlay) userInfo:nil repeats:NO];
			
			[[NSRunLoop mainRunLoop] addTimer:self.playDebouncingTimer forMode:NSDefaultRunLoopMode];
			[[NSRunLoop mainRunLoop] run];
		}
	}];
}


//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// stop
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)stop
{
	[self.playerOperationQueue cancelAllOperations];
	[self.playerOperationQueue addOperationWithBlock: ^{
		@synchronized(self)
		{
			// We kill the thread after notifications are sent since we manually pressed Stop so we don't need to try other available servers
			_stopStreamThread = TRUE;
		
			[self updateStateMachineForAction:kTDPlayerActionStop];
			usleep(self.debouncing * 1000000);
			[self.mediaPlayer stop];

			if (_stopStreamThread)
			{
				_active = FALSE;
				_stopStreamThread = TRUE;
			}
		}
	}];
}



-(void)pause {
    if ([self.mediaPlayer isKindOfClass:[TDStreamPlayer class]]) {
    [self.playerOperationQueue cancelAllOperations];
    [self.playerOperationQueue addOperationWithBlock: ^{
        @synchronized(self)
        {
            usleep(self.debouncing * 1000000);
            [self.mediaPlayer pause];
            
            [self updateStateMachineForAction:kTDPlayerActionPause];
        }
    }];
    } else {
        [self stop];
    }
    
}

- (void)changePlaybackRate:(float)rate {
    if (self.mediaPlayer) {
        [self.mediaPlayer changePlaybackRate:rate];
    } else {
        NSLog(@"AVPlayer is not initialized");
    }
}

-(void)seekToLive {
    if ([self.mediaPlayer respondsToSelector:@selector(seekToLive)]) {
        [self.mediaPlayer seekToLive];
    }
}
   
-(void)getCloudStreamInfo {
    if ([self.mediaPlayer respondsToSelector:@selector(getCloudStreamInfo)]) {
        [self.mediaPlayer getCloudStreamInfo];
    }
}
    
-(void)playCloudProgram:(NSString *) programId {
    if ([self.mediaPlayer respondsToSelector:@selector(playCloudProgram:)]) {
        [self.mediaPlayer playCloudProgram:programId];
    }
}

-(void)seekToTimeInterval:(NSTimeInterval)interval {
    if ([self.mediaPlayer respondsToSelector:@selector(seekToTimeInterval:)]) {
        [self.mediaPlayer seekToTimeInterval:interval];
    }
}

-(void)seekToTime:(CMTime)time completionHandler:(void (^)(BOOL))completionHandler {
    if ([self.mediaPlayer respondsToSelector:@selector(seekToTime:completionHandler:)]) {
        [self.mediaPlayer seekToTime:time completionHandler:completionHandler];
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
				
				case kTDPlayerActionReconnect:
						if( self.state == kTDPlayerStatePlaying || self.state == kTDPlayerStateStopped || self.state == kTDPlayerStateError ){
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
        self.state = nextState;
        
    PLAYER_LOG(@"Changed state to: %@", [TritonPlayer toStringState:self.state]);
        
        // Clear error
        if (self.state != kTDPlayerStateError) {
            self.error = nil;
        }
        
        if ([self.delegate respondsToSelector:@selector(player:didChangeState:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate player:self didChangeState:self.state];
            });
        }
}

+(NSString*) toStringState:(TDPlayerState)state
{
    switch (state) {
        case kTDPlayerStateCompleted: return @"Completed";
        case kTDPlayerStateConnecting: return @"Connecting";
        case kTDPlayerStateStopped: return @"Stopped";
        case kTDPlayerStatePlaying: return @"Playing";
        case kTDPlayerStatePaused: return @"Paused";
        case kTDPlayerStateError: return @"Error";
            
        default:
            break;
    }
}

#pragma mark - TDMediaPlaybackDelegate methods

-(void)mediaPlayer:(id<TDMediaPlayback>)player didReceiveCloudStreamInfoEvent:(NSDictionary *)cloudStreamInfoEvent {
    if ([self.delegate respondsToSelector:@selector(player:didReceiveCloudStreamInfoEvent:)]) {
        [self.delegate performSelector:@selector(player:didReceiveCloudStreamInfoEvent:) withObject:self withObject:cloudStreamInfoEvent];
    }
}

-(void)mediaPlayer:(id<TDMediaPlayback>)player didReceiveCuepointEvent:(CuePointEvent *)cuePointEvent {
    if ([self.delegate respondsToSelector:@selector(player:didReceiveCuePointEvent:)]) {
        [self.delegate performSelector:@selector(player:didReceiveCuePointEvent:) withObject:self withObject:cuePointEvent];
    }
    [cuePointEvent hasBeenExecuted];
}

-(void)mediaPlayer:(id<TDMediaPlayback>)player didReceiveAnalyticsEvent:(AVPlayerItemAccessLogEvent *)analyticsEvent {
    if ([self.delegate respondsToSelector:@selector(player:didReceiveAnalyticsEvent:)]) {
        [self.delegate performSelector:@selector(player:didReceiveAnalyticsEvent:) withObject:self withObject:analyticsEvent];
    }
}

-(void)mediaPlayer:(id<TDMediaPlayback>)player didReceiveMetaData:(NSDictionary *)metaData {
		if ([self.delegate respondsToSelector:@selector(player:didReceiveMetaData:)]) {
				dispatch_async(dispatch_get_main_queue(), ^{
						[self.delegate performSelector:@selector(player:didReceiveMetaData:) withObject:self withObject:metaData];
				});
		}
}

-(void)mediaPlayer:(id<TDMediaPlayback>)player didChangeState:(TDPlayerState)newState {
    switch (newState) {
        case kTDPlayerStateCompleted:
            [self updateStateMachineForAction:kTDPlayerActionJumpToNextState];
            break;

        	case kTDPlayerStateConnecting:
						[self updateStateMachineForAction:kTDPlayerActionReconnect];
            break;
            
        case kTDPlayerStateError: {
            // KVO will not be called, since FLVStream is not started, so change state manually
            self.isExecuting = FALSE;
            
            // We kill the thread since we tried connection to all available the servers
            _active = FALSE;
            _stopStreamThread = TRUE;
            
            self.error = player.error;
            [self updateStateMachineForAction:kTDPlayerActionError];
        }
            break;
            
        case kTDPlayerStatePaused:
            
            break;
            
        case kTDPlayerStatePlaying:
            self.isExecuting = YES;
            
            if (self.state == kTDPlayerStateConnecting) {
                [self updateStateMachineForAction:kTDPlayerActionJumpToNextState];
            }
            break;
            
        case kTDPlayerStateStopped:
            self.isExecuting = NO;
            break;
        
        default:
            break;
    }
}

-(void)mediaPlayer:(id<TDMediaPlayback>)player didReceiveInfo:(TDPlayerInfo)info andExtra:(NSDictionary *)extra {
    if ([self.delegate respondsToSelector:@selector(player:didReceiveInfo:andExtra:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate player:self didReceiveInfo:info andExtra:extra];
        });
    }
}

- (void)mediaPlayer:(id<TDMediaPlayback>)player didPlayBuffer:(AudioBufferList *)buffer {
    if ([self.delegate respondsToSelector:@selector(player:didPlayAudioBuffer:)]) {
        [self.delegate player:self didPlayAudioBuffer: buffer];
    }
}

#pragma mark - User Agent

- (NSString*)createUserAgentString
{
    //Get platform
    NSString *platformString = [[UIDevice currentDevice] platform];
    platformString = [platformString stringByReplacingOccurrencesOfString:@"iPhone" withString:@"iPhone/"];
    platformString = [platformString stringByReplacingOccurrencesOfString:@"iPod" withString:@"iPod/"];
    platformString = [platformString stringByReplacingOccurrencesOfString:@"iPad" withString:@"iPad/"];
    
    if ([platformString isEqualToString:@"i386"]) platformString = @"Simulator/i386";
    if ([platformString isEqualToString:@"x86_64"]) platformString = @"Simulator/x86_64";
    
    // We send the callsign if the station name was not set
    NSString *stationName = self.stationName ? self.stationName : self.mount;
    
    NSString *userAgentString = [NSString stringWithFormat:@"%@/%@ iOS/%@ %@ %@/%@ TdSdk/iOS-%@-opensource",
                                 self.appName,
                                 [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"],
                                 [[UIDevice currentDevice] systemVersion],
                                 platformString,
                                 self.broadcaster,
                                 stationName,
                                 TritonSDKVersion];
    
    return userAgentString;
}

#pragma mark - AudioPlayer

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// mute
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)mute
{
    if ([self.mediaPlayer isKindOfClass:[TDStreamPlayer class]]) {
    [self.mediaPlayer mute];
    } else {
        [self stop];
    }
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// unmute
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)unmute
{
    if ([self.mediaPlayer isKindOfClass:[TDStreamPlayer class]]) {
    [self.mediaPlayer unmute];
    } else {
        [self play];
    }
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// setVolume
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)setVolume:(float)volume
{
    [self.mediaPlayer setVolume:volume];
}

-(NSTimeInterval)playbackDuration {
    return [self.mediaPlayer playbackDuration];
}

-(NSTimeInterval)currentPlaybackTime {
    return [self.mediaPlayer currentPlaybackTime];
}

-(CMTime)latestPlaybackTime {
    return [self.mediaPlayer latestPlaybackTime];
}

-(void)setAllowsExternalPlayback:(BOOL)allow {
    [self.mediaPlayer setAllowsExternalPlayback:allow];
}

#pragma mark - Debugging

- (void)onCreateSimulatedCuePoint {

}

#pragma mark - Audio Session

-(void) configureAudioSession {
    // Ensure AVAudioSession is initialized
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    NSError *setCategoryError = nil;
    BOOL success = [audioSession setCategory:AVAudioSessionCategoryPlayback error:&setCategoryError];
    
    if (!success) {
        PLAYER_LOG(@"Error setting audio session category");
    }
    
    NSError *activationError = nil;
    success = [audioSession setActive:YES error:&activationError];
    
    if (!success) {
        PLAYER_LOG(@"Error activating session");
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioSessionRouteChangedNotification:) name:AVAudioSessionRouteChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioSessionInterruptionNotification:) name:AVAudioSessionInterruptionNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioSessionMediaServicesLostNotification:) name:AVAudioSessionMediaServicesWereLostNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioSessionMediaServicesResetNotification:) name:AVAudioSessionMediaServicesWereResetNotification object:nil];
   [audioSession addObserver:self forKeyPath:@"outputVolume" options:NSKeyValueObservingOptionNew context:nil];
    
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
}

- (void)audioSessionRouteChangedNotification:(NSNotification *)notification {
    
    NSDictionary *routeChangedDict = notification.userInfo;
    NSInteger routeChangeReason = [routeChangedDict[AVAudioSessionRouteChangeReasonKey] integerValue];
    
    switch (routeChangeReason) {
        case AVAudioSessionRouteChangeReasonCategoryChange:
            break;
            
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            // Stop if player is playing and user removed headphones
            if (self.isExecuting) {
                [self stop];
            }
            break;
    }
}

- (void) audioSessionInterruptionNotification:(NSNotification *)notification {
    
    NSDictionary *interruptionDict = notification.userInfo;
    NSInteger interruptionType = [interruptionDict[AVAudioSessionInterruptionTypeKey] integerValue];
    
    switch (interruptionType) {
        case AVAudioSessionInterruptionTypeBegan:
            [self handleBeginInterruption];
            break;
            
        case AVAudioSessionInterruptionTypeEnded: {
            NSInteger option = [interruptionDict[AVAudioSessionInterruptionOptionKey] integerValue];
            [self handleEndInterruptionWithOption:option];
        }
            break;
            
        default:
            PLAYER_LOG(@"Triton Player - Audio Session Interruption Notification default case");
            break;
    }
}

- (void) audioSessionMediaServicesLostNotification:(NSNotification *) notification {
    NSLog(@"Media service lost");
}

- (void) audioSessionMediaServicesResetNotification:(NSNotification *) notification {
    NSLog(@"Media service reset");
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"outputVolume"]) {
    float vol = [[AVAudioSession sharedInstance] outputVolume];
        if(vol == 0.0) {
            [self pause];
            if([self state] == kTDPlayerStatePlaying){
                [self setVolumeStopped:YES];
            }
            
        } else if(vol > 0.0 && [self state] == kTDPlayerStateStopped && [self volumeStopped] == YES){
            [self play];
        }
    }
}

#pragma mark - Interruption handling

-(void)handleBeginInterruption {
    PLAYER_LOG(@"TritonPlayer received a begin interruption.");
    self.backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskIdentifier];
    }];

    self.playerWasInterrupted = YES;
    
    if ([self.delegate respondsToSelector:@selector(playerBeginInterruption:)]) {
        [self.delegate performSelector:@selector(playerBeginInterruption:) withObject:self];
    }
}

-(void)handleEndInterruptionWithOption:(NSInteger) option {
    PLAYER_LOG(@"TritonPlayer received an end interruption.");
    
    // Audio session was deactivated due to the interruption so activate it again
    NSError *activationError = nil;
    BOOL success = [[AVAudioSession sharedInstance] setActive:YES error:&activationError];
    
    if (!success) {
        PLAYER_LOG(@"Error activating session: %@", activationError.localizedDescription);
    }
    
    self.playerWasInterrupted = NO;

    self.shouldResumePlaybackAfterInterruption = option == AVAudioSessionInterruptionOptionShouldResume;
    
    if ([self.delegate respondsToSelector:@selector(playerEndInterruption:)]) {
        [self.delegate performSelector:@selector(playerEndInterruption:) withObject:self];
    }

    if (self.backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskIdentifier];
        self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    }
}

#pragma mark - Error handling

- (void)failWithError:(TDPlayerError) errorCode andDescription:(NSString*) description {
    // KVO will not be called, since FLVStream is not started, so change state manually
    self.isExecuting = FALSE;
    
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey : description};
    
    NSError *error = [NSError errorWithDomain:TritonPlayerDomain code:errorCode userInfo:userInfo];
    
    self.error = error;
    [self updateStateMachineForAction:kTDPlayerActionError];
}

#pragma mark - Private API for the StdApp

- (id)_addPeriodicTimeObserverForInterval:(CMTime)interval queue:(dispatch_queue_t)queue usingBlock:(void (^)(CMTime time))block {
    return [self.mediaPlayer addPeriodicTimeObserverForInterval:interval queue:queue usingBlock:block];
}

-(void)_removeTimeObserver:(id)observer {
    return [self.mediaPlayer removeTimeObserver:observer];
}


-(NSString*) getCastStreamingUrl
{
    if(self.mediaPlayer != nil)
    {
        if ([self.mediaPlayer isKindOfClass:[TDStationPlayer class]])
        {
           return [((TDStationPlayer*)self.mediaPlayer) getCastStreamingUrl];
        }
        else if ([self.mediaPlayer isKindOfClass:[TDStreamPlayer class]])
        {
           return [((TDStreamPlayer*)self.mediaPlayer) getStreamingUrl];
        }
    }
    
    return nil;
}

-(NSString*) getSideBandMetadataUrl
{
    if(self.mediaPlayer != nil)
    {
        if ([self.mediaPlayer isKindOfClass:[TDStationPlayer class]])
        {
            return [((TDStationPlayer*)self.mediaPlayer) getSideBandMetadataUrl];
        }
    }
    
    return nil;
}

@end
