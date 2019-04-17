
#import "MultiStationViewController.h"

@interface MultiStationViewController ()<TritonPlayerDelegate, UITextFieldDelegate>
@property (nonatomic, strong) TritonPlayer *tritonPlayer;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIButton *btnPlay;
@property (weak, nonatomic) IBOutlet UIButton *btnStop;
@property (weak, nonatomic) IBOutlet UIButton *btnNext;
@property (weak, nonatomic) IBOutlet UIButton *btnPrevious;
@property (weak, nonatomic) IBOutlet UISwitch *btnHLS;

@property (weak, nonatomic) IBOutlet UILabel *labelCuePointType;

@property (weak, nonatomic) IBOutlet UILabel *labelTitle;
@property (weak, nonatomic) IBOutlet UILabel *labelArtist;
@property (weak, nonatomic) IBOutlet UILabel *labelAlbum;
@property (weak, nonatomic) IBOutlet UILabel *station;

@property (weak, nonatomic) IBOutlet UILabel *labelPlayerState;

@property (weak, nonatomic) IBOutlet UILabel *labelTransport;
@property (weak, nonatomic) IBOutlet UILabel *labelConnectionTime;

@property (weak, nonatomic) IBOutlet UIButton *stationsScanner;

@property (assign, nonatomic) BOOL interruptedOnPlayback;

@property (nonatomic, assign) int currentIndex;

@end

@implementation MultiStationViewController

NSDate* startTimer;
NSDate* endTimer;
BOOL scanningStations;
NSTimer* scanTimer;

int loadStationsCount;

-(void)viewDidLoad {
		
		
		
		self.activityIndicator.hidden = YES;
		self.tritonPlayer = [[TritonPlayer alloc] initWithDelegate:self andSettings:nil];

    self.stationFLVList = [NSArray arrayWithObjects:
                           @"MOBILEFM_AACV2",
                           @"MOBILEFM_AACV1",
                           @"S1_FLV_AAC",
                           @"S1_FLV_MP3",
                           @"S2_FLV_AAC",
                           @"S2_FLV_MP3",
                           @"S3_FLV_MP3",
                           @"S4_FLV_AAC",
                           
                           nil];
    
    self.stationHLSList = [NSArray arrayWithObjects:
                           @"TRITONRADIOMUSICAAC",
                           @"TEST_ST04AAC",
                           @"S1_HLS_AAC",
                           @"S5_HLS_AAC",
                           nil];
		
		
		[super viewDidLoad];
		[self.btnHLS  setOn:NO];
		self.btnPrevious.enabled = NO;
		self.btnNext.enabled = NO;
		self.btnStop.enabled = NO;
}

-(void)viewDidAppear:(BOOL)animated {
		[super viewDidAppear:animated];
		
		// Turn on remote control event delivery
		[[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
		
		// Set itself as the first responder
		[self becomeFirstResponder];
}

-(void)viewDidDisappear:(BOOL)animated {
		// Turn off remote control event delivery
		[[UIApplication sharedApplication] endReceivingRemoteControlEvents];
		
		[self.tritonPlayer stop];
		self.tritonPlayer = nil;                                                                                   
		
		// Resign as first responder
		[self resignFirstResponder];
		
		[super viewDidDisappear:animated];
}

- (void)reset {
		[self clearLabels];
		[self.activityIndicator stopAnimating];
		self.activityIndicator.hidden = YES;
		
		self.btnPlay.enabled = YES;
}

- (void) clearLabels {
		self.labelTitle.text = @"";
		self.labelArtist.text = @"";
		self.labelAlbum.text = @"";
		self.labelCuePointType.text = @"";
}

- (IBAction)playButtonPressed:(id)sender  {
		_playingStation =[self getStation:@"current"];
		[self  play];
}

- (IBAction)stopButtonPressed:(id)sender {
		[self.tritonPlayer stop];
    
    if(scanTimer)
    {
        [scanTimer invalidate];
        scanningStations= NO;
    }
}

- (IBAction)nextButtonPressed:(id)sender {
		_playingStation =[self getStation:@"next"];
		[self  play];
}

- (IBAction)previousButtonPressed:(id)sender {
		_playingStation =[self getStation:@"previous"];
		[self  play];
}

- (IBAction)scanButtonPressed:(id)sender {
  if(!scanningStations)
  {
      [self playButtonPressed:nil];
      scanTimer = [NSTimer scheduledTimerWithTimeInterval: 10.0 target: self  selector: @selector(scan) userInfo: nil repeats: YES];
      scanningStations= YES;
  }
  else
  {
      if(scanTimer)
      {
          [scanTimer invalidate];
          scanningStations= NO;
      }
  }
}

-(void) scan
{
    [self nextButtonPressed:nil];
}


- (IBAction)HLSSwitchOn:(id)sender{
		[self.tritonPlayer stop];
		self.station.text = @"";
		_currentIndex = 0;
    
    if(scanTimer)
    {
        [scanTimer invalidate];
        scanningStations= NO;
    }
}

-(void) play {
		startTimer =  [NSDate date];
		NSDictionary *settings = @{SettingsEnableLocationTrackingKey: @(YES),
															 SettingsStationNameKey : _playingStation,
															 SettingsMountKey : _playingStation,
															 SettingsTtagKey : @[@"mobile:ios"],
															 SettingsBroadcasterKey : @"TritonDigital",
															 @"ExtraForceDisableHLS" : @(NO),
															 };
		
		[self.tritonPlayer updateSettings:settings];
		self.station.text = _playingStation;
		self.playerState = kEmbeddedStateConnecting;
		[self.tritonPlayer play];
}


-(NSString*) getStation:(NSString*)order
{
		
		if( [self.btnHLS isOn]){
				stationList = _stationHLSList;
		}else{
				stationList = _stationFLVList;
		}
		
		if([order  isEqual: @"previous"]){
				_currentIndex = (_currentIndex - 1) % [stationList count];
		}else if ([order  isEqual: @"next"]){
				_currentIndex = (_currentIndex + 1) % [stationList count];
		}else{
				_currentIndex = (_currentIndex ) % [stationList count];
		}
		
		
		return [stationList objectAtIndex:_currentIndex];
}


#pragma mark - Receiving and processing stream metadata

-(void)loadCuePoint:(CuePointEvent *)cuePoint {
		[self clearLabels];
		
		if (cuePoint.data) {
				
				self.labelCuePointType.text = cuePoint.type;
				
				if ([cuePoint.type isEqualToString:EventTypeAd])
				{
						NSLog(@"Received Ad CuePoint");
						[self executeAdsEvent:cuePoint];
				}
				else if ([cuePoint.type isEqualToString:EventTypeTrack])
				{
						NSLog(@"Received NowPlaying CuePoint");
						
						[self executeNowPlayingEvent:cuePoint];
				}
		}
}

- (void)executeNowPlayingEvent:(CuePointEvent *)inNowPlayingEvent {
		if (!inNowPlayingEvent.executionCanceled) {
				NSString *songTitle = [inNowPlayingEvent.data objectForKey:CommonCueTitleKey];
				NSString *artistName = [inNowPlayingEvent.data objectForKey:TrackArtistNameKey];
				NSString *albumName = [inNowPlayingEvent.data objectForKey:TrackAlbumNameKey];
				
				self.labelTitle.text = [songTitle capitalizedString];
				self.labelArtist.text = [artistName capitalizedString];
				self.labelAlbum.text = [albumName capitalizedString];
		}
}

- (void)executeAdsEvent:(CuePointEvent *) adCuePointEvent {
		self.labelTitle.text = [adCuePointEvent.data objectForKey:CommonCueTitleKey];
}

-(void)setPlayerState:(EmbeddedPlayerState)playerState {
		
		switch (playerState) {
				case kEmbeddedStateConnecting:
						self.labelPlayerState.text = @"Connecting to station...";
						self.btnPlay.enabled = NO;
						break;
						
				case kEmbeddedStatePlaying:
						self.labelPlayerState.text = @"Playing";
						self.btnStop.enabled = YES;
						self.btnPlay.enabled = NO;
						self.btnNext.enabled = YES;
						self.btnPrevious.enabled = YES;

						endTimer =  [NSDate date];
						int totalTime =   [endTimer timeIntervalSinceDate:startTimer] * 1000.0f;
						self.labelConnectionTime.text = [NSString stringWithFormat:@"%i%@", totalTime, @" ms" ];
						
						break;

				case kEmbeddedStateStopped:
						self.labelPlayerState.text = @"Stopped";
						self.labelConnectionTime.text =@"";
						self.labelTransport.text = @"";
						[self reset];
						break;
						
				case kEmbeddedStateError:
						self.labelPlayerState.text = [NSString stringWithFormat:@"Error %ld - %@", (long)self.error.code, self.error.localizedDescription];
						[self reset];
						break;
						
				default:
						return;
		}
		
		_playerState = playerState;
}

-(void)setTransport:(EmbeddedTransportMethod)transport {
		
		switch (transport) {
				case kEmbeddedTransportMethodFLV:
						self.labelTransport.text = @"FLV";
						break;
						
				case kEmbeddedTransportMethodHLS:
						self.labelTransport.text = @"HLS";
						break;
						
				case kEmbeddedTransportMethodOther:
						self.labelTransport.text = @"Other";
						break;
						
				default:
						return;
		}
		
		_transport = transport;
}


#pragma mark Remote Control Events

- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent {
		
		if (receivedEvent.type == UIEventTypeRemoteControl) {
				
				switch (receivedEvent.subtype) {
								
						case UIEventSubtypeRemoteControlTogglePlayPause:
								if (self.playerState == kEmbeddedStatePlaying) {
										[self stopButtonPressed:nil];
										
								} else {
										[self playButtonPressed:nil];
								}
								break;
								
						case UIEventSubtypeRemoteControlPause:
								[self stopButtonPressed:nil];
								break;
								
						case UIEventSubtypeRemoteControlPlay:
								[self playButtonPressed:nil];
								break;
								
						default:
								break;
				}
		}
}

#pragma mark - UITextFieldDelegate methods

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
		[textField resignFirstResponder];
		[textField invalidateIntrinsicContentSize];
		return YES;
}

#pragma mark - Reproduction flow

-(void)seekToTime:(CMTime)time completionHandler:(void (^)(BOOL))completionHandler {
		[self.tritonPlayer seekToTime:time completionHandler:completionHandler];
}

-(NSTimeInterval)playbackDuration {
		return self.tritonPlayer.playbackDuration;
}

-(NSTimeInterval)currentPlaybackTime {
		return self.tritonPlayer.currentPlaybackTime;
}


#pragma mark TritonPlayerDelegate methods

- (void)player:(TritonPlayer *)player didReceiveCuePointEvent:(CuePointEvent *)cuePointEvent {
		NSLog(@"Received CuePoint");
		
		[self loadCuePoint:cuePointEvent];
}

-(void)player:(TritonPlayer *)player didChangeState:(TDPlayerState)state {
		switch (state) {
				case kTDPlayerStateStopped:
						self.playerState = kEmbeddedStateStopped;
						break;
						
				case kTDPlayerStatePlaying:
						self.playerState = kEmbeddedStatePlaying;
						break;
						
				case kTDPlayerStateConnecting:
						self.playerState = kEmbeddedStateConnecting;
						break;
						
				case kTDPlayerStateError: {
						self.error = player.error;
						self.playerState = kEmbeddedStateError;
				}
						break;
				default:
						break;
		}
}

-(void)player:(TritonPlayer *)player didReceiveInfo:(TDPlayerInfo)info andExtra:(NSDictionary *)extra {
		
		switch (info) {
				case kTDPlayerInfoConnectedToStream:
						if( [extra objectForKey:@"transport"] ){
								NSInteger transport = [[extra objectForKey:@"transport"] intValue];
								[self setTransport: transport];
						}
						NSLog(@"Connected to stream");
						break;
						
				case kTDPlayerInfoBuffering:
						NSLog(@"Buffering %@%%...", extra[InfoBufferingPercentageKey]);
						break;
						
				case kTDPlayerInfoForwardedToAlternateMount:
						NSLog(@"Forwarded to an alternate mount: %@", extra[InfoAlternateMountNameKey]);
						break;
		}
}

- (void)playerBeginInterruption:(TritonPlayer *) player {
		NSLog(@"playerBeginInterruption");
		if ([self.tritonPlayer isExecuting]) {
				[self.tritonPlayer stop];
				self.interruptedOnPlayback = YES;
		}
}

- (void)playerEndInterruption:(TritonPlayer *) player {
		NSLog(@"playerEndInterruption");
		if (self.interruptedOnPlayback && player.shouldResumePlaybackAfterInterruption) {
				
				// Resume stream
				[self.tritonPlayer play];
				self.playerState = kEmbeddedStatePlaying;
				
				self.interruptedOnPlayback = NO;
		}
}



#pragma mark - Reproduction flow


#pragma mark - Notifications

-(void)onAudioPlayerStateRequestNotification:(NSNotification*)notification {
		
}

-(void)sendAudioPlayerPlayingNotification {
		
}

-(void)onAudioPlaybackStopRequestNotification:(NSNotification*)notification {
		
}

@end
