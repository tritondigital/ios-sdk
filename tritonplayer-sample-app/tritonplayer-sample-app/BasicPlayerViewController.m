//
//  BasicPlayerViewController.m
//  tritonplayer-sample-app
//
//  Copyright (c) 2014 Triton Digital. All rights reserved.
//

#import "BasicPlayerViewController.h"
#import "EmbeddedPlayerViewController.h"

#import <TritonPlayerSDK/TritonPlayerSDK.h>

/**
 This class shows how to create a basic radio application using TritonPlayer to play/stop a Triton stream, manage its lifecycle and receive stream metadata through cue points.
 It also shows how to display in-stream companion banners for displaying ads synchronized with the stream.
 */
@interface BasicPlayerViewController () <TritonPlayerDelegate, TDBannerViewDelegate>

@property (assign, nonatomic) BOOL interruptedOnPlayback;

@property (strong, nonatomic) TritonPlayer *tritonPlayer;

// A reusable view controller that implements a player interface with hooks for play, stop and loading ad banners
@property (strong, nonatomic) EmbeddedPlayerViewController *playerViewController;

@property (strong, nonatomic) NSString *cloudProgramId;
@end

@implementation BasicPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
    self.navigationItem.leftItemsSupplementBackButton = YES;

    // We will pass the settings when play is pressed
    self.tritonPlayer = [[TritonPlayer alloc] initWithDelegate:self andSettings:nil];
    
    // Get a reference to the reusable EmbeddedPlayerViewController
    self.playerViewController = self.childViewControllers.firstObject;
    self.playerViewController.playerState = kEmbeddedStateStopped;

    __weak BasicPlayerViewController *weakSelf = self;
    
    // Pass a block with the behavior for the play button
    self.playerViewController.playFiredBlock = ^(UIButton *button) {
        weakSelf.playerViewController.playerState = kEmbeddedStateConnecting;
        [weakSelf updateSettings];
        [weakSelf.tritonPlayer play];
    };
    
    // Do the same for the stop button
    self.playerViewController.stopFiredBlock = ^(UIButton *button) {
        [weakSelf.tritonPlayer stop];
    };
    
    // Do the same for the rewind button
    self.playerViewController.rewindFiredBlock = ^(UIButton *button) {
        NSLog(@"Current Time %f", weakSelf.tritonPlayer.currentPlaybackTime );
        [weakSelf.tritonPlayer seekToTimeInterval:weakSelf.tritonPlayer.currentPlaybackTime - 10.0];
    };
    
    // Do the same for the forward button
    self.playerViewController.forwardFiredBlock = ^(UIButton *button) {
        NSLog(@"Current Time %f", weakSelf.tritonPlayer.currentPlaybackTime );
        [weakSelf.tritonPlayer seekToTimeInterval:weakSelf.tritonPlayer.currentPlaybackTime + 10.0];
    };
    
    // Do the same for the live button
    self.playerViewController.liveFiredBlock = ^(UIButton *button) {
        NSLog(@"Current Time %f", weakSelf.tritonPlayer.currentPlaybackTime );
        //[weakSelf.tritonPlayer seekToTime:weakSelf.tritonPlayer.latestPlaybackTime];
    };
    
    // Do the same for the program button
    self.playerViewController.getCloudStreamInfoFiredBlock = ^(UIButton *button) {
        [weakSelf updateSettings];
        [weakSelf.tritonPlayer getCloudStreamInfo];
    };
    
    // Do the same for the timeshiftProgram button
    self.playerViewController.timeshiftProgramFiredBlock = ^(UIButton *button) {
        [weakSelf.tritonPlayer playCloudProgram:weakSelf.cloudProgramId];
    };
    
    // The initial mount
    self.playerViewController.mountName = @"TRITONRADIOMUSICAAC_RW";
}

-(void)viewDidDisappear:(BOOL)animated {
    [self.tritonPlayer stop];
    self.tritonPlayer = nil;
    
    [super viewDidDisappear:animated];
}

-(void)updateSettings {
    // Triton Player settings. You can test it with your own station configuration.
    NSDictionary *settings = @{SettingsStationNameKey : @"BASIC_CONFIG",
                               SettingsBroadcasterKey : @"Triton Digital",
                               SettingsMountKey : self.playerViewController.mountName,
                               SettingsEnableLocationTrackingKey : @(YES),
                               SettingsStreamParamsExtraKey : @{@"banners": @"300x50,320x50",
                                                                StreamParamExtraDist:@"the-dist",
                                                                StreamParamExtraDistTimeshift:@"timeshift-dist"
                                                                
                               },
                               SettingsTtagKey : @[@"mobile:ios", @"triton:sample"],
                               StreamParamExtraListenerIdType: @"idfa",
                               StreamParamExtraListenerIdValue: @"triton-app-id",
                               //SettingsTimeshiftEnabledKey: @(YES)
                               // @"ExtraForceDisableHLS" : @(NO)
                               //SettingsLowDelayKey: @"60"
                               };
    [self.tritonPlayer updateSettings:settings];
}


- (void)setTransport:(NSInteger)transport {
		switch (transport) {
				case PlayerContentTypeFLV:
						self.playerViewController.transport = kEmbeddedTransportMethodFLV;
						break;
						
				case PlayerContentTypeHLS:
						self.playerViewController.transport = kEmbeddedTransportMethodHLS;
						break;
				
				case PlayerContentTypeOther:
						self.playerViewController.transport = kEmbeddedTransportMethodOther;
						break;
						
				default:
						break;
		}
}



#pragma mark TritonPlayerDelegate methods

- (void)player:(TritonPlayer *)player didReceiveCuePointEvent:(CuePointEvent *)cuePointEvent {
    NSLog(@"Received CuePoint");
    
    [self.playerViewController loadCuePoint:cuePointEvent];
}

- (void)player:(TritonPlayer *)player didReceiveAnalyticsEvent:(AVPlayerItemAccessLogEvent *)analyticsEvent {
    NSLog(@"Received Analytics Event -- Indicated bitrate is %f", [analyticsEvent indicatedBitrate]);
}

- (void)player:(TritonPlayer *)player didReceiveCloudStreamInfoEvent:(NSDictionary *)cloudStreamInfoEvent {
    NSObject *programs = [cloudStreamInfoEvent valueForKey:@"programs"];
    if([programs isKindOfClass:[NSDictionary class]]){
        NSObject *properties = [(NSDictionary *)programs valueForKey:@"properties"];
        NSString *title = [(NSDictionary *)properties valueForKey:@"program_title"];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.playerViewController.btnTimeshiftProgram.enabled = YES;
            self.playerViewController.btnTimeshiftProgram.hidden = NO;
            [self.playerViewController.btnTimeshiftProgram setTitle:title forState:UIControlStateNormal];
            self.cloudProgramId = [(NSDictionary *)programs valueForKey:@"program_episode_id"];
         });
       
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.playerViewController.btnTimeshiftProgram.enabled = NO;
            self.playerViewController.btnTimeshiftProgram.hidden = NO;
            [self.playerViewController.btnTimeshiftProgram setTitle:@"No Programs" forState:UIControlStateNormal];
         });
    }
}

-(void)player:(TritonPlayer *)player didChangeState:(TDPlayerState)state {
    switch (state) {
        case kTDPlayerStateStopped:
            self.playerViewController.playerState = kEmbeddedStateStopped;
            break;
            
        case kTDPlayerStatePlaying:
            self.playerViewController.playerState = kEmbeddedStatePlaying;
            break;
				case kTDPlayerStateConnecting:
						self.playerViewController.playerState = kEmbeddedStateConnecting;
						break;
            
        case kTDPlayerStateError: {
            self.playerViewController.error = player.error;
            self.playerViewController.playerState = kEmbeddedStateError;
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
        self.playerViewController.playerState = kEmbeddedStatePlaying;
        
        self.interruptedOnPlayback = NO;
    }
}



@end
