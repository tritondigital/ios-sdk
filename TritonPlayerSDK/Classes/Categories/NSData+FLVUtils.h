//
//  NSData+FLVUtils.h
//  iPhoneV2
//
//  Created by Thierry Bucco on 09-03-24.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//

#import <Foundation/Foundation.h>

// Fix for loading category symbol
void NSDataFLVUtilsEmptyFunction();

@interface NSData (FLVUtils)

- (NSString *)hexadecimalRepresentation;
- (UInt8)getUInt8:(int)offset;
- (unsigned int)getUInt24:(int)offset;
- (unsigned int)getUInt32:(int)offset;

@end
