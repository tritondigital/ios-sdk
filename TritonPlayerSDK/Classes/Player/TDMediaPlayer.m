//
//  HLSPlayer.m
//  FLVStreamPlayerLib64
//
//  Created by Carlos Pereira on 2014-10-15.
//
//
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <UIKit/UIKit.h>

#import "TDMediaPlayer.h"
#import "TDSBMPlayer.h"
#import "CuePointEvent.h"
#import "CuePointEventProtected.h"
#import "Logs.h"
#import "TritonPlayer.h"
#import "TritonPlayerConstants.h"

NSString *const SettingsMediaPlayerUserAgentKey = @"MediaPlayerUserAgent";
NSString *const SettingsMediaPlayerSBMURLKey = @"MediaPlayerSBMURL";
NSString *const SettingsMediaPlayerStreamURLKey = @"MediaPlayerStreamURL";

@interface TDMediaPlayer () <TDSBMPlayerPlayerDelegate>

// Audio Player
@property (nonatomic, strong) AVPlayer *mediaPlayer;
@property (nonatomic, strong) AVPlayerItem *mediaPlayerItem;

// URL details
@property (nonatomic, strong) NSString *streamURL;
@property (nonatomic, strong) NSString *mountName;
@property (nonatomic, strong) NSString *queryParameters;
@property (nonatomic, copy) NSString *userAgent;

// Side-Band Metadata
@property (nonatomic, strong) TDSBMPlayer *sbmPlayer;
@property (nonatomic, strong) NSString *sidebandMetadataSessionId;
@property (nonatomic, copy) NSString *sidebandMetadataURL;

@property (nonatomic, strong) id timeObserver;
@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundTaskIdentifier;

@property (nonatomic, assign) TDPlayerState state;

@end

@implementation TDMediaPlayer

@synthesize currentPlaybackTime;
@synthesize playbackDuration;
@synthesize delegate;
@synthesize error = _error;

-(instancetype)init {
    return [self initWithSettings:nil];
}

-(instancetype)initWithSettings:(NSDictionary *)settings {
    self = [super init];
    
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemAccessLogEntryAddedNotification:)
                                                     name:AVPlayerItemNewAccessLogEntryNotification
                                                   object:_mediaPlayerItem];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemAccessErrorLogEntryAddedNotification:)
                                                     name:AVPlayerItemNewErrorLogEntryNotification
                                                   object:_mediaPlayerItem];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidPlayToEndNotification:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:_mediaPlayerItem];
        
        self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        
        [self updateSettings:settings];
        
        self.state = kTDPlayerStateStopped;
    }
    
    return self;

}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if(observersAdded)
    {
        @try
        {
        [self.mediaPlayerItem removeObserver:self forKeyPath:@"status"];
        [self.mediaPlayerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
            observersAdded = NO;
        }
        @catch (id anException) {
            PLAYER_LOG(@"Observers already removed");
        }
    }    
}

-(void)updateSettings:(NSDictionary *)settings {
    if (settings)
    {
       self.streamURL = settings[SettingsMediaPlayerStreamURLKey];
       self.sidebandMetadataURL = settings[SettingsMediaPlayerSBMURLKey];

        if ([self.sidebandMetadataURL isEqualToString:@""]) {
          self.sidebandMetadataURL = nil;
    }
    
       self.userAgent = settings[SettingsMediaPlayerUserAgentKey];
        
        //Always reset this
        self.sidebandMetadataSessionId = nil;
    }
}

#pragma mark - Media properties

-(NSTimeInterval)currentPlaybackTime {
    CMTime currentTime = self.mediaPlayer.currentTime;
    
    if (CMTIME_IS_INVALID(currentTime)) {
        return  -1;
    }
    
    return CMTimeGetSeconds(self.mediaPlayer.currentTime);
}

-(NSTimeInterval)playbackDuration {
    CMTime duration = self.mediaPlayer.currentItem.duration;
    
    if (CMTIME_IS_INVALID(duration)) {
        return -1;
    }
    
    return CMTimeGetSeconds(self.mediaPlayer.currentItem.duration);
}

#pragma mark - Reproduction flow

-(void)play {
    
    if ([self canChangeStateWithAction:kTDPlayerActionPlay]) {
        
        TDPlayerState lastState = self.state;
        
        [self updateStateMachineForAction:kTDPlayerActionPlay];
        
        if (lastState == kTDPlayerStatePaused) {
            [self addMediaPlayerItemObservers];
            [self.mediaPlayer play];
            
            // Advance state machine to playing
            if(self.mediaPlayerItem.status == AVPlayerItemStatusReadyToPlay)
              [self updateStateMachineForAction:kTDPlayerActionJumpToNextState];
            
        } else {
            
            if (self.sidebandMetadataURL) {
                // Create and prepare SBM Player but only start it when the stream starts playing.
                
                self.sidebandMetadataSessionId = [TDSBMPlayer generateSBMSessionId];
                
                NSURL *sbmUrl = [self createURLWithSbmIdFromString:self.sidebandMetadataURL];
                self.sbmPlayer = [[TDSBMPlayer alloc] initWithSettings:@{SettingsSBMURLKey : sbmUrl}];
                
                // We will synchronize the cue points manually.
                self.sbmPlayer.autoSynchronizeCuePoints = NO;
                
                self.sbmPlayer.delegate = self;
            }
            
            NSURL *streamURL = nil;
            
            if (self.sidebandMetadataSessionId) {
                streamURL = [self createURLWithSbmIdFromString:self.streamURL];
                
            } else {
                streamURL = [NSURL URLWithString:self.streamURL];
            }
            
            self.mediaPlayerItem = [[AVPlayerItem alloc] initWithURL:streamURL];
            [self addMediaPlayerItemObservers];
            
            self.mediaPlayer = [[AVPlayer alloc] initWithPlayerItem:self.mediaPlayerItem];
        }
        
        
    }
}

-(void)stop {
        if (self.mediaPlayer) {
            
            [self.sbmPlayer stop];
            self.sbmPlayer = nil;
            
            [self.mediaPlayer pause];
            [self removeMediaPlayerItemObservers];

            self.mediaPlayerItem = nil;
            self.mediaPlayer = nil;
            
            [self updateStateMachineForAction:kTDPlayerActionStop];

            @try
            {
                if (self.timeObserver) {
                    [self.mediaPlayer removeTimeObserver:self.timeObserver];
                    self.timeObserver = nil;
                }
            }
            @catch(id exception)
            {
                //we do nothing; not the correct observer that was added
            }
        }
}

-(void)pause {
    [self.mediaPlayer pause];
    [self removeMediaPlayerItemObservers];
    [self updateStateMachineForAction:kTDPlayerActionPause];
}

BOOL observersAdded= NO;
-(void) addMediaPlayerItemObservers
{
    if(!observersAdded && self.mediaPlayerItem != nil)
    {
        [self.mediaPlayerItem addObserver:self forKeyPath:@"status" options:0 context:nil];
        [self.mediaPlayerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:0 context:nil];
        [self.mediaPlayerItem addObserver:self forKeyPath:@"playbackBufferFull" options:0 context:nil];
       [self.mediaPlayerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:0 context:nil];
        [self.mediaPlayerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
        observersAdded = YES;
    }
}

-(void) removeMediaPlayerItemObservers
{
    if(observersAdded && self.mediaPlayerItem != nil)
    {
        @try
        {
            [self.mediaPlayerItem removeObserver:self forKeyPath:@"status"];
            [self.mediaPlayerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
            [self.mediaPlayerItem removeObserver:self forKeyPath:@"playbackBufferFull"];
            [self.mediaPlayerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
            [self.mediaPlayerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
            observersAdded = NO;
        }
        @catch (id anException) {
            PLAYER_LOG(@"Observers already removed");
        }
    }
}

-(void)seekToTimeInterval:(NSTimeInterval)interval {
    [self.mediaPlayer seekToTime:CMTimeMake(interval, 1)];
}

-(void)seekToTime:(CMTime)time completionHandler:(void (^)(BOOL))completionHandler {
    [self.mediaPlayer seekToTime:time completionHandler:completionHandler];
}

-(void)mute {
    self.mediaPlayer.muted = YES;
}

-(void)unmute {
    self.mediaPlayer.muted = NO;
}

-(void)setVolume:(float)volume {
    self.mediaPlayer.volume = volume;
}

-(NSURL*)createURLWithSbmIdFromString:(NSString *)string {
    // Append the sbmid query parameter using NSURLComponents just to be sure that if there's another query parameter in the future, things will always work.
    // When iOS 8 will be the the target version, use queryItems instead of query property.
    
    NSURLComponents *components = [NSURLComponents componentsWithString:string];
    
    NSString *queryString = [NSString stringWithFormat:@"sbmid=%@", self.sidebandMetadataSessionId];
    
    if (components.query) {
        components.query = [components.query stringByAppendingFormat:@"&%@", queryString];
        
    } else {
        components.query = queryString;
    }
    
    return components.URL;
}

-(void)setBaseURL:(NSString *)baseURL andMountName:(NSString *)mountName andQueryParameters:(NSString *)queryParameters {
    self.streamURL = baseURL;
    self.mountName = mountName;
    self.queryParameters = queryParameters;
}

#pragma mark - Timed observations

- (id)addPeriodicTimeObserverForInterval:(CMTime)interval
                                   queue:(dispatch_queue_t)queue
                              usingBlock:(void (^)(CMTime))block {
    
    return [self.mediaPlayer addPeriodicTimeObserverForInterval:interval queue:queue usingBlock:block];
}

- (void)removeTimeObserver:(id)observer {
    [self.mediaPlayer removeTimeObserver:observer];
}

#pragma mark - KVO
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if ([keyPath isEqualToString:@"status"]) {
        switch (self.mediaPlayerItem.status) {
            case AVPlayerItemStatusReadyToPlay:
                if ([self.delegate respondsToSelector:@selector(mediaPlayer:didReceiveInfo:andExtra:)]) {
                    [self.delegate mediaPlayer:self didReceiveInfo:kTDPlayerInfoConnectedToStream andExtra:nil];
                }
                
                if (self.backgroundTaskIdentifier != UIBackgroundTaskInvalid){
                    [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskIdentifier];
                    self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
                }
            
                // Start sideband metadata if enabled
                if (self.sidebandMetadataURL) {
                    [self.sbmPlayer play];
                }
                [self.mediaPlayer play];
                
                // Move state machine to play state
                 [self updateStateMachineForAction:kTDPlayerActionPlay];
                break;
                
            case AVPlayerItemStatusFailed:
                PLAYER_LOG(@"AVPlayerItemStatusFailed");
                
                self.error = self.mediaPlayer.error;
                [self updateStateMachineForAction:kTDPlayerActionError];
                break;
            
            default:
                break;
        }
    }
    
    else if ([keyPath isEqualToString:@"loadedTimeRanges"])
    {
        NSTimeInterval timeInterval = [self availableDuration];// Calculation of buffer progress
        
        //PLAYER_LOG(@"Buffering ... timeInterval:%f",timeInterval);
        if ([self.delegate respondsToSelector:@selector(mediaPlayer:didReceiveInfo:andExtra:)]) {
            [self.delegate mediaPlayer:self didReceiveInfo:kTDPlayerInfoBuffering andExtra:nil];
        }
    }
    else if ([keyPath isEqualToString:@"playbackBufferFull"] || [keyPath isEqualToString:@"playbackLikelyToKeepUp"] )
    {
        PLAYER_LOG(@"Buffering completed");
        if( self.state == kTDPlayerStateConnecting)
        {
            BOOL isFromNetwork = ([self.streamURL containsString:@"http://"] || [self.streamURL containsString:@"https://"]);
            
            BOOL isNotFailed   = self.mediaPlayerItem.status != AVPlayerItemStatusFailed;
            BOOL isReadyToPlay = self.mediaPlayerItem.status == AVPlayerItemStatusReadyToPlay;
            if((!isFromNetwork && isNotFailed) || (isReadyToPlay && isFromNetwork))
            {
                // Move state machine to play state
                [self updateStateMachineForAction:kTDPlayerActionJumpToNextState];
            }
        }
    }
    else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
        if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){.majorVersion = 10, .minorVersion = 0, .patchVersion = 0}]) {
            
            // Move state machine to play state
            if (self.sidebandMetadataURL != nil) //live streaming
            {
              [self updateStateMachineForAction:kTDPlayerActionJumpToNextState];
            }
            
            BOOL pSEmpty = self.mediaPlayerItem.playbackBufferEmpty;
            BOOL pSKeepUp = self.mediaPlayerItem.playbackLikelyToKeepUp;
            AVPlayerItemStatus s = self.mediaPlayerItem.status;
            if(s == AVPlayerItemStatusReadyToPlay && pSEmpty && !pSKeepUp)
            {
                self.backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
                    [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskIdentifier];
                }];
                
                PLAYER_LOG(@"playbackBufferEmpty");
                [self closeWhenConnectionDropped];
            }
        }
        else
        {
            if (!self.mediaPlayerItem.playbackLikelyToKeepUp) {
                self.backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
                    [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskIdentifier];
                }];
                
                PLAYER_LOG(@"playbackBufferEmpty");
                [self closeWhenConnectionDropped];
            }
        }
    }
}

#pragma mark - MetadataPlayer delegate

-(void)sbmPlayer:(TDSBMPlayer *)player didReceiveCuePointEvent:(CuePointEvent *)cuePointEvent {
    
    // Synchronize cuePoints with the playing stream before sending it to the delegate. We use the cuePoint timestamp propery to
    // set a time observer in the AVPlayer. The first cuePoint received should be sent immediatelly (timestamp == 0)
    
    __weak TDMediaPlayer *weakSelf = self;
    void (^observerBlock)() = ^{
        if ([weakSelf.delegate respondsToSelector:@selector(mediaPlayer:didReceiveCuepointEvent:)]) {
            [weakSelf.delegate performSelector:@selector(mediaPlayer:didReceiveCuepointEvent:) withObject:weakSelf withObject:cuePointEvent];    
        }
    };
    
    CMTime targetTime = CMTimeMake(cuePointEvent.timestamp, 1000);
    
    //TimeObserver in the AVPlayer were not working properly for some HLS streams, that why the following lines were commented. Insted we use a dispatch_after to sync the cue-points
   
    if (CMTimeCompare(targetTime, kCMTimeZero) > 0) {
        self.timeObserver = [self.mediaPlayer addBoundaryTimeObserverForTimes:@[[NSValue valueWithCMTime:targetTime]] queue:dispatch_get_main_queue() usingBlock:observerBlock];
    
    } else {
        if ([weakSelf.delegate respondsToSelector:@selector(mediaPlayer:didReceiveCuepointEvent:)]) {
            [weakSelf.delegate performSelector:@selector(mediaPlayer:didReceiveCuepointEvent:) withObject:weakSelf withObject:cuePointEvent];
        }
    }
    
//    NSTimeInterval targetInterval = targetTime.value / targetTime.timescale;
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, targetInterval * NSEC_PER_MSEC), dispatch_get_main_queue(), observerBlock);
    
    if(cuePointEvent.data != nil) PLAYER_LOG(@"didReceiveCuePointEvent with data: %@", cuePointEvent.data);
    PLAYER_LOG(@"didReceiveCuePointEvent with target time: %lld", targetTime.value / targetTime.timescale);
}

-(void)sbmPlayer:(TDSBMPlayer *)player didFailConnectingWithError:(NSError *)error {
    PLAYER_LOG(@"didFailConnectingWithError");
    // For the moment, nothing to do. The metadata player already tried to reconnect without success. The next time the user does stop and play, it will try to reconnect.
    [self.sbmPlayer close];
}

#pragma mark - Notifications

- (void)removeListeners {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)playerItemAccessLogEntryAddedNotification:(NSNotification *)notification {
    PLAYER_LOG(@"playerItemAccessLogEntryAddedNotification");
    AVPlayerItem *thisItem = self.mediaPlayer.currentItem;
    
    for (AVPlayerItemAccessLogEvent *event  in [[thisItem accessLog] events]) {
        PLAYER_LOG(@"indicated bitrate is %f", [event indicatedBitrate]);
        PLAYER_LOG(@"observerd bitrate is %f", [event observedBitrate]);
        PLAYER_LOG(@"server address is %@", [event serverAddress]);
        PLAYER_LOG(@"playbackSessionID is %@", [event playbackSessionID]);

        if ([[event URI] length])
        {
            PLAYER_LOG(@"AVPlayer URI is %@", [event URI]);
        }
    }
}

- (void)playerItemAccessErrorLogEntryAddedNotification:(NSNotification *)notification {
    PLAYER_LOG(@"playerItemAccessErrorLogEntryAddedNotification");
    AVPlayerItem *thisItem = self.mediaPlayer.currentItem;
    long errorStatusCode = NSURLErrorUnknown;
    NSString* errorDomain=nil;
   
    for (AVPlayerItemErrorLogEvent *event  in [[thisItem errorLog] events]) {
        errorStatusCode =    (long)[event errorStatusCode];
        errorDomain     =    [event errorDomain];
        PLAYER_LOG(@"AVPlayer errorStatusCode is %ld", errorStatusCode);
        PLAYER_LOG(@"AVPlayer errorComment is %@", [event errorComment]);
        PLAYER_LOG(@"AVPlayer errorDomain is %@", errorDomain);
        PLAYER_LOG(@"AVPlayer server address is %@", [event serverAddress]);
        if ([[event URI] length])
        {
            PLAYER_LOG(@"AVPlayer URI is %@", [event URI]);
        }
    }
    
    BOOL connectionDropped = (errorStatusCode == NSURLErrorCannotFindHost         ||
                              errorStatusCode == NSURLErrorCannotConnectToHost    ||
                              errorStatusCode == NSURLErrorNetworkConnectionLost  ||
                              errorStatusCode == NSURLErrorResourceUnavailable    ||
                              errorStatusCode == NSURLErrorNotConnectedToInternet );
    if(connectionDropped && ([NSURLErrorDomain isEqualToString:errorDomain]) )
    {
        [self closeWhenConnectionDropped];
    }
}

- (void)playerItemDidPlayToEndNotification:(NSNotification *)notification {
    PLAYER_LOG(@"playerItemDidPlayToEndNotification");
    [self updateStateMachineForAction:kTDPlayerActionJumpToNextState];
    
    self.backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskIdentifier];
    }];
    
    [self stop];
    [self.sbmPlayer close];
    
    // Go to completed
}


-(void)secondaryAudioNotification:(NSNotification *)notification {
    NSDictionary *secondaryAudio = notification.userInfo;
    NSInteger hint = [secondaryAudio[AVAudioSessionSilenceSecondaryAudioHintTypeKey] integerValue];
    
    switch (hint) {
        case AVAudioSessionSilenceSecondaryAudioHintTypeBegin:
            PLAYER_LOG(@"Secondary audio begin");
            break;
            
        case AVAudioSessionSilenceSecondaryAudioHintTypeEnd:
            PLAYER_LOG(@"Secondary audio end");
            break;
            
        default:
            break;
    }
}

-(void) closeWhenConnectionDropped
{
    // Connection is about to drop
    [self stop];
    [self.sbmPlayer close];
    
    NSError *error = [NSError errorWithDomain:TritonPlayerDomain code:TDPlayerHostNotFoundError userInfo:nil];
    self.error = error;
    [self updateStateMachineForAction:kTDPlayerActionError];
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
                
            } else if ((self.state == kTDPlayerStatePlaying) &&  (!self.sidebandMetadataSessionId)) {
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


- (NSTimeInterval)availableDuration {
    NSArray *loadedTimeRanges = [[self.mediaPlayer currentItem] loadedTimeRanges];
    CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];// Gets the buffer area
    float startSeconds = CMTimeGetSeconds(timeRange.start);
    float durationSeconds = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result = startSeconds + durationSeconds;// Calculate the total schedule buffer
    return result;
}

@end
