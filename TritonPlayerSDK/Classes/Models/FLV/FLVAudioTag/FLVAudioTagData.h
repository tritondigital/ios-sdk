//
//  FLVAudioTagData.h
//  FLVStreamPlayerLib
//
//  Created by Thierry Bucco on 09-04-24.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FLVAudioTagHeader.h"

enum
{
	kSequenceHeader			= 0,
	kRaw					= 1
};
typedef NSInteger FLVAudioPacketTypes;

	
@interface FLVAudioTagData : NSObject 
{
	FLVAudioPacketTypes	packetType;
	NSData				*audioData;
}

@property (assign) FLVAudioPacketTypes	packetType;
@property (nonatomic,strong) NSData	*audioData;

- (void)setAudioDataWithTagData:(NSData *)inData forAudioFormat:(FLVSoundFormatTypes)inSoundFormat;
- (unsigned char *)createADTSHeaderFromSpecificConfig:( const unsigned char *)inAudioSpecificConfig dataLen:(int)inDataLen;
- (void)saveAudioPacketOnDisk;

@end
