//
//  FLVDecoder.m
//  iPhoneV2
//
//  Created by Thierry Bucco on 09-03-23.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//

#import "FLVDecoder.h"
#import "FLVAudioTag.h"
#import "FLVAudioTagHeader.h"
#import "FLVScriptObjectTag.h"
#import "TritonPlayer.h"
#import "TritonPlayerProtected.h"
#import "FLVVideoTag.h"
#import "NSData+FLVUtils.h"
#import "FLVTag.h"


@interface FLVDecoder (Private)

- (FLVTag *)tagWithPayload:(NSData *)inPayload;

@end



@implementation FLVDecoder

@synthesize currentFLVTag;

static int currentFLVHeaderSize = 0;
static int currentPreviousTagSize = 0;
static int currentTagPayloadSize = 0;
static int currentTagDataSize = 0;


//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// init
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (id)initWithStreamController:(id)inStreamController
{
	self = [super init];
	if (self)
	{
        NSDataFLVUtilsEmptyFunction();
        streamController = inStreamController;
		
		tmpFLVHeaderBytes = nil;
		tmpTagPayloadBytes = nil;
		tmpTagDataBytes = nil;
	}

	return self;
}


//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// dealloc
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)dealloc
{
	if (streamController)
	{
		streamController = nil;
	}
}


//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// decodeStreamData
/// PUBLIC API - called by FLVStream's connection:didReceiveData: handler, on the TritonPlayer thread
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)decodeStreamData:(NSData *)inData
{
    if (!inData)
    {
        return;
    }
    
	int offset = 0;
	UInt8 *aByte;
	UInt8 *lBytes = (UInt8 *)[inData bytes];
	
	@synchronized(self)
	{
		while (offset < [inData length])
		{
			aByte = lBytes+offset;
			
			switch(fillingWhat)
			{
				case kFillingFlvHeader:
					
					if (!tmpFLVHeaderBytes)
					{
						tmpFLVHeaderBytes = malloc(kFlvHeaderSize);
					}
					
					if (currentFLVHeaderSize < kFlvHeaderSize)
					{
						tmpFLVHeaderBytes[currentFLVHeaderSize]=*aByte;
						currentFLVHeaderSize += 1;
						
						if (currentFLVHeaderSize == kFlvHeaderSize)
						{
							[streamController setStreamHeader:[NSData dataWithBytesNoCopy:tmpFLVHeaderBytes length:currentFLVHeaderSize freeWhenDone:YES]];
							tmpFLVHeaderBytes = nil;
							currentFLVHeaderSize = 0;
							
							fillingWhat = kFillingPreviousTagSize;
						}
					}
					
					break;
					
				case kFillingPreviousTagSize:
					
					if (currentPreviousTagSize < kFlvPreviousTagSize)
					{
						currentPreviousTagSize += 1;
						
						if (currentPreviousTagSize == kFlvPreviousTagSize)
						{
							currentPreviousTagSize = 0;
							fillingWhat = kFillingTagPayload;
						}
					}
					
					break;
					
				case kFillingTagPayload:
					
					if (!tmpTagPayloadBytes)
					{
						tmpTagPayloadBytes = malloc(kFlvPayloadSize);
					}
					
					if (currentTagPayloadSize < kFlvPayloadSize)
					{
						tmpTagPayloadBytes[currentTagPayloadSize]=*aByte;
						currentTagPayloadSize += 1;
						
						if (currentTagPayloadSize == kFlvPayloadSize)
						{
							currentFLVTag = [self tagWithPayload:[NSData dataWithBytesNoCopy:tmpTagPayloadBytes length:currentTagPayloadSize freeWhenDone:YES]];
							tmpTagPayloadBytes = nil;

							if (currentFLVTag == nil)
							{
								// error
								return;
								break;
							}

							if (timestampReference == 0.0f)
							{
								timestampReference = [NSDate timeIntervalSinceReferenceDate];
							}
							
							currentFLVTag.timestampReference = timestampReference;
							
							currentTagPayloadSize = 0;
							
							fillingWhat = kFillingTagData;
						}
					}
					
					break;
					
				case kFillingTagData:
					
					if (!tmpTagDataBytes)
					{
						tmpTagDataBytes  = malloc(currentFLVTag.dataSize);
					}
					
					if (currentTagDataSize < currentFLVTag.dataSize)
					{
						tmpTagDataBytes[currentTagDataSize]=*aByte;
						currentTagDataSize += 1;
						
						if (currentTagDataSize == currentFLVTag.dataSize)
						{
							//[currentFLVTag setTagData:[NSData dataWithBytes:tmpTagDataBytes length:currentTagDataSize]];
 							[currentFLVTag setTagData:[NSData dataWithBytesNoCopy:tmpTagDataBytes length:currentTagDataSize freeWhenDone:YES]];
                            
							//free(tmpTagDataBytes);
							tmpTagDataBytes = nil;
							currentTagDataSize = 0;
							
							[streamController sendTagToDispatcher:currentFLVTag];
							
							currentFLVTag = nil;
							
							fillingWhat = kFillingPreviousTagSize;
						}
					}
					
					break;
			}

			offset++;
		}
	}
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// tagWithPayload
/// PRIVATE API
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (FLVTag *)tagWithPayload:(NSData *)inPayload
{
    FLVTag *newTag = nil;
    
    if (!inPayload)
    {
        return newTag;
    }

	// get tag type
	int lType = [inPayload getUInt8:0]; // offset 0
	
	switch(lType)
	{
		case SCRIPTDATAOBJECT:
			newTag = [[FLVScriptObjectTag alloc] initPayloadWithData:inPayload];
			break;
			
		case AUDIODATA:
			newTag = [[FLVAudioTag alloc] initPayloadWithData:inPayload];
			break;
			
		case VIDEODATA:
			newTag = [[FLVVideoTag alloc] initPayloadWithData:inPayload];
			break;

		default:
			NSLog(@"Unknown/unsupported FLV tag type %d", lType);
			break;
	}

	return newTag;
}


//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// clear
/// PUBLIC API - called by TDFLVPLayer's isExecutingNotificationReceived: handler, on the TritonPlayer-AudioPlayer
/// thread normally, but seen at least once on an NSOperationQueue thread
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)clear
{
	@synchronized(self)
	{
		currentFLVHeaderSize = 0;
		currentPreviousTagSize = 0;
		currentTagPayloadSize = 0;
		currentTagDataSize = 0;
        timestampReference = 0;

		if (tmpFLVHeaderBytes)
		{
			free(tmpFLVHeaderBytes);
			tmpFLVHeaderBytes = nil;
		}

		if (tmpTagPayloadBytes)
		{
			free(tmpTagPayloadBytes);
			tmpTagPayloadBytes = nil;
		}

		if (tmpTagDataBytes)
		{
			free(tmpTagDataBytes);
			tmpTagDataBytes = nil;
		}


		fillingWhat = kFillingFlvHeader;
	}
}

@end
