//
//  FLVDecoder.m
//  iPhoneV2
//
//  Created by Thierry Bucco on 09-03-23.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//

#import "FLVDispatcher.h"
#import "FLVTag.h"
#import "FLVAudioTag.h"
#import "FLVAudioTagData.h"
#import "FLVScriptObjectTag.h"
#import "CuePointEvent.h"
#import "CuePointEventProtected.h"
#import "CuePointEventController.h"
#import "AudioPlayerController.h"

#define kEventTypeKey @"type"
#define kEventType @"event"

@implementation FLVDispatcher

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// init
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (id)initWithCuePointEventController:(CuePointEventController *)inCuePointEventController andAudioPlayerController:(AudioPlayerController *)inAudioPlayerController
{
	self = [super init];
	if (self)
	{
		if (inCuePointEventController)
		{
			cuePointEventController = inCuePointEventController;
			audioPlayerController = inAudioPlayerController;
		}
		else
		{
			[NSException raise:@"FLVDispatcherCuePointEventController" format:@"cuePointEventController cannot be nil"];
		}
	}
	return self;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// dispatchNewTag
/// PUBLIC API - called by TDFLVPlayer's sendTagToDispatcher: method on the TritonPlayer thread.
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)dispatchNewTag:(FLVTag *)inTag
{
	FLVAudioTag				*lAudioTag;
	FLVScriptObjectTag		*lScriptTag;
	
	switch (inTag.type)
	{
		case AUDIODATA:
			lAudioTag = (FLVAudioTag *)inTag;
			
			if (lAudioTag.audioTagData.packetType == kRaw)
			{
				[audioPlayerController addAudioTag:lAudioTag];
			}
            break;
            
		case SCRIPTDATAOBJECT:
			
			lScriptTag = (FLVScriptObjectTag *)inTag;
			
            // We need the bitate if found
            if ( [lScriptTag.amfObjectName isEqualToString:@"onMetaData"] )
            {
                NSString *bitrate = [(NSDictionary *)lScriptTag.amfObjectData objectForKey:@"audiodatarate"];
                if ( bitrate )
                {
                    [audioPlayerController setBitrate:[bitrate intValue]];
                }
								
								if( metaDataDelegate ){
										[metaDataDelegate didReceiveMetaData: (NSDictionary *)lScriptTag.amfObjectData];
								}
            }
            
			// we need to determine event type
			if ([lScriptTag.amfObjectData respondsToSelector:@selector(objectForKey:)])
			{
				NSString *eventType = [(NSDictionary *)lScriptTag.amfObjectData objectForKey:kEventTypeKey];
				
				if ([eventType isEqualToString:kEventType] == TRUE)
				{
						// create a CuePointEvent object
					
						// the firedate is the timestamp.
						// it calculated from current tag timestamp minus timestamp base of the begining stream
                    
						NSTimeInterval nowTimeStamp = [NSDate timeIntervalSinceReferenceDate];
						NSTimeInterval secondsDiff = (nowTimeStamp - lScriptTag.timestampReference);
						NSTimeInterval lExecutionSeconds = (lScriptTag.timestamp / 1000) - secondsDiff;
						
						if (lExecutionSeconds < 0.0f)
						{
								lExecutionSeconds = 0.0f;
						}
						
						CuePointEvent *lCuePointEvent = [[CuePointEvent alloc] initEventWithAMFObjectData:(NSDictionary *)lScriptTag.amfObjectData andTimestamp:lExecutionSeconds];

					if (lCuePointEvent)
					{
						[lCuePointEvent setCuePointEventController:cuePointEventController]; // will indicate when execution is finished from view controller
						// add event to events manager
							
						[cuePointEventController addCuePointEvent:lCuePointEvent];
						// released after execution
					}
				}
			}
			
            break;
            
		case VIDEODATA:
            break;
			
		default:
            break;
	}
}


- (void) setTDFLVMetaDataDelegate:(id) delegate
{
		metaDataDelegate = delegate;
}

@end
