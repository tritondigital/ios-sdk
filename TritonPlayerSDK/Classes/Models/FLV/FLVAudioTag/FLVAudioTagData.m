//
//  FLVAudioTagData.m
//  FLVStreamPlayerLib
//
//  Created by Thierry Bucco on 09-04-24.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//

#import "FLVAudioTagData.h"
#import "FLVAudioTagHeader.h"
#import "NSData+FLVUtils.h"
#import "ADTSHeaderSharedData.h"

@implementation FLVAudioTagData

@synthesize packetType;
@synthesize audioData;

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// dealloc
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=


//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// setAudioDataWithData
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)setAudioDataWithTagData:(NSData *)inData forAudioFormat:(FLVSoundFormatTypes)inSoundFormat
{
    if(!inData)
    {
        return;
    }
    
    
    NSDataFLVUtilsEmptyFunction();
	
	if (inSoundFormat == kAAC)
	{
		ADTSHeaderSharedData *adtsHeaderSharedDataManager = [ADTSHeaderSharedData sharedADTSHeaderManager];
		
		packetType = [inData getUInt8:0];
		if (packetType == kSequenceHeader)
		{
			// save AudioSpecificConfig in sharedDataManager
            const NSInteger configSize = [inData length]-1;
			[adtsHeaderSharedDataManager setAudioSpecificConfig:(UInt8 *)[[inData subdataWithRange:NSMakeRange(1, configSize)] bytes] size:configSize];
		}
		else
		{
			// create ADTS header
			unsigned char *lADTSHeader = [self createADTSHeaderFromSpecificConfig:adtsHeaderSharedDataManager.AudioSpecificConfig dataLen:(int)([inData length]-1)];
						
			// create aac audio data container
			NSMutableData *aacAudio = [NSMutableData dataWithCapacity:[inData length]+7];
			
			// put ADTS header
			[aacAudio appendData:[NSData dataWithBytesNoCopy:lADTSHeader length:7 freeWhenDone:YES]];
			
			// put raw audio data
			[aacAudio appendData:[NSData dataWithBytes:(UInt8 *)[inData bytes]+1 length:[inData length]-1]];
			
			self.audioData = aacAudio;
            lADTSHeader= nil;
		}
	}
	else
	{
		packetType = kRaw; // always raw data
		
		self.audioData = [NSData dataWithBytes:(UInt8 *)[inData bytes] length:[inData length]];
	}
	
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// createADTSHeaderFromSpecificConfig
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (unsigned char *)createADTSHeaderFromSpecificConfig:( const unsigned char *)inAudioSpecificConfig dataLen:(int)inDataLen
 {
	 static const NSInteger headerSize = 7;
     unsigned char *ADTSHeader = malloc(headerSize);
	 memset(ADTSHeader,0,headerSize);
	 
	 unsigned objectType = (inAudioSpecificConfig[0]>>3)-1;
	 unsigned freqIdx = ((inAudioSpecificConfig[0]&0x07)<<1)|((inAudioSpecificConfig[1]&0x80)>>7); // 7
	 unsigned channelCfg = (inAudioSpecificConfig[1] & 0x78) >> 3;
	 
	 //
	 // channel cfg is 4 bits in the setup data but since it is 3 in ADTS, we shrink the field here.
	 //
	 
	 ADTSHeader[0] = 0xFF;
	 ADTSHeader[1] = 0xF1;
	 ADTSHeader[1] &= 0xF7; // MP2
	 ADTSHeader[2] = (unsigned char)((objectType<<6) | ((freqIdx&0x0F)<<2) | 0x02 | (channelCfg>>2));
	 ADTSHeader[3] = (unsigned char)(channelCfg<<6);
	 
	 unsigned l = inDataLen;
	 l += 7;
	 
	 ADTSHeader[3] |= (l & 0x1800) >> 11;
	 // frame size continued over full byte
	 ADTSHeader[4] = (unsigned char)((l & 0x1FF8) >> 3);
	 // frame size continued first 3 bits
	 ADTSHeader[5] = (unsigned char)((l & 0x7) << 5);
	 // buffer fullness (0x7FF for VBR) over 5 last bits
	 ADTSHeader[5] |= 0x1F;
	 // buffer fullness (0x7FF for VBR) continued over 6 first bits + 2 zeros for
	 // number of raw data blocks
	 ADTSHeader[6] = 0xFC;

	 return ADTSHeader;
}
 
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// saveAudioPacketOnDisk
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)saveAudioPacketOnDisk
{
	// Create the output file first if necessary
	
	if (packetType == kRaw)
	{
		if ([[NSFileManager defaultManager] fileExistsAtPath: @"/Users/thierry/Desktop/data/rawAudioData"] == NO)
		{
			[[NSFileManager defaultManager] createFileAtPath: @"/Users/thierry/Desktop/data/rawAudioData" contents: nil attributes: nil];
		}
		
		NSFileHandle *outFileHandle = [NSFileHandle fileHandleForWritingAtPath:@"/Users/thierry/Desktop/data/rawAudioData"];
		[outFileHandle seekToEndOfFile];
		[outFileHandle writeData:self.audioData];
		[outFileHandle synchronizeFile];
	}
}

@end
