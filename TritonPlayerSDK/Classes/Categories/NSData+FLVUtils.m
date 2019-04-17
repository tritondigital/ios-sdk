//
//  NSData+FLVUtils.m
//  iPhoneV2
//
//  Created by Thierry Bucco on 09-03-24.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//

#import "NSData+FLVUtils.h"

// Fix for loading category symbol
void NSDataFLVUtilsEmptyFunction() {}

@implementation NSData (FLVUtils)

- (NSString *)hexadecimalRepresentation
{
	NSMutableString *lHexadecimalRepresentation = [NSMutableString stringWithCapacity:0];
	for (int i=0; i<[self length]; i++)
	{
		[lHexadecimalRepresentation appendFormat:@"%02X ", [self getUInt8:i]];
	}
	return lHexadecimalRepresentation;
}

- (UInt8)getUInt8:(int)offset
{
	UInt8 *lValue = (UInt8 *)([self bytes] + offset);
	int theval = ((int) (lValue[0])) & 0xFFFFFFFF;
	return (UInt8)theval;
}

- (unsigned int)getUInt24:(int)offset
{
	UInt8 *lValue = (UInt8 *)([self bytes] + offset);	
	int theval = ((int) (lValue[0] << 16 | lValue[1] << 8  | lValue[2])) & 0xFFFFFFFF;
	return theval;
}
	
- (unsigned int)getUInt32:(int)offset
{
	UInt8 *lValue = (UInt8 *)([self bytes] + offset);
	int theval = ((int) (lValue[0] << 24 | lValue[1] << 16  | lValue[2] << 8 | lValue[3])) & 0xFFFFFFFF;
	return theval;
}	


@end
