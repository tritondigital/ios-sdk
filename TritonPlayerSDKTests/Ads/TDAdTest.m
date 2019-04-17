//
//  TDCompanionBannerTest.m
//  TritonPlayerSDK
//
//  Created by Carlos Pereira on 2015-02-18.
//  Copyright (c) 2015 Triton Digital. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "TDAd.h"
#import "TDCompanionBanner.h"

@interface TDAdTest : XCTestCase

@property (nonatomic, strong) TDAd *ad;

@end

@implementation TDAdTest

- (void)setUp {
    [super setUp];

    self.ad = [[TDAd alloc] init];
    
    NSMutableArray *banners = [NSMutableArray array];
    
    TDCompanionBanner *banner320x50 = [[TDCompanionBanner alloc] init];
    banner320x50.width = 320;
    banner320x50.height = 50;
    [banners addObject:banner320x50];
    
    TDCompanionBanner *banner320x240 = [[TDCompanionBanner alloc] init];
    banner320x240.width = 320;
    banner320x240.height = 240;
    [banners addObject:banner320x240];
    
    TDCompanionBanner *banner300x50 = [[TDCompanionBanner alloc] init];
    banner300x50.width = 300;
    banner300x50.height = 50;
    [banners addObject:banner300x50];
    
    TDCompanionBanner *banner300x480 = [[TDCompanionBanner alloc] init];
    banner300x480.width = 300;
    banner300x480.height = 480;
    [banners addObject:banner300x480];
    
    TDCompanionBanner *banner320x480 = [[TDCompanionBanner alloc] init];
    banner320x480.width = 320;
    banner320x480.height = 480;
    [banners addObject:banner320x480];
    
    self.ad.companionBanners = banners;
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testSmallResolution {
    TDCompanionBanner *banner = [self.ad bestCompanionBannerForWidth:320 andHeight:240];
    
    XCTAssertEqual(banner.width, 320);
    XCTAssertEqual(banner.height, 240);
}

- (void)testMediumResolution {
    TDCompanionBanner *banner = [self.ad bestCompanionBannerForWidth:320 andHeight:640];
    
    XCTAssertEqual(banner.width, 320);
    XCTAssertEqual(banner.height, 480);
}

- (void)testBigResolution {
    TDCompanionBanner *banner = [self.ad bestCompanionBannerForWidth:1024 andHeight:768];
    
    XCTAssertEqual(banner.width, 320);
    XCTAssertEqual(banner.height, 480);
}

- (void)testVerySmallResolution {
    TDCompanionBanner *banner = [self.ad bestCompanionBannerForWidth:300 andHeight:300];
    
    XCTAssertEqual(banner.width, 300);
    XCTAssertEqual(banner.height, 50);
}

- (void)testNoBannerAvailable {
    TDCompanionBanner *banner = [self.ad bestCompanionBannerForWidth:200 andHeight:200];
    
    XCTAssertNil(banner);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
        TDCompanionBanner *banner = [self.ad bestCompanionBannerForWidth:320 andHeight:480];
    }];
}

@end
