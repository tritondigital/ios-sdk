//
//  TDMediaPlayerTest.m
//  TritonPlayerSDKTests
//
//  Created by Mahamada Kabore on 2017-11-20.
//  Copyright © 2017 Triton Digital. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TDMediaPlayer.h"
#import "TDMediaPlaybackDelegate.h"

@interface TDMediaPlayerTest : XCTestCase<TDMediaPlaybackDelegate>

@end

@implementation TDMediaPlayerTest

BOOL isActive;
XCTestExpectation *myExpectation;

- (void)setUp {
    [super setUp];
    isActive = YES;
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    isActive=  NO;
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testCanPlay {
    myExpectation = [self expectationWithDescription:@"MediaPlayer Play "];
    
    [NSThread detachNewThreadSelector:@selector(startPlay) toTarget:self withObject:nil];
    
    [[NSRunLoop currentRunLoop] addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
    
    while (isActive) {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.30, FALSE);
    }
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError * _Nullable error) {
       
    }];
}

-(void) startPlay
{
    NSString *url = @"https://ia802508.us.archive.org/5/items/testmp3testfile/mpthreetest.mp3";
    NSDictionary *settings = @{SettingsMediaPlayerStreamURLKey : url };
    TDMediaPlayer *player = [[TDMediaPlayer alloc] initWithSettings:settings];
    player.delegate = self;
    [player play];
}

-(void)mediaPlayer:(id<TDMediaPlayback>)player didChangeState:(TDPlayerState)newState
{
    [myExpectation fulfill];
    isActive = FALSE;
}

@end
