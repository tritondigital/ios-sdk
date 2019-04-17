//
//  FLVHeader.m
//  iPhoneV2
//
//  Created by Thierry Bucco on 09-03-23.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//

#import "FLVHeader.h"


@implementation FLVHeader

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// initWithData
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (id)initWithData:(NSData *)inData
{	
	
	self = [super init];
	if (self && inData)
	{
		UInt8 *lVersion = malloc(sizeof(UInt8));
		UInt8 *lTypeFlags = malloc(sizeof(UInt8));
		UInt8 *lDataOffset = malloc(sizeof(UInt8));
		
		// get version
		[inData getBytes:lVersion range:NSMakeRange(3, 1)];
		version =  *lVersion;
		
		// get typeFlags
		[inData getBytes:lTypeFlags range:NSMakeRange(4, 1)];
		
		hasAudio = *lTypeFlags & 0x4;
		hasVideo = *lTypeFlags & 0x1;
		
		// get DataOffset
		[inData getBytes:lDataOffset range:NSMakeRange(8, 1)];
		dataOffset = *lDataOffset;
		
		free(lVersion);
		free(lTypeFlags);
		free(lDataOffset);
	}
	
	return self;
}

@end
