//
//  FLVTag.h
//  iPhoneV2
//
//  Created by Thierry Bucco on 09-03-23.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kFlvHeaderSize			9
#define kFlvPayloadSize			11
#define kFlvPreviousTagSize		4

enum
{
	AUDIODATA			= 8,
	VIDEODATA			= 9,
	SCRIPTDATAOBJECT	= 18
};
typedef NSInteger FLVTagTypes;


@interface FLVTag : NSObject 
{
	// payload
	FLVTagTypes			type;
	UInt32				dataSize;
	NSTimeInterval      timestamp;
	NSTimeInterval		timestampReference; // when stream connects, this is the base 
	// data
	NSData				*data;
}

@property (strong) NSData	*data; // we want the setter atomic
@property FLVTagTypes       type;
@property UInt32            dataSize;
@property NSTimeInterval    timestamp;
@property NSTimeInterval    timestampReference;

- (id)initPayloadWithData:(NSData *)inData;
- (void)setTagData:(NSData *)inData;
- (NSString *)description;

@end
