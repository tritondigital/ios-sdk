//
//  TDSyncBannerView.h
//  TritonPlayerSDK
//
//  Copyright (c) 2015 Triton Digital. All rights reserved.
//

#import "TDBannerView.h"
#import "CuePointEvent.h"

/**
 * TDSyncBannerView is a TDBannerView subclass tailored to show a companion banner synchronized with the playing stream.
 *
 * It takes an ad CuePointEvent and display the ad if any available.
 */
@interface TDSyncBannerView : TDBannerView

/// @name Loading a CuePointEvent

/**
 * Loads an ad cue point into the banner. If the cue point doesn't represent an ad or if there's no ad to display, it does nothing.
 *
 * @param cuePoint The CuePointEvent with the ad to be loaded.
 */
- (void)loadCuePoint:(CuePointEvent *) cuePoint;

@end
