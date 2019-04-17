//
//  FLVTagTest.m
//  FLVStreamPlayerLib
//
//  Created by Thierry Bucco on 09-04-22.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CuePointEvent.h"
#import "FLVDispatcher.h"
#import "CuePointEventController.h"
#import "AudioPlayerController.h"
#import "FLVScriptObjectTag.h"
#import "testConstants.h"


@interface FLVDispatcherTest : XCTestCase <TDFLVMetaDataDelegate>
@end

@implementation FLVDispatcherTest


- (void) testDispatchNewTagOnMetadata
{
    FLVScriptObjectTag    *testTag;
    FLVDispatcher *flvDispatcher;
    CuePointEventController *cuePointEventController;
    AudioPlayerController    *audioPlayerController;

    audioPlayerController = [[AudioPlayerController alloc] initWithDelegate:self];
    cuePointEventController = [[CuePointEventController alloc] initWithDelegate:self];

    flvDispatcher = [[FLVDispatcher alloc] initWithCuePointEventController:cuePointEventController andAudioPlayerController:audioPlayerController];
		[flvDispatcher setTDFLVMetaDataDelegate:self];

    //new tag
    NSData *payload = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"cleared_payload_good" ofType:@"raw"]];
    NSData *data = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"onMetaData_StreamTitle_NotEmpty" ofType:@"flv"]];
    testTag = [[FLVScriptObjectTag alloc] initPayloadWithData:payload];
    [testTag setTagData:data];
    testTag.amfObjectName = @"onMetaData";

    [flvDispatcher dispatchNewTag:testTag];
		
		
}

-(void) didReceiveMetaData: (NSDictionary *)metaData
{
		XCTAssertNotNil(metaData);
		XCTAssertNotNil([metaData objectForKey:@"StreamTitle"]);
}



@end

