//
//  CuePointEventController.h
//  iPhoneV2
//
//  Created by Thierry Bucco on 09-03-26.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CuePointEvent;
@class NowPlayingEvent;


@interface CuePointEventController : NSObject 
{
	NSMutableArray				*cuePointsList;
	id delegate;
}

- (id)initWithDelegate:(id)inDelegate;
- (void)addCuePointEvent:(CuePointEvent *)inCuePointEvent;
- (void)cuePointEventHasBeenExecuted:(CuePointEvent *)inCuePointEvent;
- (void)removeAllCuePointsEvents;
- (int)getNumberOfEvents;

- (void)executeCuePointEvent:(CuePointEvent *)inCuePointEvent;


@end
