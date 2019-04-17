//
//  StationsListParserDelegate.h
//  FLVStreamPlayerLib
//
//  Created by Thierry Bucco on 09-05-27.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//

#import <Foundation/Foundation.h>

@class StationsDirectory;
@class Station;

@interface BroadcastersListParserDelegate : NSObject <NSXMLParserDelegate>
{
	StationsDirectory		*receiverStationsDirectory;
	NSMutableDictionary		*broadcastersList; // key / value for having unique entries
	
	// For xml parsing
	NSMutableString			*currentPropertyNode;
	
	// xml data and url connection error
	NSData					*xmlData;
}

- (id)initWithStationsDirectory:(StationsDirectory *)theReceiverObject;
- (void)dealloc;
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string;
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict;
- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName;
- (void)parserDidEndDocument:(NSXMLParser *)parser;
- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError;

@end
