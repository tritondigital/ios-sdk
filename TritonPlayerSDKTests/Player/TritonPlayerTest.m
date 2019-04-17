//
//  TritonPlayerTest.m
//  TritonPlayerSDKTests
//
//  Created by mrk on 2017-11-14.
//  Copyright © 2017 Triton Digital. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TritonPlayer.h"

@interface TritonPlayerTest : XCTestCase<TritonPlayerDelegate>

@end

@implementation TritonPlayerTest

BOOL active;
XCTestExpectation *expectation;

- (void)setUp {
    [super setUp];
		active = YES;
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
		active = NO;
		[super tearDown];
}

- (void)testCanReceiveOnMetaDataEventFromIceCast {
		expectation = [self expectationWithDescription:@"Play WO"];
		
		[NSThread detachNewThreadSelector:@selector(play) toTarget:self withObject:nil];
		
		[[NSRunLoop currentRunLoop] addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
		
		while (active) {
				CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.090, FALSE);
		}
		
		[self waitForExpectationsWithTimeout:30 handler:^(NSError * _Nullable error) {

		}];
}

-(void) play
{
		NSString *url = [[NSBundle bundleForClass:[self class]] pathForResource:@"stream" ofType:@"flv"];
		NSDictionary *settings = @{SettingsContentURLKey : [NSString stringWithFormat:@"file://%@", url] };
		TritonPlayer *player = [[TritonPlayer alloc] initWithDelegate:self andSettings:settings];
		[player play];
}

-(void)player:(TritonPlayer *)player didReceiveMetaData: (NSDictionary *)metaData
{
		XCTAssertNotNil(metaData);
		XCTAssertNotNil([metaData objectForKey:@"StreamTitle"]);
		active = FALSE;
		[expectation fulfill];
}




@end

