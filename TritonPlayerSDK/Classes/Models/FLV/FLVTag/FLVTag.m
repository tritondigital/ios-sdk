//
//  FLVTag.m
//  iPhoneV2
//
//  Created by Thierry Bucco on 09-03-23.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//

#import "FLVTag.h"
#import "NSData+FLVUtils.h"

@implementation FLVTag

@synthesize type;
@synthesize dataSize;
@synthesize timestamp;
@synthesize timestampReference;
@synthesize data;

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// dealloc
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=


//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// initWithData
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (id)initPayloadWithData:(NSData *)inData
{	
	if ([inData length] < kFlvPayloadSize) return nil;
		
	
	self = [super init];
	if (self)
	{
        NSDataFLVUtilsEmptyFunction();
        
		UInt32 lTimestamp;
		UInt32 lTimestampExt;
		
		// get tag type
		type = [inData getUInt8:0]; // offset 0
		
		// get datasize
		dataSize = [inData getUInt24:1]; // offset 1
		
		lTimestamp = [inData getUInt24:4]; // offset 4
		lTimestampExt = [inData getUInt8:7];
		
		timestamp = lTimestamp + (lTimestampExt << 24);	
	}
	
	return self;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// setTagData
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)setTagData:(NSData *)inData
{
	self.data = inData;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// description
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (NSString *)description
{
	return @"needs to be implemented";
}

@end
