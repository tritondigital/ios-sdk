//
//  TDInterstitialAdViewController.h
//  TritonPlayerSDK
//
//  Created by Carlos Pereira on 2015-01-23.
//  Copyright (c) 2015 Triton Digital. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TDInterstitialAd.h"
@import MediaPlayer;

@class TDAd;

@interface TDInterstitialAdViewController : UIViewController

@property (nonatomic, weak) id<TDInterstitialDelegate> delegate;

@property (nonatomic, assign) BOOL enableCountdownDisplay;

- (instancetype)initWithAd:(TDAd *) ad andDelegate:(id<TDInterstitialDelegate>) delegate;

- (void)showAd;

@end
