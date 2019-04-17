//
//  FLVScriptObjectTag.h
//  iPhoneV2
//
//  Created by Thierry Bucco on 09-03-23.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FLVTag.h"

@interface FLVScriptObjectTag : FLVTag 
{
	NSString	*amfObjectName;
	id			amfObjectData;
}

@property (strong) NSString *amfObjectName;
@property (strong) NSString *amfObjectData;


- (NSString *)description;
- (void)decodeAMF;

@end
