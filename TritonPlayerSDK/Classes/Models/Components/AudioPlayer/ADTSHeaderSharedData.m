//
//  ADTSHeaderSharedData.m
//  FLVStreamPlayerLib
//
//  Created by Thierry Bucco on 09-04-28.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//

#import "ADTSHeaderSharedData.h"


@implementation ADTSHeaderSharedData

@synthesize AudioSpecificConfig;

- (void)setAudioSpecificConfig:(unsigned char*)inAudioSpecificConfig size:(NSInteger)audioSpecificSize
{
	if (AudioSpecificConfig == NULL)
		AudioSpecificConfig = malloc(audioSpecificSize);
	
	memcpy(AudioSpecificConfig, inAudioSpecificConfig, audioSpecificSize);
}

- (void)dealloc 
{
    free(AudioSpecificConfig);
}

static ADTSHeaderSharedData *sharedADTSHeaderManager = nil;

+ (ADTSHeaderSharedData*)sharedADTSHeaderManager
{
    static dispatch_once_t once;
    static id sharedInstance;
    
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized(self) {
        if (sharedADTSHeaderManager == nil) 
		{
            sharedADTSHeaderManager = [super allocWithZone:zone];
            return sharedADTSHeaderManager;  // assignment and return on first allocation
        }
    }
    return nil; //on subsequent allocation attempts return nil
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

@end
