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
#import  "AVKit/AVkit.h"

#define kCloseButtonWidth     25
#define kCloseButtonHeight    25
#define kCloseButtonXPosition 5
#define kCloseButtonYPosition 5

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
@property (strong) id playerObserver;

// For video ads
@property (nonatomic, strong) AVPlayerViewController *moviePlayerViewController;

// For audio ads
@property (nonatomic, strong) AVPlayer *audioPlayer;
@property (nonatomic, strong) TDBannerView *banner;

@property (nonatomic, assign) BOOL userClickedVideo;

@property (nonatomic, assign) NSTimer *adCountdownTimer;
@property (nonatomic, strong) UITextField *adCountdownDisplay;


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
}

- (void)showAd {
    if (self.mediaType == kTDMediaTypeVideo) {
        [self playVideoAd:self.ad];
    } else if (self.mediaType == kTDMediaTypeAudio) {
        [self playAudioAd:self.ad];
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
            if (self.presentingViewController) {
                if ([self.delegate respondsToSelector:@selector(interstitialWillDismiss:)]) {
                    [self.delegate interstitialWillDismiss:(TDInterstitialAd *)self.presentingViewController];
                }
                
            if ([self.delegate respondsToSelector:@selector(interstitialPlaybackFinished:)]) {
                   [self.delegate interstitialPlaybackFinished:(TDInterstitialAd *)self.presentingViewController];
            }

                [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
                    if ([self.delegate respondsToSelector:@selector(interstitialDidDismiss:)]) {
                        [self.delegate interstitialDidDismiss:(TDInterstitialAd *)self.presentingViewController];
                    }
                }];
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
    self.view.backgroundColor = [UIColor blackColor];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];

    self.userClickedVideo = NO;
    
    // Create and load MPMoviePlayer

    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:ad.mediaURL];
    playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = YES;
    AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];

    player.allowsExternalPlayback = YES;
    player.automaticallyWaitsToMinimizeStalling = NO;

    self.moviePlayerViewController = [[AVPlayerViewController alloc] init];
    self.moviePlayerViewController.player = player;
    [self.moviePlayerViewController.view setTranslatesAutoresizingMaskIntoConstraints:NO];
    self.moviePlayerViewController.showsPlaybackControls = NO;

    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [self.activityIndicator setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.activityIndicator startAnimating];
    self.activityIndicator.center = self.moviePlayerViewController.view.center;
    //[self.moviePlayerViewController.view addSubview:self.activityIndicator];

    TDCloseButton *button = [[TDCloseButton alloc] initWithFrame:CGRectMake(kCloseButtonXPosition, kCloseButtonYPosition, kCloseButtonWidth, kCloseButtonHeight)];
    [button addTarget:self action:@selector(closeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];

     [self registerMoviePlayerNotifications];
    [self presentViewController:self.moviePlayerViewController animated:YES completion:^{
        [self.moviePlayerViewController.contentOverlayView addSubview:self.activityIndicator];
        [self.moviePlayerViewController.contentOverlayView addSubview:button];

        if(self.enableCountdownDisplay){
            CGRect countdownDisplayRect = CGRectMake(5.0,
                                         (self.moviePlayerViewController.contentOverlayView.frame.size.height - 30.0),
                                         30.0,
                                          30.0);
            self.adCountdownDisplay = [[UITextField alloc] initWithFrame:countdownDisplayRect];
            self.adCountdownDisplay.text = self.ad.adDuration.stringValue;
            
            [self.moviePlayerViewController.contentOverlayView addSubview:self.adCountdownDisplay];
        }

        [player playImmediatelyAtRate:1.0];
    }];

    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(screenTapped)];
    recognizer.delegate = self;
    [self.moviePlayerViewController.view addGestureRecognizer:recognizer];
}

- (void)playAudioAd:(TDAd *) ad {
    TDCloseButton *button = [[TDCloseButton alloc] initWithFrame:CGRectMake(kCloseButtonXPosition, kCloseButtonYPosition, kCloseButtonWidth, kCloseButtonHeight)];
    [button addTarget:self action:@selector(closeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(screenTapped)];
    recognizer.delegate = self;
    
    
    self.audioPlayer = [[AVPlayer alloc] initWithURL:ad.mediaURL];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioPlayerDidFinish:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [self.audioPlayer addObserver:self forKeyPath:@"rate" options:0 context:nil];
    [self.audioPlayer play];
    
    self.banner = [[TDBannerView alloc] initWithWidth:CGRectGetWidth(self.view.frame) andHeight:CGRectGetHeight(self.view.frame)];
        self.banner.translatesAutoresizingMaskIntoConstraints = NO;

        self.banner.delegate = self;
        [self.view addSubview:self.banner];
        [self addCenterConstraintForItem:self.banner];
        [self.banner presentAd:ad];
    [self.view addGestureRecognizer:recognizer];
    [self.view addSubview:button];
    
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

- (void)playBackDidFinishNotification:(NSNotification *) notification {
    if(self.adCountdownTimer != nil){
        [self.adCountdownTimer invalidate];
        self.adCountdownTimer = nil;
    }

    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
	    if ([self.delegate respondsToSelector:@selector(interstitialPlaybackFinished:)]) {
		   [self.delegate interstitialPlaybackFinished:(TDInterstitialAd *)self.presentingViewController];
	    }
    
            if ([self.delegate respondsToSelector:@selector(interstitialWillDismiss:)]) {
                [self.delegate interstitialWillDismiss:(TDInterstitialAd *)self.presentingViewController];
            }
    
            [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
                if ([self.delegate respondsToSelector:@selector(interstitialDidDismiss:)]) {
                    [self.delegate interstitialDidDismiss:(TDInterstitialAd *)self.presentingViewController];
                }
            }];
}
         
- (void)playbackStartedNotification{
    [self.moviePlayerViewController.player removeTimeObserver:self.playerObserver];
    self.playerObserver = nil;
            for (NSURL *url in self.ad.mediaImpressionURLs) {
                [TDAdUtils trackUrlAsync:url];
            }
            
            [self.activityIndicator stopAnimating];
            [self.activityIndicator removeFromSuperview];
	    if(self.enableCountdownDisplay){
		self.adCountdownTimer=[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(addCountdownTimerFired) userInfo:nil repeats:YES];
	    }
}
            
- (void)registerMoviePlayerNotifications {          
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playBackDidFinishNotification:)
                                            name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.moviePlayerViewController.player.currentItem];             
    
    CMTime interval = CMTimeMakeWithSeconds(0.5, NSEC_PER_SEC);

    // Add time observer
     __weak typeof(self) weakSelf = self;
       self.playerObserver =  [self.moviePlayerViewController.player addPeriodicTimeObserverForInterval:interval
                                                  queue:NULL
                                             usingBlock:^(CMTime time) {
           [weakSelf playbackStartedNotification];
        }];
}

-(void)addCountdownTimerFired
{
    if(self.ad.adDuration.intValue >=  0)
    {
        self.ad.adDuration = [NSNumber numberWithInt:(self.ad.adDuration.intValue - 1)];
        self.adCountdownDisplay.text = self.ad.adDuration.stringValue;
    }
    else
    {
        if(self.adCountdownTimer != nil){
            [self.adCountdownTimer invalidate];
            self.adCountdownTimer = nil;
        }
    }
}

#pragma mark - AVPlayerItem notifications
- (void)audioPlayerDidFinish:(NSNotification *) notfication {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
    if ([self.delegate respondsToSelector:@selector(interstitialPlaybackFinished:)]) {
           [self.delegate interstitialPlaybackFinished:(TDInterstitialAd *)self.presentingViewController];
    }
    
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
