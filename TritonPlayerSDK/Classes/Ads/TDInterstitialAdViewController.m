//
//  TDInterstitialAdViewController.m
//  TritonPlayerSDK
//
//  Created by Carlos Pereira on 2015-01-23.
//  Copyright (c) 2015 Triton Digital. All rights reserved.
//

#import "TDInterstitialAdViewController.h"
#import "TDAd.h"
#import "TDCloseButton.h"
#import "TDAdUtils.h"
#import "TDBannerView.h"
#import "TDBannerViewDelegate.h"
#import "TDCompanionBanner.h"

#import <AVFoundation/AVFoundation.h>

#define kCloseButtonWidth 30
#define kCloseButtonHeight 30
#define kCloseButtonXPosition 10
#define kCloseButtonYPosition 20

typedef NS_ENUM(NSInteger, TDMediaType) {
    kTDMediaTypeUnknown,
    kTDMediaTypeVideo,
    kTDMediaTypeAudio
};

@interface TDInterstitialAdViewController ()<UIGestureRecognizerDelegate, TDBannerViewDelegate>

@property (nonatomic, strong) TDAd *ad;
@property (nonatomic, assign) TDMediaType mediaType;

@property (nonatomic, strong) TDCloseButton *closeButton;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;

// For video ads
@property (nonatomic, strong) MPMoviePlayerViewController *moviePlayerViewController;

// For audio ads
@property (nonatomic, strong) AVPlayer *audioPlayer;
@property (nonatomic, strong) TDBannerView *banner;

@property (nonatomic, assign) BOOL userClickedVideo;

@end

@implementation TDInterstitialAdViewController

- (instancetype)initWithAd:(TDAd *) ad andDelegate:(id)delegate {
    self = [super init];
    
    if (self) {
        self.ad = ad;
        self.delegate = delegate;
        
        if ([ad.mediaMIMEType hasPrefix:@"video"]) {
            self.mediaType = kTDMediaTypeVideo;
            
        } else if ([self.ad.mediaMIMEType hasPrefix:@"audio"]) {
            self.mediaType = kTDMediaTypeAudio;
            
        } else {
            self.mediaType = kTDMediaTypeUnknown;
        }
    }
    
    return self;
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)loadView {
    self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
}

-(void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [self.activityIndicator setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:self.activityIndicator];
    [self addCenterConstraintForItem:self.activityIndicator];
    [self.activityIndicator startAnimating];
    
    self.closeButton = [[TDCloseButton alloc] initWithFrame:CGRectMake(kCloseButtonXPosition, kCloseButtonYPosition, kCloseButtonWidth, kCloseButtonHeight)];
    [self.closeButton addTarget:self action:@selector(closeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.closeButton];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    
    self.userClickedVideo = NO;
}

- (void)showAd {
    
    if (self.mediaType == kTDMediaTypeVideo) {
        [self playVideoAd:self.ad];

    } else if (self.mediaType == kTDMediaTypeAudio) {
        [self playAudioAd:self.ad];

    } else {
    }
}

- (void)screenTapped {
    self.userClickedVideo = YES;
    
    if (self.mediaType == kTDMediaTypeVideo) {
        // Track the click using the tracking server
        for (NSURL *url in self.ad.clickTrackingURLs) {
            [TDAdUtils trackUrlAsync:url];
        }
        
        // Open a browser to the click through url
        if (self.ad.videoClickThroughURL) {
            [self.presentingViewController dismissViewControllerAnimated:NO completion:^{
                if ([self.delegate respondsToSelector:@selector(interstitialWillLeaveApplication:)]) {
                    [self.delegate interstitialWillLeaveApplication:(TDInterstitialAd *)self.presentingViewController];
                }
                
                [[UIApplication sharedApplication] openURL:self.ad.videoClickThroughURL];
            }];
        }
    }
}

- (void)closeButtonPressed:(id) sender {
    if (self.mediaType == kTDMediaTypeVideo) {

        if (self.moviePlayerViewController.moviePlayer.playbackState == MPMoviePlaybackStateStopped) {
            if (self.presentingViewController) {
                if ([self.delegate respondsToSelector:@selector(interstitialWillDismiss:)]) {
                    [self.delegate interstitialWillDismiss:(TDInterstitialAd *)self.presentingViewController];
                }
                
                [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
                    if ([self.delegate respondsToSelector:@selector(interstitialDidDismiss:)]) {
                        [self.delegate interstitialDidDismiss:(TDInterstitialAd *)self.presentingViewController];
                    }
                }];
            }
            
        } else {
            [self.moviePlayerViewController.moviePlayer stop];
        
        }
    } else {
        [self.audioPlayer pause];
        
        if ([self.delegate respondsToSelector:@selector(interstitialWillDismiss:)]) {
            [self.delegate interstitialWillDismiss:(TDInterstitialAd *)self.presentingViewController];
        }
        
        [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
            if ([self.delegate respondsToSelector:@selector(interstitialDidDismiss:)]) {
                [self.delegate interstitialDidDismiss:(TDInterstitialAd *)self.presentingViewController];
            }
        }];
    }
}

- (void)playVideoAd:(TDAd *) ad {
    [self registerMoviePlayerNotifications];
    
    // Create and load MPMoviePlayer
    self.moviePlayerViewController = [[MPMoviePlayerViewController alloc] initWithContentURL:self.ad.mediaURL];
    [self.moviePlayerViewController.view setTranslatesAutoresizingMaskIntoConstraints:YES];
    
    self.moviePlayerViewController.moviePlayer.controlStyle = MPMovieControlStyleNone;
    [self.moviePlayerViewController.moviePlayer prepareToPlay];

    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(screenTapped)];
    recognizer.delegate = self;
    [self.moviePlayerViewController.moviePlayer.view addGestureRecognizer:recognizer];
}

- (void)playAudioAd:(TDAd *) ad {
    TDCloseButton *button = [[TDCloseButton alloc] initWithFrame:CGRectMake(kCloseButtonXPosition, kCloseButtonYPosition, kCloseButtonWidth, kCloseButtonHeight)];
    [button addTarget:self action:@selector(closeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(screenTapped)];
    recognizer.delegate = self;
    
    [self.view addGestureRecognizer:recognizer];
    [self.view addSubview:button];
    
    self.audioPlayer = [[AVPlayer alloc] initWithURL:ad.mediaURL];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioPlayerDidFinish:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [self.audioPlayer addObserver:self forKeyPath:@"rate" options:0 context:nil];
    [self.audioPlayer play];
    
    TDCompanionBanner *companionBanner = [ad bestCompanionBannerForWidth:CGRectGetWidth(self.view.frame) andHeight:CGRectGetHeight(self.view.frame)];
    if (companionBanner) {
        self.banner = [[TDBannerView alloc] initWithWidth:companionBanner.width andHeight:companionBanner.height];
        self.banner.translatesAutoresizingMaskIntoConstraints = NO;

        self.banner.delegate = self;
        [self.view addSubview:self.banner];
        [self addCenterConstraintForItem:self.banner];
        [self.banner presentAd:ad];
    }
}

- (void)addCenterConstraintForItem:(UIView *)item {
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.view
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:item
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1.0
                                                           constant:0.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.view
                                                          attribute:NSLayoutAttributeCenterY
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:item
                                                          attribute:NSLayoutAttributeCenterY
                                                         multiplier:1.0
                                                           constant:0.0]];

}

#pragma mark - MPMoviePlayerController notifications

- (void)loadStateDidChangeNotification:(NSNotification *) notification {
    
    if (self.moviePlayerViewController.moviePlayer.loadState & MPMovieLoadStatePlayable) {
        // Do nothing for the moment
    }
    
    if (self.moviePlayerViewController.moviePlayer.loadState & MPMovieLoadStatePlaythroughOK) {
        
        if (self.moviePlayerViewController.presentingViewController == nil) {
            [self presentViewController:self.moviePlayerViewController animated:NO completion:^{
                [self.closeButton removeFromSuperview];
                [self.moviePlayerViewController.moviePlayer.view addSubview:self.closeButton];
                [self.moviePlayerViewController.moviePlayer play];
            }];
        }
    }
}

- (void)playBackDidFinishNotification:(NSNotification *) notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
    
    int reason = [notification.userInfo[MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue];
    
    switch (reason) {
        case MPMovieFinishReasonPlaybackEnded: {
            if ([self.delegate respondsToSelector:@selector(interstitialWillDismiss:)]) {
                [self.delegate interstitialWillDismiss:(TDInterstitialAd *)self.presentingViewController];
            }
            [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
                if ([self.delegate respondsToSelector:@selector(interstitialDidDismiss:)]) {
                    [self.delegate interstitialDidDismiss:(TDInterstitialAd *)self.presentingViewController];
                }
            }];
            break;
        }
        case MPMovieFinishReasonUserExited:
            if (self.moviePlayerViewController) {
                [self.moviePlayerViewController.moviePlayer stop];
            }
            break;
            
        case MPMovieFinishReasonPlaybackError:
            break;
            
        default:
            break;
    }
}

- (void)playbackStateDidChangeNotification:(NSNotification *) notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackStateDidChangeNotification object:nil];
    
    switch (self.moviePlayerViewController.moviePlayer.playbackState)
    {
        case MPMoviePlaybackStatePlaying:
            for (NSURL *url in self.ad.mediaImpressionURLs) {
                [TDAdUtils trackUrlAsync:url];
            }
            
            [self.activityIndicator stopAnimating];
            [self.activityIndicator removeFromSuperview];
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

- (void)registerMoviePlayerNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadStateDidChangeNotification:)
                                                 name:MPMoviePlayerLoadStateDidChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playBackDidFinishNotification:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playbackStateDidChangeNotification:)
                                                 name:MPMoviePlayerPlaybackStateDidChangeNotification
                                               object:nil];
}

#pragma mark - AVPlayerItem notifications
- (void)audioPlayerDidFinish:(NSNotification *) notfication {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
    if ([self.delegate respondsToSelector:@selector(interstitialWillDismiss:)]) {
        [self.delegate interstitialWillDismiss:(TDInterstitialAd *)self.presentingViewController];
    }
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        if ([self.delegate respondsToSelector:@selector(interstitialDidDismiss:)]) {
            [self.delegate interstitialDidDismiss:(TDInterstitialAd *)self.presentingViewController];
        }
    }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    [self.audioPlayer removeObserver:self forKeyPath:@"rate"];
    
    if ([keyPath isEqualToString:@"rate"]) {
        if ([self.audioPlayer rate] > 0) {
            for (NSURL *url in self.ad.mediaImpressionURLs) {
                [TDAdUtils trackUrlAsync:url];
            }
            
            [self.activityIndicator stopAnimating];
            [self.activityIndicator removeFromSuperview];
        }
    }
}

#pragma mark - UIGestureRecognizerDelegate methods

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

#pragma mark - TDBannerView delegate methods

-(void)bannerViewDidPresentAd:(TDBannerView *)bannerView {
    [self.activityIndicator stopAnimating];
    [self.activityIndicator removeFromSuperview];
}

-(void)bannerViewWillLeaveApplication:(TDBannerView *)bannerView {
    // Pause audio when user clicked in a banner
    [self.audioPlayer pause];
    
    [self.presentingViewController dismissViewControllerAnimated:NO completion:^{
        if ([self.delegate respondsToSelector:@selector(interstitialWillLeaveApplication:)]) {
            [self.delegate interstitialWillLeaveApplication:(TDInterstitialAd *)self.presentingViewController];
        }
    }];
}

#pragma mark - UIApplication notification

-(void)appWillResignActive:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    
    // If user clicked in a video (clickthrough) things will already be handled. Otherwise, close the interstitial
    if (!self.userClickedVideo) {
        [self closeButtonPressed:nil];
    }
}

@end
