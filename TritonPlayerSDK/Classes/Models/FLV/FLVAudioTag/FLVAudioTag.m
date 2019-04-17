//
//  FLVAudioTag.m
//  iPhoneV2
//
//  Created by Thierry Bucco on 09-03-23.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//

#import "FLVAudioTag.h"
#import "FLVAudioTagHeader.h"
#import "FLVAudioTagData.h"
#import "NSData+FLVUtils.h"

@implementation FLVAudioTag

@synthesize audioHeader;
@synthesize audioTagData;

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// dealloc
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=


//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// description
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (NSString *)description
{
    NSDataFLVUtilsEmptyFunction();
	return @"print audio format";
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// setTagData
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)setTagData:(NSData *)inData
{
	if(!inData)
    {
        return;
    }
	audioHeader		= [[FLVAudioTagHeader alloc] init];
	audioTagData	= [[FLVAudioTagData alloc] init];
	
	[audioHeader setAudioHeaderWithUInt8:[inData getUInt8:0]]; // offset 0];
	
    [audioTagData setAudioDataWithTagData:[NSData dataWithBytes:(UInt8 *)[inData bytes]+1 length:[inData length]-1] forAudioFormat:audioHeader.soundFormat];
	
	
}


//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// saveDataOnDisk
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)saveData:(NSData *)inData
{
	
	if ([[NSFileManager defaultManager] fileExistsAtPath: @"/Users/cpereira/Desktop/data/packetsReceived"] == NO)
	{
		[[NSFileManager defaultManager] createFileAtPath: @"/Users/cpereira/Desktop/data/packetsReceived" contents: nil attributes: nil];
	}
	
	NSFileHandle *outFileHandle = [NSFileHandle fileHandleForWritingAtPath:@"/Users/cpereira/Desktop/data/packetsReceived"];
	[outFileHandle seekToEndOfFile];
	[outFileHandle writeData:inData];
	[outFileHandle synchronizeFile];
}


@end
