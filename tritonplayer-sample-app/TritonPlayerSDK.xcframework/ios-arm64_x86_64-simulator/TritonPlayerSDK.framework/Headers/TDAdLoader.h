//
//  TDAdLoader.h
//  TritonPlayerSDK
//
//  Copyright (c) 2015 Triton Digital. All rights reserved.
//

#import <Foundation/Foundation.h>

/// Represents Triton Mobile SDk generated error codes
extern NSString *const TDErrorDomain;

/// The error codes that can be returned when using ad functionality.
typedef NS_ENUM(NSInteger, TDAdErrorCode) {
    /// A network error occurred while requesting the ad
    TDErrorCodeInvalidRequest = 101,
    
    /// The width and height of the ad was not specified
    TDErrorCodeUndefinedSize = 102,
    
    /// There's no ad to be displayed for the request
    TDErrorCodeNoInventory = 103,
    
    /// The ad request or media url is malformed
    TDErrorCodeInvalidAdURL = 104,
    
    /// Unable to parse the response
    TDErrorCodeResponseParsingFailed = 105
};

@class TDAd;
@class TDAdRequestURLBuilder;

/** 
 * TDAdLoader loads a Triton ad from an ad request. 
 *
 * The ad returned is represented by a TDAd object and contains all the information needed to display and manage an ad. The ad returned can be 
 * presented using custom application UI or it can be passed directly to TDBannerView or TDInterstitialAd for display.
 *
 */

@interface TDAdLoader : NSObject

/// @name Creating a TDAdLoader

/**
 * Loads an ad asynchronously from a request string. The string can be built manually by following Triton Digital On-Demand advertising guide or 
 * by the help of TDAdRequestURLBuilder class (recommended).
 *
 * @param request A NSString containing the request with the targeting parameters.
 * @param completionHandler a block that will execute when the request is finished, with the ad loaded or an error object.
 */

- (void)loadAdWithStringRequest:(NSString*)request
       completionHandler:(void (^) (TDAd *loadedAd, NSError *error))completionHandler;

/**
 * Loads an ad asynchronously directly from a TDAdRequestURLBuilder.
 *
 * @param builder A TDAdRequestURLBuilder containing the request with the targeting parameters.
 * @param completionHandler a block that will execute when the request is finished, with the ad loaded or an error object.
 */

- (void)loadAdWithBuilder:(TDAdRequestURLBuilder*)builder
        completionHandler:(void (^) (TDAd *loadedAd, NSError *error))completionHandler;

@end
