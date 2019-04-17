//
//  TDInterstitialAd.h
//  TritonPlayerSDK
//
//  Copyright (c) 2014 Triton Digital. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

#import "TDInterstitialAdDelegate.h"
#import "TDAd.h"
#import "TDAdRequestURLBuilder.h"

/**
 * The TDInterstitialAd class is used to request and display Triton interstitial ads. 
 *
 * Interstitial ads, like pre-rolls and mid-rolls, are full screen ads displayed in natural transition points of the app. I.e. Playing a video ad before the user start to listen to a station. Audio and video interstitials are supported. It's recommended to preload the ad long before it is displayed.
 */
@interface TDInterstitialAd : NSObject

/// @name Managing the delegate

/**
 * The delegate that will receive state changes from TDInterstitialAd.
 */

@property (nonatomic, weak) id<TDInterstitialDelegate> delegate;

/// @name Loading an interstitial ad

/**
 * Informs if the ad was loaded from Triton's server. This property should be checked before presenting the interstitial ad.
 */

@property (nonatomic, readonly) BOOL loaded;

/**
 * Prepare an interstitial ad for playing. It will be prefetched if needed.
 * 
 * @param ad The TDAd to be loaded.
 */

-(void)loadAd:(TDAd*) ad;

/**
 * Request and prepare an interstitial ad for playing. It will be prefetched if needed.
 * 
 * @param requestBuilder A TDAdRequestURLBuilder object representing the interstitial request.
 */

-(void)loadRequestBuilder:(TDAdRequestURLBuilder *) requestBuilder;

/**
 * Request and prepare an interstitial ad for playing. It will be prefetched if needed.
 *
 * @param stringRequest A NSString representing the interstitial request. It can be build manually or by TDAdRequestURLBuilder.
 */

-(void)loadStringRequest:(NSString *) stringRequest;


/// @name Presenting an Interstitial ad

/**
 * Presents the interstitial ad which takes over the entire screen until it finishes or the user dismisses it. This method only has effect if loaded returns YES and/or if the delegate’s interstitialDidReceiveAd: has been called.
 * @param rootViewController The current view controller which will be used to present the full screen ad.
 */

-(void)presentFromViewController:(UIViewController *) rootViewController;

@end
