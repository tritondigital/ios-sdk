//
//  SBMPlayer.m
//  tritonplayer-sample-app-dev
//
//  Created by Carlos Pereira on 2015-03-24.
//  Copyright (c) 2015 Triton Digital. All rights reserved.
//

#import "SBMPlayerViewController.h"
#import "EmbeddedPlayerViewController.h"

#import <TritonPlayerSDK/TritonPlayerSDK.h>
#import <AVFoundation/AVFoundation.h>

#define kStreamURL @"http://1359.live.preprod01.streamtheworld.net:80/HLS_TEST_HLS"
#define kSBMURL @"http://1359.live.preprod01.streamtheworld.net:80/HLS_TEST_SBM"

@interface SBMPlayerViewController ()<TDSBMPlayerPlayerDelegate>

@property (strong, nonatomic) EmbeddedPlayerViewController *playerViewController;
@property (strong, nonatomic) TDSBMPlayer *sbmPlayer;

@property (strong, nonatomic) AVPlayer *mediaPlayer;
@property (strong, nonatomic) AVPlayerItem *mediaPlayerItem;
@end

@implementation SBMPlayerViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
    self.navigationItem.leftItemsSupplementBackButton = YES;
    
    self.playerViewController = self.childViewControllers.firstObject;
    self.playerViewController.mountName = @"HLS_TEST_SBM";
    
    __weak SBMPlayerViewController *weakSelf = self;
    self.playerViewController.playFiredBlock = ^(UIButton *button) {
        [weakSelf startPlaying];
    };
    self.playerViewController.stopFiredBlock = ^(UIButton *button) {
        [weakSelf stopPlaying];
    };
    
    [self configureAudioSession];
}

-(void)viewDidDisappear:(BOOL)animated {
    [self stopPlaying];
    
    [super viewDidDisappear:animated];
}

-(void)configureAudioSession {
    // Ensure AVAudioSession is initialized
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    NSError *setCategoryError = nil;
    BOOL success = [audioSession setCategory:AVAudioSessionCategoryPlayback error:&setCategoryError];
    
    if (!success) {
        NSLog(@"Error setting audio session category");
    }
    
    NSError *activationError = nil;
    success = [audioSession setActive:YES error:&activationError];
    
    if (!success) {
        NSLog(@"Error activating session");
    }
}

-(void)startPlaying {
    self.playerViewController.playerState = kEmbeddedStateConnecting;
    
    NSString *sbmSessionId = [TDSBMPlayer generateSBMSessionId];
    NSURL *streamUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@?sbmid=%@", kStreamURL, sbmSessionId]];
    NSURL *sbmUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@?sbmid=%@", kSBMURL, sbmSessionId]];
    
    self.sbmPlayer = [[TDSBMPlayer alloc] initWithSettings:@{SettingsSBMURLKey : sbmUrl}];
    self.sbmPlayer.delegate = self;
    
    self.mediaPlayerItem = [[AVPlayerItem alloc] initWithURL:streamUrl];
    [self.mediaPlayerItem addObserver:self forKeyPath:@"status" options:0 context:nil];
    
    self.mediaPlayer = [[AVPlayer alloc] initWithPlayerItem:self.mediaPlayerItem];

}

-(void)stopPlaying {
    if (self.mediaPlayer) {
        [self.mediaPlayerItem removeObserver:self forKeyPath:@"status"];
        [self.mediaPlayer pause];
        self.mediaPlayerItem = nil;
        self.mediaPlayer = nil;
        
        [self.sbmPlayer stop];
        
        self.playerViewController.playerState = kEmbeddedStateStopped;
    }
}

-(void)dealloc {
    [self.mediaPlayerItem removeObserver:self forKeyPath:@"status"];
}

#pragma mark - TDSBMPlayerDelegate

-(void)sbmPlayer:(TDSBMPlayer *)player didReceiveCuePointEvent:(CuePointEvent *)cuePointEvent {
    NSLog(@"Received CuePoint");

    [self.playerViewController loadCuePoint:cuePointEvent];
    
    // Update offset from player
    self.sbmPlayer.synchronizationOffset = self.sbmPlayer.currentPlaybackTime - CMTimeGetSeconds(self.mediaPlayer.currentTime);
}

-(void)sbmPlayer:(TDSBMPlayer *)player didFailConnectingWithError:(NSError *)error {
    [self.sbmPlayer close];
}

#pragma mark - KVO

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if ([keyPath isEqualToString:@"status"]) {
        switch (self.mediaPlayerItem.status) {
            case AVPlayerItemStatusReadyToPlay:
                
                [self.sbmPlayer play];
                [self.mediaPlayer play];
                
                self.playerViewController.playerState = kEmbeddedStatePlaying;
                break;
                
            case AVPlayerItemStatusFailed:
                NSLog(@"AVPlayerItemStatusFailed");
                
                [self stopPlaying];
                
                self.playerViewController.error = self.mediaPlayerItem.error;
                
                self.playerViewController.playerState = kEmbeddedStateError;
                break;
                
            default:
                break;
        }
    }
}

@end
