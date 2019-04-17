//
//  CustomAdsViewController.m
//  tritonplayer-sample-app-dev
//
//  Copyright (c) 2015 Triton Digital. All rights reserved.
//

#import "CustomAdsViewController.h"
#import "InterstitialViewController.h"

#import <MediaPlayer/MediaPlayer.h>
#import <TritonPlayerSDK/TritonPlayerSDK.h>
#import <AVFoundation/AVFoundation.h>


@interface CustomAdsViewController ()<UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UILabel *statusMessageLabel;
@property (weak, nonatomic) IBOutlet UIButton *loadAudioButton;
@property (weak, nonatomic) IBOutlet UIButton *loadVideoButton;
@property (weak, nonatomic) IBOutlet UIButton *playButton;

@property (strong, nonatomic) MPMoviePlayerViewController *moviePlayerViewController;
@property (strong, nonatomic) AVPlayer *audioPlayer;

@property (strong, nonatomic) TDAdLoader *adLoader;
@property (strong, nonatomic) TDAdRequestURLBuilder *requestBuilder;
@property (strong, nonatomic) TDAd *ad;
@property (strong, nonatomic) TDBannerView *bannerView;

@end

@implementation CustomAdsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
    self.navigationItem.leftItemsSupplementBackButton = YES;
    
    self.adLoader = [[TDAdLoader alloc] init];
    
    // Create a single TDAdRequestURLBuilder for both audio and video requests
    self.requestBuilder = [[TDAdRequestURLBuilder alloc] initWithHostURL:kRequestUrl];
    self.requestBuilder.stationId = kStationId;
    self.requestBuilder.adType = kTDAdTypeMidroll;

    self.statusMessageLabel.text = @" ";
    self.activityIndicator.hidden = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)loadAudioAdPressed:(UIButton *)sender {
    [self showActivityIndicatorWithStatusMessage:@"Loading an audio ad..."];
    
    self.requestBuilder.assetType = kTDAssetTypeAudio;
    
    [self.adLoader loadAdWithBuilder:self.requestBuilder completionHandler:^(TDAd *loadedAd, NSError *error) {
        if (error) {
            [self hideActivityIndicatorWithStatusMessage:error.localizedDescription];
        
        } else {
            [self hideActivityIndicatorWithStatusMessage:@"Loaded an audio ad."];
            
            self.ad = loadedAd;
        }
    }];
}

- (IBAction)loadVideoAdPressed:(UIButton *)sender {
    [self showActivityIndicatorWithStatusMessage:@"Loading a video ad..."];
    
    self.requestBuilder.assetType = kTDAssetTypeVideo;
    
    [self.adLoader loadAdWithBuilder:self.requestBuilder completionHandler:^(TDAd *loadedAd, NSError *error) {
        if (error) {
            [self hideActivityIndicatorWithStatusMessage:error.localizedDescription];
            
        } else {
            [self hideActivityIndicatorWithStatusMessage:@"Loaded a video ad."];
            
            self.ad = loadedAd;
        }
    }];
}

- (IBAction)playButtonPressed:(UIButton *)sender {
    if (self.ad) {
        if ([self.ad.mediaMIMEType hasPrefix:@"video"]) {
            [self playVideoAd];
            
        } else {
            [self playAudioAd];
        }
    }
}

- (void)playVideoAd {
    [self showActivityIndicatorWithStatusMessage:@"Playing video ad."];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playbackStateDidChangeNotification:)
                                                 name:MPMoviePlayerPlaybackStateDidChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playBackDidFinishNotification:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:nil];
    
    self.moviePlayerViewController = [[MPMoviePlayerViewController alloc] initWithContentURL:self.ad.mediaURL];
    self.moviePlayerViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    self.moviePlayerViewController.moviePlayer.controlStyle = MPMovieControlStyleNone;
    
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(videoScreenTapped)];
    recognizer.delegate = self;
    [self.moviePlayerViewController.moviePlayer.view addGestureRecognizer:recognizer];
    
    [self addChildViewController:self.moviePlayerViewController];
    [self.view addSubview:self.moviePlayerViewController.view];
    
    float aspectRatio = self.ad.videoWidth / self.ad.videoHeight;
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.moviePlayerViewController.view
                                                          attribute:NSLayoutAttributeWidth
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeWidth
                                                         multiplier:1.0
                                                           constant:0.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.moviePlayerViewController.view
                                                          attribute:NSLayoutAttributeHeight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeWidth
                                                         multiplier:aspectRatio constant:0.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.moviePlayerViewController.view
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.playButton
                                                          attribute:NSLayoutAttributeBottom
                                                         multiplier:1.0 constant:8.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.moviePlayerViewController.view
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1.0 constant:0.0]];
    
    [self.moviePlayerViewController didMoveToParentViewController:self];

}

- (void)playAudioAd {
    [self showActivityIndicatorWithStatusMessage:@"Playing audio ad."];
    self.audioPlayer = [[AVPlayer alloc] initWithURL:self.ad.mediaURL];
    
    [self.bannerView removeFromSuperview];
    
    // Create a banner with a size that fits in the space between the downmost component (the play button) and the rest of the screen.
    // You can create how many banners you want with the size you want and just present the ad with each of them.
    TDCompanionBanner *banner = [self.ad bestCompanionBannerForWidth:CGRectGetWidth(self.view.frame) andHeight:CGRectGetHeight(self.view.frame) - CGRectGetMaxY(self.playButton.frame)];
    self.bannerView = [[TDBannerView alloc] initWithWidth:banner.width andHeight:banner.height];
    self.bannerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.bannerView];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.bannerView
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.playButton
                                                          attribute:NSLayoutAttributeBottom
                                                         multiplier:1.0 constant:8.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.bannerView
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1.0 constant:0.0]];
    
    [self.bannerView presentAd:self.ad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioPlayerDidFinish:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [self.audioPlayer addObserver:self forKeyPath:@"rate" options:0 context:nil];
    [self.audioPlayer play];

}

- (IBAction)clearButtonPressed:(UIButton *)sender {
    self.ad = nil;
    self.statusMessageLabel.text = @" ";
    [self.bannerView clear];
    
    [self.audioPlayer pause];
    
    if (self.moviePlayerViewController) {
        [self.moviePlayerViewController.moviePlayer stop];
        [self.moviePlayerViewController.view removeFromSuperview];
        [self.moviePlayerViewController removeFromParentViewController];
        self.moviePlayerViewController = nil;
    }
}

- (void)videoScreenTapped {
    [self.ad trackVideoClick];
    
    if (self.ad.videoClickThroughURL) {
        [self.moviePlayerViewController.moviePlayer stop];
        [[UIApplication sharedApplication] openURL:self.ad.videoClickThroughURL];
    }
}

-(void)showActivityIndicatorWithStatusMessage:(NSString*)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.statusMessageLabel.text = message;
        [self.activityIndicator startAnimating];
        self.activityIndicator.hidden = NO;
        
        self.loadAudioButton.enabled = NO;
        self.loadVideoButton.enabled = NO;
    });
}

-(void)hideActivityIndicatorWithStatusMessage:(NSString*)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.statusMessageLabel.text = message;
        [self.activityIndicator stopAnimating];
        self.activityIndicator.hidden = YES;

        self.loadAudioButton.enabled = YES;
        self.loadVideoButton.enabled = YES;
    });
}

#pragma mark - MPMoviePlayerViewController delegate methods

- (void)playbackStateDidChangeNotification:(NSNotification *) notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackStateDidChangeNotification object:nil];
    
    switch (self.moviePlayerViewController.moviePlayer.playbackState)
    {
        case MPMoviePlaybackStatePlaying:
            [self hideActivityIndicatorWithStatusMessage:@"Video ad is playing"];
            [self.ad trackMediaImpressions];
            break;
            
        case MPMoviePlaybackStatePaused:
            break;
            
        case MPMoviePlaybackStateInterrupted:
            break;
            
        case MPMoviePlaybackStateStopped:
            break;
            
        default:
            break;
    }
    
}

- (void)playBackDidFinishNotification:(NSNotification *) notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
    
    int reason = [notification.userInfo[MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue];
    
    switch (reason) {
        case MPMovieFinishReasonPlaybackEnded: {
            [self.moviePlayerViewController.view removeFromSuperview];
            [self.moviePlayerViewController removeFromParentViewController];
            self.statusMessageLabel.text = @"Video ad finished.";
            break;
        }
        case MPMovieFinishReasonUserExited:
            break;
            
        case MPMovieFinishReasonPlaybackError:
            break;
            
        default:
            break;
    }
}

#pragma mark - AVPlayerItem notifications
- (void)audioPlayerDidFinish:(NSNotification *) notfication {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];

    self.statusMessageLabel.text = @"Audio ad finished.";
    [self.bannerView clear];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    [self.audioPlayer removeObserver:self forKeyPath:@"rate"];
    
    if ([keyPath isEqualToString:@"rate"]) {
        if ([self.audioPlayer rate] > 0) {
            [self hideActivityIndicatorWithStatusMessage:@"Audio ad is playing"];
            [self.ad trackMediaImpressions];
        }
    }
}

#pragma mark - UIGestureRecognizerDelegate methods

#pragma mark - gesture delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}
@end
