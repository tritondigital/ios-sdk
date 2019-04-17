//
//  TDAuthUtilsTest.m
//  TritonPlayerSDK
//
//  Created by Carlos Pereira on 2015-07-08.
//  Copyright (c) 2015 Triton Digital. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

//#import <TritonPlayerSDK/TritonPlayerSDK.h>
#import "TDAuthUtils.h"

@interface TDAuthUtilsTest : XCTestCase

@end

@implementation TDAuthUtilsTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testSimpleSign {
    NSString *token = [TDAuthUtils createJWTTokenWithSecretKey:@"ThisIsASecretValue"
                                                andSecretKeyId:@"a1b2c3d4e5" andRegisteredUser:YES andUserId:@"foo@bar.com" andTargetingParameters:@{}];
    
//    XCTAssert([token isEqualToString:@"eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiIsImtpZCI6ImExYjJjM2Q0ZTUifQ.eyJpc3MiOiJwZHZ5Iiwic3ViIjoiZm9vQGJhci5jb20iLCJpYXQiOjE0Mjk4MDI3MTYsInRkLXJlZyI6dHJ1ZX0.YeNcfr7Rcpv4P8Tu6Y2bRuGqYUGQM0lHjyK_nD8SWKA"], @"Pass");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
