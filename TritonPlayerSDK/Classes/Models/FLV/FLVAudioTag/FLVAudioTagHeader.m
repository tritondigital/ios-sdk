//
//  FLVAudioTagHeader.m
//  FLVStreamPlayerLib
//
//  Created by Thierry Bucco on 09-04-24.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//

#import "FLVAudioTagHeader.h"


@implementation FLVAudioTagHeader

@synthesize soundFormat;
@synthesize soundRate;
@synthesize soundSize;
@synthesize soundType;

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// setAudioHeaderWithData
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)setAudioHeaderWithUInt8:(UInt8)inValue
{	
	soundFormat = (inValue & 0xF0) >> 4;
	soundRate	= (inValue & 0xC) >> 2;
	soundSize	= (inValue & 0x2) >> 1;
	soundType	= inValue & 0x1;
}

@end
