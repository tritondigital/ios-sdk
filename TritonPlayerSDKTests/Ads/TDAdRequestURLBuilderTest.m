//
//  TDAdRequestURLBuilderTest.m
//  TritonPlayerSDK
//
//  Created by Carlos Pereira on 2014-12-04.
//  Copyright (c) 2014 Triton Digital. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <TritonPlayerSDK/TritonPlayerSDK.h>

#define kHttpHostUrlComplete @"http://cmod209.live.streamtheworld.com/ondemand/ars"
#define kHttpsHostUrlComplete @"https://cmod209.live.streamtheworld.com/ondemand/ars"
#define invalidUrl @"gttp://cmod209.live.streamtheworld.com/myrko/georges"
#define kHostUrlNoSchema @"cmod209.live.streamtheworld.com/ondemand/ars"
#define kHostUrlNoSuffix @"http://cmod209.live.streamtheworld.com"
#define kHostUrlNoSchemaNoSuffix @"cmod209.live.streamtheworld.com"

@interface TDAdRequestURLBuilderTest : XCTestCase

@property (nonatomic, strong) TDAdRequestURLBuilder *urlBuilder;

@end

@implementation TDAdRequestURLBuilderTest

- (void)setUp {
    [super setUp];
    
    self.urlBuilder = [[TDAdRequestURLBuilder alloc] initWithHostURL:@"http://mobileapps.media.streamtheworld.com/sandbox/cpereira/vast/ars.xml"];
    self.urlBuilder.stationId = 1001;
    self.urlBuilder.stationName = @"KYJJ";
    self.urlBuilder.postalCode = @"H2V3S5";
    self.urlBuilder.dateOfBirth = [NSDate date];
    self.urlBuilder.gender = kTDGenderMale;
    self.urlBuilder.latitude = 22;
    self.urlBuilder.longitude = -22;
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testHostUrlAutoComplete {
    TDAdRequestURLBuilder *builder = [TDAdRequestURLBuilder builderWithHostURL:kHttpHostUrlComplete];
    builder.stationId = 1234;
		
		
		
    NSString *request = [builder generateAdRequestURL];
    
    XCTAssert([request hasPrefix:kHttpsHostUrlComplete]);
    
    builder = [TDAdRequestURLBuilder builderWithHostURL:kHttpsHostUrlComplete];
    builder.stationId = 1234;
    
    request = [builder generateAdRequestURL];
    
    XCTAssert([request hasPrefix:kHttpsHostUrlComplete]);
    
    builder = [TDAdRequestURLBuilder builderWithHostURL:invalidUrl];
    builder.stationId = 1234;
    
    request = [builder generateAdRequestURL];
    
    XCTAssert([request hasPrefix:kHttpsHostUrlComplete]);

    builder = [TDAdRequestURLBuilder builderWithHostURL:kHostUrlNoSchema];
    builder.stationId = 1234;
    
    request = [builder generateAdRequestURL];
    
    XCTAssert([request hasPrefix:kHttpsHostUrlComplete]);
    
    builder = [TDAdRequestURLBuilder builderWithHostURL:kHostUrlNoSuffix];
    builder.stationId = 1234;
    
    request = [builder generateAdRequestURL];
    
    XCTAssert([request hasPrefix:kHttpsHostUrlComplete]);
    
    builder = [TDAdRequestURLBuilder builderWithHostURL:kHostUrlNoSchemaNoSuffix];
    builder.stationId = 1234;
    
    request = [builder generateAdRequestURL];
    
    XCTAssert([request hasPrefix:kHttpsHostUrlComplete]);
}

- (void)testNoMandatoryParameters {
    
}

- (void)testExample {
    // This is an example of a functional test case.
    XCTAssert([self.urlBuilder generateAdRequestURL] != nil, @"Pass");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
