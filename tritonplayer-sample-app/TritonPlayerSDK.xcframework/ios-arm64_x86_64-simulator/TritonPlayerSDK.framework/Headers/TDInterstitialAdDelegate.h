//
//  TDInterstitialAdDelegate.h
//  TritonPlayerSDK
//
//  Copyright (c) 2015 Triton Digital. All rights reserved.
//

@class TDInterstitialAd;

/**
 *  TDInterstitialDelegate defines methods you can implement to handle interstitial life-cycle updates.
 */
@protocol TDInterstitialDelegate <NSObject>

@optional

/**
 * Called when the interstital ad was loaded suceesfully. From this point, it is able to be presented.
 *
 * @param ad The TDInterstitialAf object that loaded an ad.
 */
- (void)interstitialDidLoadAd:(TDInterstitialAd *)ad;

/**
 * Called when an interstitial ad loading failed.
 *
 * @param ad The TDInterstitialAd object that failed to load ad
 * @param error The error that occurred when loading the ad
 */
- (void)interstitial:(TDInterstitialAd *)ad didFailToLoadAdWithError:(NSError *)error;

/**
 * Called just before presenting an interstitial.
 *
 * @param ad The TDInterstitialAd object that will be presented
 */
- (void)interstitialWillPresent:(TDInterstitialAd *)ad;

/**
 * Called before the interstitial is to be animated off the screen.
 *
 * @param ad The TDInterstitialAd object that will be dismissed
 */

- (void)interstitialWillDismiss:(TDInterstitialAd *)ad;

/**
 * Called just after the interstitial is animated off the screen.
 *
 * @param ad The TDInterstitialAd object that did dismiss
 */

- (void)interstitialDidDismiss:(TDInterstitialAd *)ad;

/**
 * Called when inserstital playback has finished.
 *
 * @param ad The TDinterstitialAd object that finished playing
 */

- (void)interstitialPlaybackFinished:(TDInterstitialAd *)ad;

/**
 * Called just before the application will go to the background or terminate because the user clicked on an ad that will launch another application (such as the App Store).
 *
 * @param ad The TDInterstitialAd object that will leave the application
 */

- (void)interstitialWillLeaveApplication:(TDInterstitialAd *)ad;

@end

