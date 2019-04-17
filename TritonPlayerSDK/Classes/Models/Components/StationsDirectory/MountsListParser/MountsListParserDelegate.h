//
//  MountsListParserDelegate.h
//  FLVStreamPlayerLib
//
//  Created by Thierry Bucco on 09-05-27.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Station;
@class Mount;

@interface MountsListParserDelegate : NSObject <NSXMLParserDelegate>
{
	NSMutableArray		*mountsList;
	Station				*receiverStation;
	
	// For xml parsing
	Mount			*currentMountNode;
	NSString		*currentCallsign;
	NSMutableString *currentPropertyNode;
	
	// xml data and url connection error
	NSData				*xmlData;
}

- (id)initWithStation:(Station *)theReceiverObject;

@end
