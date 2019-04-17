//
//  MountsListParser.h
//  FLVStreamPlayerLib
//
//  Created by Thierry Bucco on 09-05-27.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StationsDirectory.h"

@class Station;

@interface MountsListParser : NSObject 
{
	// xml data and url connection error
	NSData					*xmlData;
	UInt8					parserError;
	Station					*stationReceiver;
}

@property (readonly) UInt8 parserError;

- (id)init;
- (void)dealloc;
- (void)getMountsListXMLDataForStation:(Station *)inStation;
- (BOOL)getFLVMountsListForStation:(Station *)outStation;

@end
