//
//  FLVDecoder.h
//  iPhoneV2
//
//  Created by Thierry Bucco on 09-03-23.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TDFLVPlayer.h"

enum
{
	kFillingFlvHeader = 0,
	kFillingPreviousTagSize = 1,
	kFillingTagPayload = 2,
	kFillingTagData = 3
};
typedef NSInteger FillingMode;


@class FLVTag;
@class FLVHeader;
@class TritonPlayer;

@interface FLVDecoder : NSObject
{
	TDFLVPlayer	*streamController;
	FLVTag				*currentFLVTag;
	
	FillingMode fillingWhat;

	NSTimeInterval	timestampReference;
	UInt8			*tmpFLVHeaderBytes;
	UInt8			*tmpTagPayloadBytes;
	UInt8			*tmpTagDataBytes;
}

@property (nonatomic,strong) FLVTag *currentFLVTag;

- (id)initWithStreamController:(id)inStreamController;
- (void)decodeStreamData:(NSData *)inData;
- (void)clear;

@end
