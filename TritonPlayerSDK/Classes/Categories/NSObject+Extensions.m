//
//  NSObject-iPhoneExtensions.h
//  iPhoneV2
//
//  Created by Thierry Bucco on 09-03-26.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//

#import "NSObject+Extensions.h"

// Fix for loading category symbol
void NSObjectExtensionsEmptyFunction() {}

@implementation NSObject (Extensions)

- (NSString *)className
{
	return NSStringFromClass([self class]);
}

@end