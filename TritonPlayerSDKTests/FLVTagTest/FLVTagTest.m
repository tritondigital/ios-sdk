//
//  FLVTagTest.m
//  FLVStreamPlayerLib
//
//  Created by Thierry Bucco on 09-04-22.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "FLVScriptObjectTag.h"
#import "testConstants.h"
#import "CuePointEvent.h"

@interface FLVTagTest : XCTestCase
@end

@implementation FLVTagTest


//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// testSetTagData_nowPlaying_GOOD
//
// empty now playing (cleared)
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void) testSetTagData_nowPlaying_clear_GOOD
{
	FLVScriptObjectTag	*testTag;

    NSData *payload = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"cleared_payload_good" ofType:@"raw"]];
    NSData *data = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"cleared_data_good" ofType:@"raw"]];

	XCTAssertNotNil(payload, @"payload is NULL");
	XCTAssertNotNil(data, @"data is NULL");
	
	//
	// Empty now playing
	//
	
	// setting payload
	testTag = [[FLVScriptObjectTag alloc] initPayloadWithData:payload];
	
	
	XCTAssertTrue(testTag.type == 18); // datascriptobject
	XCTAssertTrue(testTag.dataSize == 177);
	XCTAssertTrue(testTag.timestamp == 617735082); // datascriptobject
	
	// setting data
	[testTag setTagData:data];
	
	// is data size correct
	XCTAssertTrue([testTag.data length] == 177);
	
	// amf data
	NSDictionary *amfObjectDict = (NSDictionary *)testTag.amfObjectData;
	
	// now playing event name
	XCTAssertEqualObjects([amfObjectDict objectForKey:@"type"], @"event");
	XCTAssertEqualObjects([amfObjectDict objectForKey:@"name"], @"NowPlaying");
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// testSetTagData_nowPlaying_GOOD
//
// now playing correct, give artist & song title
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void) testSetTagData_nowPlaying_song_GOOD
{
	FLVScriptObjectTag	*testTag;
    NSData *payload = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"thebravery_payload_good" ofType:@"raw"]];
    NSData *data = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"thebravery_data_good" ofType:@"raw"]];
	
	XCTAssertNotNil(payload, @"payload is NULL");
	XCTAssertNotNil(data, @"data is NULL");
	
	//
	// Empty now playing
	//
	
	// setting payload
	testTag = [[FLVScriptObjectTag alloc] initPayloadWithData:payload];
	
	
	XCTAssertTrue(testTag.type == 18); // datascriptobject
	XCTAssertTrue(testTag.dataSize == 196);
	XCTAssertTrue(testTag.timestamp == 618019062); // datascriptobject
	
	// setting data
	[testTag setTagData:data];
	
	// is data size correct
	XCTAssertTrue([testTag.data length] == 196);
	
	// amf data
	NSDictionary *amfObjectDict = (NSDictionary *)testTag.amfObjectData;
	NSDictionary *parametersDict = (NSDictionary *)[(NSDictionary *)testTag.amfObjectData objectForKey:@"parameters"];
	
	// now playing event name
	XCTAssertEqualObjects([amfObjectDict objectForKey:@"type"], @"event", @"Event type is '%@' and should be ''", [parametersDict objectForKey:@"type"]);
	XCTAssertEqualObjects([amfObjectDict objectForKey:@"name"], @"NowPlaying", @"Event name is '%@' and should be ''", [parametersDict objectForKey:@"name"]);
	
	XCTAssertEqualObjects([parametersDict objectForKey:@"Artist"], @"The Bravery", @"Artist is '%@' and should be 'The Bravery'", [parametersDict objectForKey:@"Artist"]);
	XCTAssertEqualObjects([parametersDict objectForKey:@"Title"], @"Believe", @"Title is '%@' and should be 'Believe'", [parametersDict objectForKey:@"Title"]);
	XCTAssertEqualObjects([parametersDict objectForKey:@"Album"], @"", @"Album is '%@' and should be ''", [parametersDict objectForKey:@"Album"]);
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// testSetTagData_nowPlaying_song_BAD
//
// payload data size is 0
// the TAG is not created and nil is returned
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void) testSetTagData_nowPlaying_song_BAD
{
	FLVScriptObjectTag	*testTag;
	
	// wrong tag type and bigger data size
    NSData *payload = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"badpayload_truncated" ofType:@"raw"]];
    NSData *data = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"thebravery_data_bad" ofType:@"raw"]];
	
	XCTAssertNotNil(payload, @"payload is NULL");
	XCTAssertNotNil(data, @"data is NULL");

	// setting payload
	testTag = [[FLVScriptObjectTag alloc] initPayloadWithData:payload];
	
	XCTAssertNil(testTag, @"tag should be nil");
	
	// setting data
	[testTag setTagData:data];
	XCTAssertNil(testTag.data, @"testTag.data should be nil");
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// testSetTagaData_nowPlaying_song_BAD_String
//
// payload data has a string with the wrong number of bytes.
// the TAG is not created and nil is returned
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=


-(void) testSetTagaData_nowPlaying_song_BAD_String
{
    NSData *payload = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"thebravery_payload_good" ofType:@"raw"]];
    NSData *data = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"thebravery_data_badstring" ofType:@"raw"]];
    
    XCTAssertNotNil(payload, @"payload is NULL");
    XCTAssertNotNil(data, @"data is NULL");
    
    FLVScriptObjectTag *tag = [[FLVScriptObjectTag alloc] initPayloadWithData:payload];
    
    XCTAssertNotNil(tag, @"tag is NULL");
    
    [tag setTagData:data];
    
    XCTAssertNil(tag.data, @"Tag data is not nil");
    
    CuePointEvent *event = [[CuePointEvent alloc] initEventWithAMFObjectData:(NSDictionary*)tag.amfObjectData andTimestamp:0];
    
    XCTAssertNil(event, @"CuePoint event is not nil");
}


@end
