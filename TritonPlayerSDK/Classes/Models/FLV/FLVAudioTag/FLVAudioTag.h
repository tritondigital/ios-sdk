//
//  FLVAudioTag.h
//  iPhoneV2
//
//  Created by Thierry Bucco on 09-03-23.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FLVTag.h"

@class FLVAudioTagHeader;
@class FLVAudioTagData;

@interface FLVAudioTag : FLVTag 
{
	FLVAudioTagHeader	*audioHeader;
	FLVAudioTagData		*audioTagData;
}

@property (nonatomic, strong) FLVAudioTagHeader		*audioHeader;
@property (nonatomic, strong) FLVAudioTagData		*audioTagData;

- (NSString *)description;
- (void)setTagData:(NSData *)inData;
- (void)saveData:(NSData *)inData;

@end
