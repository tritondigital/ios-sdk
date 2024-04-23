//
//  TDBannerViewDelegate.h
//  TritonPlayerSDK
//
//  Copyright (c) 2014 Triton Digital. All rights reserved.
//

@class TDBannerView;

/**
 * TDBannerViewDelegate defines methods you can implement to receive life-cycle information about a TDBannerView.
 */
@protocol TDBannerViewDelegate <NSObject>

@optional

/**
 * Sent when TDBannerView presents an ad. This is a good opportunity to show, add to hierarchy or animate the banner if it has not being displayed yet.
 *
 * @param bannerView The banner that presented an ad.
 */

-(void) bannerViewDidPresentAd:(TDBannerView*) bannerView;

/**
 * Sent if a TDBannerView failed to present an ad. Normally it happens if there's no ad available (no inventory) to be displayed.
 *
 * @param bannerView The TDBannerView that failed to present an ad.
 * @param error The error that occurred during loading. The error codes are available in TDAdLoader.h.
 */

-(void) bannerView:(TDBannerView*) bannerView didFailToPresentAdWithError:(NSError *) error;

/**
 * Sent when the app will be deactivated or sent to background because the user clicked on an ad and it will be loaded externally in a browser.
 *
 * @param bannerView The banner that will leave the application
 */

-(void) bannerViewWillLeaveApplication:(TDBannerView*) bannerView;

@end
