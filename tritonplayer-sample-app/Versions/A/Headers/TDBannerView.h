//
//  TDBannerView.h
//  TritonPlayerSDK
//
//  Copyright (c) 2014 Triton Digital. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDBannerViewDelegate.h"

@class TDAdRequestURLBuilder;
@class TDAd;

/**
 * The TDBannerView class represents a view that displays Triton Banners (in-stream ads) ads. 
 *
 * The ads are represented by a TDAd object obtained from TDAdLoader. The banner size is independent of its frame size, but when initializing the TDBannerView with one of its initializers, it will make the underlying views size match the banner's size.
 */
@interface TDBannerView : UIView

/// @name Managing the delegate

/**
 * The delegate that will receive state changes from TDBannerView.
 */

@property (nonatomic, weak) id<TDBannerViewDelegate> delegate;

/// @name Creating a TDBannerView

/**
 * Initializes a TDBannerView with specified widht and height positioned at the top left corner of its superview (0,0).
 *
 * @param width The width of the banner
 * @param height The height of the banner
 */

-(instancetype) initWithWidth:(NSInteger)width
                    andHeight:(NSInteger)height;

/**
 * Initializes a TDBannerView with origin (0,0) with specified widht and height in addition to fallback width and height.
 *
 * The fallback size must be smaller than the main size otherwise it won't fit inside the view.
 * This feature was added in order to easily support 320x50 and 300x50 in the same view. The view won't change it's size, the fallback view will be centralized inside it.
 *
 * @param width The width of the banner
 * @param height The height of the banner
 * @param fallbackWidth The fallback width of the banner
 * @param fallbackHeight The fallback height of the banner
 */

-(instancetype) initWithWidth:(NSInteger)width
                    andHeight:(NSInteger)height
             andFallbackWidth:(NSInteger)fallbackWidth
                    andFallbackHeight:(NSInteger)fallbackHeight;

/**
 * Initializes a TDBannerView at the specified origin with specified widht and height in addition to fallback width and height. This is the designated initializer.
 *
 * The fallback size must be smaller than the main size otherwise it won't fit inside the view.
 * This feature was added in order to easily support 320x50 and 300x50 in the same view. The view won't change it's size, the fallback view will be centralized inside it.
 *
 * @param width The width of the banner
 * @param height The height of the banner
 * @param fallbackWidth The fallback width of the banner
 * @param fallbackHeight The fallback height of the banner
 * @param origin a CGPoint with the top left position in points related to its superview
 */

-(instancetype) initWithWidth:(NSInteger)width
                    andHeight:(NSInteger)height
             andFallbackWidth:(NSInteger)fallbackWidth
                    andFallbackHeight:(NSInteger)fallbackHeight
                    andOrigin:(CGPoint)origin;

/// @name Configuring size and position

/**
 * The width supported by the banner.
 */

@property (assign, readonly) NSInteger width;

/**
 * The height supported by the banner.
 */

@property (assign, readonly) NSInteger height;

/**
 * The fallback width supported by the banner.
 */

@property (assign, readonly) NSInteger fallbackWidth;

/**
 * The fallback height supported by the banner.
 */

@property (assign, readonly) NSInteger fallbackHeight;

/**
 * Sets the width and height supported by the banner. These dimensions are indepentent of the banner frame size.
 *
 * @param width The width of the banner
 * @param height The height of the banner
 */

-(void)setWidth:(NSInteger) width andHeight:(NSInteger) height;

/**
 * Sets the fallback width and height supported by the banner. The fallback size, when set, will be used in case the main size is not available.
 * It will be centralized inside the banner.
 *
 * @param fallbackWidth The fallback width of the banner
 * @param fallbackHeight The fallback height of the banner
 */

-(void)setFallbackWidth:(NSInteger)fallbackWidth andHeight:(NSInteger) fallbackHeight;

/**
 * Changes the top left position of the banner view related to its superview
 *
 * @param origin a CGPoint with the new top left position in points related to its superview
 */

-(void)setOrigin:(CGPoint) origin;

/// @name Presenting and removing an ad

/**
 * Request an ad to be displayed in the view.
 *
 * @param ad the TDAd object with the ad information to be loaded. Loading with a nil object will clear the banner's content.
 */

-(void)presentAd:(TDAd*)ad;

/**
 * Clears the banner contents
 */

-(void)clear;

@end
