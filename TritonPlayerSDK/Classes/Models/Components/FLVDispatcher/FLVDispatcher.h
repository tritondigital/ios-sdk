//
//  FLVDispatcher.h
//  iPhoneV2
//
//  Created by Thierry Bucco on 09-03-23.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FLVTag;
@class CuePointEventController;
@class AudioPlayerController;

@interface FLVDispatcher : NSObject
{
		CuePointEventController		*cuePointEventController;
		AudioPlayerController			*audioPlayerController;
		
		id                      	metaDataDelegate;
}

- (id)initWithCuePointEventController:(CuePointEventController *)inCuePointEventController andAudioPlayerController:(AudioPlayerController *)inAudioPlayerController;
- (void)dispatchNewTag:(FLVTag *)inTag;

- (void) setTDFLVMetaDataDelegate:(id) delegate;

@end


@protocol TDFLVMetaDataDelegate <NSObject>

@optional
-(void) didReceiveMetaData: (NSDictionary *)metaData;

@end
