//
//  CuePointEventControllerTest.m
//  FLVStreamPlayerLib
//
//  Created by Thierry Bucco on 09-04-22.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CuePointEventController.h"
#import "CuePointEvent.h"
#import "FLVScriptObjectTag.h"
#import "testConstants.h"

@interface CuePointEventControllerTest : XCTestCase {
    CuePointEventController *cuePointEventController;
}

@end

@implementation CuePointEventControllerTest

-(void)setUp {
    NSLog(@"set up");
    cuePointEventController = [[CuePointEventController alloc] initWithDelegate:self];
}

-(void)tearDown {
        NSLog(@"tear down");
    cuePointEventController = nil;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// testAddCuePointEvent_GOOD
//
// check if event has been added to array
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)testAddCuePointEvent_GOOD
{
        NSLog(@"test add good");
	// construct a valid TAG aith good amf data
	FLVScriptObjectTag	*testTag;
	NSData *payload = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"thebravery_payload_good" ofType:@"raw"]];
    NSData *data = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"thebravery_data_good" ofType:@"raw"]];

	XCTAssertNotNil(payload, @"payload is NULL");
	XCTAssertNotNil(data, @"data is NULL");
	
	// setting payload
	testTag = [[FLVScriptObjectTag alloc] initPayloadWithData:payload];
	
	// setting data
	[testTag setTagData:data];
	
	XCTAssertNotNil(testTag.amfObjectData, @"testTag.amfObjectData is NULL");
	
	CuePointEvent *lCuePointEvent = [[CuePointEvent alloc] initEventWithAMFObjectData:(NSDictionary *)testTag.amfObjectData andTimestamp:0];
	XCTAssertNotNil(lCuePointEvent, @"lCuePointEvent is NULL");
	
	XCTAssertTrue( ([lCuePointEvent.type isEqualToString:EventTypeTrack]), @"Event type is not EventTypeTrack");
	
	[cuePointEventController addCuePointEvent:lCuePointEvent];
	
	int nbOfEvents = [cuePointEventController getNumberOfEvents];
	
	XCTAssertTrue(nbOfEvents == 1, @"Number of events in queue should be 1");
	
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// testAddCuePointEvent_BAD
//
// check if no event has been added when nil
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)testAddCuePointEvent_BAD
{
        NSLog(@"test add bad");
	[cuePointEventController addCuePointEvent:nil];	
	
	int nbOfEvents = [cuePointEventController getNumberOfEvents];
	
	XCTAssertTrue(nbOfEvents == 0, @"Number of events in queue should be 0");

}


@end