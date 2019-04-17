//
//  TDInterstitialAd.m
//  TritonPlayerSDK
//
//  Created by Carlos Pereira on 2014-11-26.
//  Copyright (c) 2014 Triton Digital. All rights reserved.
//

#import "TDInterstitialAd.h"
#import "TDAdParser.h"
#import "TDAd.h"
#import "TDBannerView.h"
#import "TDAdUtils.h"
#import "TDCloseButton.h"
#import "TDInterstitialAdViewController.h"
#import "TDAdLoader.h"

#import "TDAnalyticsTracker.h"


#define kCloseButtonWidth 30
#define kCloseButtonHeight 30
#define kCloseButtonXPosition 10
#define kCloseButtonYPosition 10

@interface TDInterstitialAd () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) MPMoviePlayerViewController *moviePlayerViewController;
@property (nonatomic, strong) UIViewController *rootViewController;
@property (nonatomic, strong) TDAd *ad;
@property (nonatomic, strong) TDInterstitialAdViewController *interstitialViewController;

@property (nonatomic, strong) TDAdLoader *adLoader;

@end

@implementation TDInterstitialAd

-(void)loadAd:(TDAd *)ad {
    if (!ad || !ad.mediaURL) {
        [self failWithError:[TDAdUtils errorWithCode:TDErrorCodeNoInventory andDescription:@"No ad to display"]];
        return;
    }
    
    // No pre-fetching for the moment
    self.ad = ad;
    
    if ([self.delegate respondsToSelector:@selector(interstitialDidLoadAd:)]) {
        [self.delegate interstitialDidLoadAd:self];
    }
}

-(void)loadRequestBuilder:(TDAdRequestURLBuilder *)requestBuilder {
    [self loadStringRequest:[requestBuilder generateAdRequestURL]];
}

-(void)loadStringRequest:(NSString *)stringRequest {
    
    //Init Google Analytics Tracker
    TDAnalyticsTracker* tracker =[TDAnalyticsTracker sharedTracker];
    [tracker initialize];
    
    if (!stringRequest || [stringRequest isEqualToString:@""]) {
        [self failWithError:[TDAdUtils errorWithCode:TDErrorCodeInvalidAdURL andDescription:@"The request for the interstitial ad is invalid"]];
        return;
    }
    
    [tracker startTimer];
    
    self.adLoader = [[TDAdLoader alloc] init];
    [self.adLoader loadAdWithStringRequest:stringRequest completionHandler:^(TDAd *loadedAd, NSError *error) {
        
        if (error) {
            [self failWithError:error];
            [self trackAdPreroll:loadedAd withSuccess:NO];
            return;
        }
        
        [self loadAd:loadedAd];
        [self trackAdPreroll:loadedAd withSuccess:YES];
    }];
}


-(void) trackAdPreroll:(TDAd*) loadedAd withSuccess:(BOOL) isSuccess
{
    if(loadedAd == nil) return ;
    
    TDAnalyticsTracker* tracker =[TDAnalyticsTracker sharedTracker];
    
    NSString* mimeType = loadedAd.mediaMIMEType;
    BOOL isVideo = (mimeType != nil &&  [mimeType rangeOfString:@"video"].location == NSNotFound)? FALSE: TRUE;
    NSString* adFormat  = loadedAd.format;
    NSTimeInterval loadTime = [tracker stopTimer];
    
    if(isSuccess)
        [tracker trackAdPrerollSuccessWithFormat:adFormat isVideo:isVideo withLoadTime:loadTime];
    else
      [tracker trackAdPrerollErrorWithFormat:adFormat isVideo:isVideo withLoadTime:loadTime];
}

-(BOOL)loaded {
    return self.ad != nil;
}

-(void)presentFromViewController:(UIViewController *)rootViewController {
    
    self.rootViewController = rootViewController;
    
    if (![[self.ad.mediaURL scheme] hasPrefix:@"https"]) {
        [self failWithError:[TDAdUtils errorWithCode:TDErrorCodeInvalidAdURL andDescription:@"The ad media URL is invalid."]];
        return;
    }
    
    self.interstitialViewController = [[TDInterstitialAdViewController alloc] initWithAd:self.ad andDelegate:self.delegate];
    [self.rootViewController presentViewController:self.interstitialViewController animated:YES completion:^{

        if ([self.delegate respondsToSelector:@selector(interstitialWillPresent:)]) {
            [self.delegate interstitialWillPresent:self];
        }
        
        [self.interstitialViewController showAd];
    }];
}

#pragma mark Error handling

-(void) failWithError:(NSError *) error {
    if ([self.delegate respondsToSelector:@selector(interstitial:didFailToLoadAdWithError:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate interstitial:self didFailToLoadAdWithError:error];
        });
    }
}

#pragma mark - UIGestureRecognizerDelegate methods

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

@end
