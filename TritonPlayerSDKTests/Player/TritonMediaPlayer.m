//
//  TritonMediaPlayer.m
//  TritonPlayerSDKTests
//
//  Created by mrk on 2017-11-20.
//  Copyright © 2017 Triton Digital. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TDMediaPlayer.h"

@interface TritonMediaPlayer : XCTestCase

@end

@implementation TritonMediaPlayer

XCTestExpectation *expectation;

- (void)setUp {
		
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
		expectation = [self expectationWithDescription:@"Play"];

}


@end
