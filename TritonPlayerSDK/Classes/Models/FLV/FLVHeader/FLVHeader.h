//
//  FLVHeader.h
//  iPhoneV2
//
//  Created by Thierry Bucco on 09-03-23.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface FLVHeader : NSObject
{
	UInt8		version;
	BOOL		hasAudio;
	BOOL		hasVideo;
	UInt32		dataOffset;
}

- (id)initWithData:(NSData *)inData;

@end
