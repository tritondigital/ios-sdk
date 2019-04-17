//
//  InterstitialViewController.m
//  tritonplayer-sample-app
//
//  Copyright (c) 2015 Triton Digital. All rights reserved.
//

#import "InterstitialViewController.h"

#import <TritonPlayerSDK/TritonPlayerSDK.h>

@interface InterstitialViewController () <TDInterstitialDelegate>

@property (nonatomic, strong) TDAdLoader *adLoader;
@property (nonatomic, strong) TDInterstitialAd *videoInterstitial;
@property (nonatomic, strong) TDInterstitialAd *audioInterstitial;

@property (weak, nonatomic) IBOutlet UILabel *labelStatusAudio;
@property (weak, nonatomic) IBOutlet UILabel *labelStatusVideo;

@end

@implementation InterstitialViewController 

-(void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
    self.navigationItem.leftItemsSupplementBackButton = YES;
    
    self.labelStatusAudio.text = @"";
    self.labelStatusVideo.text = @"";
    
    [self createAndLoadInterstitials];
}

-(void)createAndLoadInterstitials {
    
    // Create an ad request. In this example, the same request will be used for both audio and video ads
    TDAdRequestURLBuilder *requestBuilder = [TDAdRequestURLBuilder builderWithHostURL:kRequestUrl];
    requestBuilder.assetType = kTDAssetTypeVideo;
    requestBuilder.adType = kTDAdTypeMidroll;
    requestBuilder.stationId = kStationId;
    requestBuilder.TTags     = @[@"mobile:ios", @"triton:sample"];
    
    self.videoInterstitial = [[TDInterstitialAd alloc] init];
    self.videoInterstitial.delegate = self;

    self.adLoader = [[TDAdLoader alloc] init];
    [self.adLoader loadAdWithBuilder:requestBuilder completionHandler:^(TDAd *loadedAd, NSError *error) {
        
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.labelStatusVideo.text = error.localizedDescription;
            });
        
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.labelStatusVideo.text = @"Loaded a video ad";
            });

            [self.videoInterstitial loadAd:loadedAd];
        }
    }];
    
    requestBuilder.assetType = kTDAssetTypeAudio;
    requestBuilder.adType = kTDAdTypeMidroll;

    self.audioInterstitial = [[TDInterstitialAd alloc] init];
    self.audioInterstitial.delegate = self;
    
    [self.adLoader loadAdWithBuilder:requestBuilder completionHandler:^(TDAd *loadedAd, NSError *error) {

        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.labelStatusAudio.text = error.localizedDescription;
                
            });
        
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.labelStatusAudio.text = @"Loaded an audio ad";
            });
            
            [self.audioInterstitial loadAd:loadedAd];
        }
    }];
}

#pragma mark - TDInterstitialDelegate methods

-(void)interstitial:(TDInterstitialAd *)ad didFailToLoadAdWithError:(NSError *)error {
    NSLog(@"Error loading interstitial ad: %@", error.localizedDescription);
}

-(void)interstitialWillPresent:(TDInterstitialAd *)ad {
    NSLog(@"interstitialWillPresent");
}

-(void)interstitialWillDismiss:(TDInterstitialAd *)ad {
    NSLog(@"interstitialWillDismiss");
    
    [self createAndLoadInterstitials];
}

-(void)interstitialDidDismiss:(TDInterstitialAd *)ad {
    NSLog(@"interstitialDidDismiss");
}

-(void)interstitialWillLeaveApplication:(TDInterstitialAd *)ad {
    NSLog(@"An external link will open in the browser");
}

#pragma mark - IBAction methods

- (IBAction)playVideoAdPressed:(id)sender {
    if (self.videoInterstitial.loaded) {
        [self.videoInterstitial presentFromViewController:self];
    }
}

- (IBAction)playAudioAdPressed:(id)sender {
    if (self.audioInterstitial.loaded) {
        [self.audioInterstitial presentFromViewController:self];
    }
}
@end
