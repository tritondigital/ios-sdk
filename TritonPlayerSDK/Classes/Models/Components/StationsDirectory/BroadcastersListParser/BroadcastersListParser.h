//
//  BroadcastersListParser.h
//  FLVStreamPlayerLib
//
//  Created by Thierry Bucco on 09-05-27.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StationsDirectory.h"

@class StationsDirectory;

@interface BroadcastersListParser : NSObject <NSXMLParserDelegate>
{
	// xml data and url connection error
	NSData					*xmlData;
	UInt8					parserError;
	StationsDirectory		*stationsDirectoryReceiver;
}

@property (readonly) UInt8 parserError;

- (id)init;
- (void)dealloc;
- (void)getBroadcastersListXMLData;
- (BOOL)getBroadcastersListForStationDirectory:(StationsDirectory *)outStationsDirectory;

@end
