//
//  FLVAudioTagHeader.h
//  FLVStreamPlayerLib
//
//  Created by Thierry Bucco on 09-04-24.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//

#import <Foundation/Foundation.h>

enum
{
	kLinearPCM				= 0,
	kADPCM					= 1,
	kMP3					= 2,
	kLinearPCMLE			= 3,
	kNellyMoser16kHzMono	= 4,
	kNellyMoser8kHzMono		= 5,
	kNellyMoser				= 6,
	kG711A_Law				= 7,
	kG711Mu_Law				= 8,
	kReserved				= 9,
	kAAC					= 10,
	kSpeex					= 11,
	kMP3_8kHz				= 14,
	kDeviceSpecificSound	= 15	
};
typedef NSInteger FLVSoundFormatTypes;

enum
{
	k5_5kHz					= 0,
	k11kHz					= 1,
	k22kHz					= 2,
	k44kHz					= 3
};
typedef NSInteger FLVSoundRates;

enum
{
	k8Bit					= 0,
	k16Bit					= 1
};
typedef NSInteger FLVSoundSizes;

enum
{
	kMono					= 0,
	kStereo					= 1
};
typedef NSInteger FLVSoundTypes;

	
@interface FLVAudioTagHeader : NSObject 
{
	FLVSoundFormatTypes soundFormat;
	FLVSoundRates		soundRate;
	FLVSoundSizes		soundSize;
	FLVSoundTypes		soundType;
}

@property (assign) FLVSoundFormatTypes	soundFormat;
@property (assign) FLVSoundRates		soundRate;
@property (assign) FLVSoundSizes		soundSize;
@property (assign) FLVSoundTypes		soundType;

- (void)setAudioHeaderWithUInt8:(UInt8)inValue;

@end
