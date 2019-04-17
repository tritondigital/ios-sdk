//
//  CuePointEventController.m
//  iPhoneV2
//
//  Created by Thierry Bucco on 09-03-26.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//

#import "CuePointEventController.h"
#import "CuePointEvent.h"
#import "CuePointEventProtected.h"
#import "Logs.h"

@implementation CuePointEventController

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// init
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (id)initWithDelegate:(id)inDelegate
{
	self = [super init];
	if (self)
	{
		cuePointsList = [[NSMutableArray alloc] init];
		delegate = inDelegate;
	}
	return self;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// dealloc
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=


//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// addCuePointEvent
/// PUBLIC API - called by FLVDispatcher on the TritonPlayer thread
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)addCuePointEvent:(CuePointEvent *)inCuePointEvent
{
	if (inCuePointEvent != nil)
	{
		@synchronized(cuePointsList)
		{
			[cuePointsList addObject:inCuePointEvent];
		}

		// Call this outside the synchronize since it might call us back immediately
		[inCuePointEvent startTimer];
	}
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// executeCuePointEvent
//
// event to execute call this method, then we delegate this message to controller which respond to events
// execute selector on main thread, since delegate will change UI
///
///
/// PUBLIC API - called by CuePointEvent on the TritonPlayer thread
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)executeCuePointEvent:(CuePointEvent *)inCuePointEvent
{
    if ( [delegate respondsToSelector:@selector(executeCuePointEvent:)] ) 
    {
		[delegate performSelectorOnMainThread:@selector(executeCuePointEvent:) withObject:inCuePointEvent waitUntilDone:NO];
    }
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// cuePointEventHasBeenExecuted
/// PUBLIC API - called (very indirectly) by CuePointEvent on the main thread (see executeCuePointEvent: above)
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)cuePointEventHasBeenExecuted:(CuePointEvent *)inCuePointEvent
{
	FLOG(@"Event released");
	
	// several events could potentially call this method at the same time, by timer
	@synchronized(cuePointsList)
	{
		NSInteger cuePointIdx = [cuePointsList indexOfObject:inCuePointEvent];
	
		if (cuePointIdx != NSNotFound)
		{
			[cuePointsList removeObjectAtIndex:cuePointIdx];
			inCuePointEvent.executionCanceled = TRUE;
			// event is released when removed from array
			inCuePointEvent = nil;
		}
	}
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// removeAllCuePointsEvents
/// PUBLIC API - called by TDFLVPlayer on the TritonPlayer thread
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)removeAllCuePointsEvents
{
	CuePointEvent *lCuePoint;
	// in stations dictionary

	@synchronized(cuePointsList)
	{
		int cpt = 0;
		for (cpt = 0; cpt < [cuePointsList count]; cpt++)
		{
			lCuePoint = [cuePointsList objectAtIndex:cpt];
			
			if (lCuePoint)
			{
				lCuePoint.executionCanceled = TRUE;
				// event will be released after execution
			}
		}
		
		if ([cuePointsList count] > 0)
		{
			[cuePointsList removeAllObjects];
		}
	}

	FLOG(@"done : %lu", (unsigned long)[cuePointsList count]);
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// getNumberOfEvents
/// PUBLIC API - called by test code only
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (int)getNumberOfEvents
{
	@synchronized(cuePointsList)
	{
		return (int)[cuePointsList count];
	}
}



@end
