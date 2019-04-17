//
//  TDSyncBannerView.m
//  TritonPlayerSDK
//
//  Created by Carlos Pereira on 2015-02-18.
//  Copyright (c) 2015 Triton Digital. All rights reserved.
//

#import "TDSyncBannerView.h"
#import "TDAdLoader.h"

@interface TDSyncBannerView ()

@property (nonatomic, strong) TDAdLoader *adLoader;

@end

@implementation TDSyncBannerView

-(instancetype)initWithWidth:(NSInteger)width
                   andHeight:(NSInteger)height
            andFallbackWidth:(NSInteger)fallbackWidth
           andFallbackHeight:(NSInteger)fallbackHeight
                   andOrigin:(CGPoint)origin {
    self = [super initWithWidth:width andHeight:height andFallbackWidth:fallbackWidth andFallbackHeight:fallbackHeight andOrigin:origin];

    if (self) {
        self.adLoader = [[TDAdLoader alloc] init];
    }
    
    return self;
}

-(void)loadCuePoint:(CuePointEvent *)cuePoint {
    
    if (!cuePoint) {
        return;
    }
    
    NSString *adRequestUrl = cuePoint.data[@"ad_vast"];
    
    if (!adRequestUrl || [adRequestUrl isEqualToString:@""]) {
        adRequestUrl = cuePoint.data[@"ad_vast_url"];
    }
   
    if (!adRequestUrl) {
        [super clear];
    
    } else {
        [self.adLoader loadAdWithStringRequest:adRequestUrl completionHandler:^(TDAd *loadedAd, NSError *error) {
            
            if (error) {
                dispatch_async(dispatch_get_global_queue(0, 0), ^{
                    if ([self.delegate respondsToSelector:@selector(bannerView:didFailToPresentAdWithError:)]) {
                        [self.delegate bannerView:self didFailToPresentAdWithError:error];
                    }
                });
                
            } else {
                [super presentAd:loadedAd];
            }
            
        }];
    }
}

@end
