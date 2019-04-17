//
//  ADTSHeaderSharedData.h
//  FLVStreamPlayerLib
//
//  Created by Thierry Bucco on 09-04-28.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ADTSHeaderSharedData : NSObject 
{
	unsigned char	*AudioSpecificConfig;
}

@property (readonly) unsigned char	*AudioSpecificConfig;

- (void)setAudioSpecificConfig:(unsigned char	*)inAudioSpecificConfig size:(NSInteger)audioSpecificSize;
- (void)dealloc ;
+ (ADTSHeaderSharedData*)sharedADTSHeaderManager;
+ (id)allocWithZone:(NSZone *)zone;
- (id)copyWithZone:(NSZone *)zone;

@end
