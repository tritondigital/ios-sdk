//
//  TDAd.m
//  TritonPlayerSDK
//
//  Created by Carlos Pereira on 2014-12-01.
//  Copyright (c) 2014 Triton Digital. All rights reserved.
//

#import "TDAd.h"
#import "TDCompanionBanner.h"
#import "TDAdUtils.h"

@implementation TDAd

-(TDCompanionBanner*)bestCompanionBannerForWidth:(NSInteger)width andHeight:(NSInteger)height {
 
    TDCompanionBanner *bestBanner = nil;
    NSInteger bestDeltaWidth = INT32_MAX;
    NSInteger bestDeltaHeight = INT32_MAX;
    
    for (TDCompanionBanner *banner in self.companionBanners) {
        NSInteger newDeltaWidth = width - banner.width;
        
        if (newDeltaWidth >= 0 && newDeltaWidth <= bestDeltaWidth) {
            NSInteger newDeltaHeight = height - banner.height;
            if (newDeltaHeight >= 0 && newDeltaHeight < bestDeltaHeight) {
                bestDeltaWidth = newDeltaWidth;
                bestDeltaHeight = newDeltaHeight;
                bestBanner = banner;
            }
        }
    }
    
    return bestBanner;
}

-(void)trackMediaImpressions {
    for (NSURL *url in self.mediaImpressionURLs) {
        [TDAdUtils trackUrlAsync:url];
    }
}

-(void)trackVideoClick {
    for (NSURL *url in self.clickTrackingURLs) {
        [TDAdUtils trackUrlAsync:url];
    }
}

@end
