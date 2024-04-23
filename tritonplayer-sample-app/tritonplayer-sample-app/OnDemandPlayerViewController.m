//
//  OnDemandPlayerViewController.m
//  tritonplayer-sample-app
//
//  Copyright (c) 2015 Triton Digital. All rights reserved.
//

#import "OnDemandPlayerViewController.h"

#import <TritonPlayerSDK/TritonPlayerSDK.h>

@interface OnDemandPlayerViewController()<TritonPlayerDelegate>

@property (weak, nonatomic) IBOutlet UITextField *urlLabel;
@property (weak, nonatomic) IBOutlet UILabel *playheadPositionLabel;
@property (weak, nonatomic) IBOutlet UILabel *durationLabel;
@property (weak, nonatomic) IBOutlet UISlider *seekBar;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIButton *playbackRateButton;
@property (weak, nonatomic) IBOutlet UITextView *metaData;
@property (nonatomic, assign) float rate;

@property (strong, nonatomic) TritonPlayer *tritonPlayer;

@property (strong, nonatomic) NSTimer *playheadTimer;

@end

@implementation OnDemandPlayerViewController

@synthesize rate;

-(void)viewDidLoad {
    [super viewDidLoad];
    self.rate = 1.0;
    self.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
    self.navigationItem.leftItemsSupplementBackButton = YES;
 //   NSURL *aURL = [[NSBundle mainBundle] URLForResource: @"Kalimba" withExtension:@"mp3"];
//    if(aURL != nil)
//    {
//        self.urlLabel.text = aURL.absoluteString;
//    }
//    else
    //self.urlLabel.text = @"https://ia802508.us.archive.org/5/items/testmp3testfile/mpthreetest.mp3";
    self.urlLabel.text = @"https://traffic.omny.fm/d/clips/803f1544-419a-4fea-962b-acdb0133575d/42e946b0-22b1-4abc-be4a-ad8800ff0e87/b822bcc2-62d4-4747-895a-adf900853119/audio.mp3?in_playlist=a2723fb4-b499-4776-967b-ad8800ff2a4f";
    self.tritonPlayer = [[TritonPlayer alloc] initWithDelegate:self andSettings:nil];
    
    self.statusLabel.text = @"Stopped";
		
    self.seekBar.continuous = NO;
    [self.seekBar addTarget:self action:@selector(seekBarValueChanged:) forControlEvents:UIControlEventValueChanged];
    self.seekBar.value = 0;
}

-(void)viewDidDisappear:(BOOL)animated {
    // Resign as first responder
    [self resignFirstResponder];
    
    [self.tritonPlayer stop];
    self.tritonPlayer = nil;
		
		self.metaData.text= @"";
    [super viewDidDisappear:animated];
}

-(void)dealloc {
    [self.playheadTimer invalidate];
}

- (void)seekBarValueChanged:(UISlider*)sender {
    [self.tritonPlayer seekToTimeInterval:sender.value * self.tritonPlayer.playbackDuration];
}

- (IBAction)seekBackwardsPressed:(id)sender {
    [self.tritonPlayer seekToTimeInterval:self.tritonPlayer.currentPlaybackTime - 10.0];
}

- (IBAction)seekForwardPressed:(id)sender {
    [self.tritonPlayer seekToTimeInterval:self.tritonPlayer.currentPlaybackTime + 10.0];
}

- (IBAction)playPressed:(id)sender {
    [self.tritonPlayer updateSettings:@{SettingsContentURLKey : self.urlLabel.text}];
    [self.tritonPlayer play];
}

- (IBAction)pausePressed:(id)sender {
    [self.tritonPlayer pause];
		self.metaData.text= @"";
}

- (IBAction)stopPressed:(id)sender {
    [self.tritonPlayer stop];
    [self.playbackRateButton setTitle:@"Playback Speed: (1.0X)" forState:UIControlStateNormal];
		self.metaData.text= @"";
}

#pragma mark - Playhead position timer

- (void)startPlayheadPositionTimer {
    if (!self.playheadTimer) {
        self.playheadTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(fireUpdate) userInfo:nil repeats:YES];
        [self.playheadTimer fire];
    }
}

- (void)stopPlayheadPositionTimer {
    [self.playheadTimer invalidate];
    self.playheadTimer = nil;
}

- (void)fireUpdate {
    self.seekBar.value = self.tritonPlayer.currentPlaybackTime / self.tritonPlayer.playbackDuration;
		
    self.playheadPositionLabel.text = [self stringFromTimeInterval:self.tritonPlayer.currentPlaybackTime];
}

-(NSString *)stringFromTimeInterval:(NSTimeInterval)interval {
    NSInteger ti = (NSInteger)interval;
    NSInteger seconds = ti % 60;
    NSInteger minutes = (ti / 60) % 60;
    NSInteger hours = (ti / 3600);
    return [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)hours, (long)minutes, (long)seconds];
}

#pragma mark - Triton Player Delegate methods

-(void)player:(TritonPlayer *)player didChangeState:(TDPlayerState)state {
    switch (state) {
        case kTDPlayerStateCompleted:
            self.statusLabel.text = @"Completed";
            break;
            
        case kTDPlayerStateConnecting:
            self.statusLabel.text = @"Connecting...";
            break;
            
        case kTDPlayerStateError: {
            NSError *error = player.error;
            self.statusLabel.text = @"Error";
            NSLog(@"Player Error: %@", error.localizedDescription);
            
            // Fire one more time so it updates the playhead position
            [self.playheadTimer fire];
            [self stopPlayheadPositionTimer];
        }
            break;
            
        case kTDPlayerStatePlaying:
            self.statusLabel.text = @"Playing";
            [self startPlayheadPositionTimer];
            break;
            
        case kTDPlayerStateStopped:
            self.statusLabel.text = @"Stopped";
            // Fire one more time so it updates the playhead position
            [self.playheadTimer fire];
            [self stopPlayheadPositionTimer];
            break;
        
        case kTDPlayerStatePaused:
            self.statusLabel.text = @"Paused";
            break;
            
        default:
            break;
    }
}

-(void)player:(TritonPlayer *)player didReceiveInfo:(TDPlayerInfo)info andExtra:(NSDictionary *)extra {
    
    switch (info) {
        case kTDPlayerInfoConnectedToStream:
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


-(void)player:(TritonPlayer *)player didReceiveMetaData: (NSDictionary *)metaData {
		NSLog(@"didReceiveMetaData : %@", metaData);
		NSString* data = @"";
		for( id key in metaData){
				NSString *md = [NSString stringWithFormat:@"%@ : %@\n", key, [metaData objectForKey:key] ];
				data = [data stringByAppendingString:md];
		}
		[self updateMedaDataView:data];
}

-(void)playerDidConnectToStream:(TritonPlayer *)player {
    self.statusLabel.text = @"Connected";
    self.durationLabel.text = [self stringFromTimeInterval:player.playbackDuration];
}

-(void)updateMedaDataView:(NSString*)metaData {
		self.metaData.text= metaData;
}

-(IBAction)showDropdownMenu:(id)sender {
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Playback Speed"] message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *option1Action = [UIAlertAction actionWithTitle:@"0.5X" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.rate = 0.5;
        [self.playbackRateButton setTitle:@"Playback Speed: (0.5X)" forState:UIControlStateNormal];
        [self.tritonPlayer changePlaybackRate:self.rate];
    }];
    [alertController addAction:option1Action];
    
    UIAlertAction *option2Action = [UIAlertAction actionWithTitle:@"1.0X" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.rate = 1.0;
        [self.playbackRateButton setTitle:@"Playback Speed: (1.0X)" forState:UIControlStateNormal];
        [self.tritonPlayer changePlaybackRate:self.rate];
    }];
    [alertController addAction:option2Action];
    
    UIAlertAction *option3Action = [UIAlertAction actionWithTitle:@"1.5X" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.rate = 1.5;
        [self.playbackRateButton setTitle:@"Playback Speed: (1.5X)" forState:UIControlStateNormal];
        [self.tritonPlayer changePlaybackRate:self.rate];
    }];
    [alertController addAction:option3Action];
    
    UIAlertAction *option4Action = [UIAlertAction actionWithTitle:@"2.0X" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.rate = 2.0;
        [self.playbackRateButton setTitle:@"Playback Speed: (2.0X)" forState:UIControlStateNormal];
        [self.tritonPlayer changePlaybackRate:self.rate];
    }];
    [alertController addAction:option4Action];
    
    [self presentViewController:alertController animated:YES completion:nil];
}
@end
