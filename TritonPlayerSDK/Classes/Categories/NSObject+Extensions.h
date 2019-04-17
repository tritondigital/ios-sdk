//
//  NSObject-iPhoneExtensions.h
//  iPhoneV2
//
//  Created by Thierry Bucco on 09-03-26.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//

#import <Foundation/Foundation.h>

// Fix for loading category symbol
void NSObjectExtensionsEmptyFunction();

@interface NSObject (Extensions)
- (NSString *)className;
@end