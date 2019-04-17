//
//  FLVTagTest.m
//  FLVStreamPlayerLib
//
//  Created by Thierry Bucco on 09-04-22.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CuePointEvent.h"
#import "FLVScriptObjectTag.h"
#import "testConstants.h"


@interface CuePointEventTest : XCTestCase
@end

@implementation CuePointEventTest


//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// testInitEventWithAMFObjectData_BAD
//
// 1- amf dictionary from The Bravery good tag
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void) testInitEventWithAMFObjectData_GOOD
{
	// construct a valid TAG aith good amf data
	FLVScriptObjectTag	*testTag;
    //NSData *payload = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"thebravery_payload_good" ofType:@"raw"]];
	//NSData *data = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"thebravery_data_good" ofType:@"raw"]];
    NSData *payload = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"thebravery_payload_good" ofType:@"raw"]];
    NSData *data = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"JOYTURK_ROCKAAC" ofType:@"raw"]];
    
	XCTAssertNotNil(payload, @"payload is NULL");
	XCTAssertNotNil(data, @"data is NULL");
	
	// setting payload
	testTag = [[FLVScriptObjectTag alloc] initPayloadWithData:payload];
	
	// setting data
	[testTag setTagData:data];
	
	XCTAssertNotNil(testTag.amfObjectData, @"testTag.amfObjectData is NULL");

	CuePointEvent *lCuePointEvent = [[CuePointEvent alloc] initEventWithAMFObjectData:(NSDictionary *)testTag.amfObjectData andTimestamp:0];
	XCTAssertNotNil(lCuePointEvent, @"lCuePointEvent is NULL");
	
	XCTAssertTrue( ([lCuePointEvent.type isEqualToString:EventTypeTrack]), @"Event type is not NowPlaying");
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// testInitEventWithAMFObjectData_BAD
//
// amf dictionary is nil
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void) testInitEventWithAMFObjectData_BAD
{
	// try with empty data
	CuePointEvent *lCuePointEvent;
	
	lCuePointEvent = [[CuePointEvent alloc] initEventWithAMFObjectData:nil andTimestamp:0];
	XCTAssertNil(lCuePointEvent, @"CuePointEvent should be nil");
}

@end
