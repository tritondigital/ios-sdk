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

@interface StationsListParserDelegate : NSObject <NSXMLParserDelegate>
{
	StationsDirectory	*receiverStationsDirectory;
	NSMutableArray		*stationsList;
	
	// For xml parsing
	Station				*currentStationNode;
	NSMutableString		*currentPropertyNode;
	NSMutableString		*currentServerAddress;
	
	// xml data and url connection error
	NSData				*xmlData;
}

- (id)initWithStationsDirectory:(StationsDirectory *)theReceiverObject;
- (void)dealloc;
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string;
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict;
- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName;
- (void)parserDidEndDocument:(NSXMLParser *)parser;
- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError;

@end
