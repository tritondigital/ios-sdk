//
//  TDAd.h
//  TritonPlayerSDK
//
//  Copyright (c) 2014 Triton Digital. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TDCompanionBanner;

/**
 * TDAd represents a Triton ad in the SDK. It contains information about all supported ads (in-stream/on-demand, audio/banner/video).
 *
 * Usually TDAd is used as an output of TDAdLoader and as input of TDBannerView and TDInterstitialAd and its details don't need to be known. However,
 * when the application is rendering the ads by itself, it must inspect its attributes and methods.
 */

@interface TDAd : NSObject

/// @name General properties

/// The urls that need to be called for generating an ad impression
@property (nonatomic, strong) NSArray *mediaImpressionURLs;

/// The type of the linear media as a MIME-type (usually audio or video)
@property (nonatomic, strong) NSString *mediaMIMEType;


/// The format of the ad. VAST or DAAST
@property (nonatomic, strong) NSString *format;


/// The url of the linear media
@property (nonatomic, strong) NSURL    *mediaURL;

/// @name Banner ads

/// An array of TDCompanionBanner objects for each banner available in the ad
@property (nonatomic, strong) NSArray *companionBanners;

/// @name Video interstitials

/// The width of the video
@property (nonatomic, assign) NSInteger videoWidth;

/// The height of the video
@property (nonatomic, assign) NSInteger videoHeight;

/// The url that the app must be redirected when the user clicks in a video ad
@property (nonatomic, strong) NSURL     *videoClickThroughURL;

/// The list of urls that must be called to track the user clicking in a video ad
@property (nonatomic, strong) NSArray   *clickTrackingURLs;

@property (nonatomic, strong) NSURL     *vastAdTagUri;

@property (nonatomic, strong) NSURL     *errorUrl;
/// @name Helper methods

/**
 * Returns the companion banner in the receiver's companion banners list that approximates most the desired width and height.
 *
 * @param width the desired width of the banner
 * @param height the desired height of the banner
 * @return A TDCompanionBanner that is the best match for the desired width and height.
 */

-(TDCompanionBanner*)bestCompanionBannerForWidth:(NSInteger)width andHeight:(NSInteger)height;

/**
 * Tracks asynchronously all the media impressions URL for the ad. Useful when you are rendering your ads with custom UI.
 */
-(void)trackMediaImpressions;

/**
 * Tracks asynchronously all the video click URLs for the ad. Useful when you are rendering your ads with custom UI.
 */
-(void)trackVideoClick;
@end
