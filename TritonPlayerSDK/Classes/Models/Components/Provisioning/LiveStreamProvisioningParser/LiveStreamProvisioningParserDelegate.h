//
//  LiveStreamProvisioningParser.h
//  iPhoneV2
//
//  Created by Thierry Bucco on 09-05-08.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Provisioning.h"

@class Server;
@class Provisioning;

@interface LiveStreamProvisioningParserDelegate : NSObject <NSXMLParserDelegate>

- (id)initWithProvisioning:(Provisioning *)theReceiverObject;
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string;
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict;
- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName;
- (void)parserDidEndDocument:(NSXMLParser *)parser;
- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError;

@end
