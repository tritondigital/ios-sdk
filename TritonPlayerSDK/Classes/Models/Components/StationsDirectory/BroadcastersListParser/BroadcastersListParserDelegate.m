//
//  StationsListParserDelegate.m
//  FLVStreamPlayerLib
//
//  Created by Thierry Bucco on 09-05-27.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//

#import "StationsDirectory.h"
#import "BroadcastersListParserDelegate.h"

@implementation BroadcastersListParserDelegate

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// initWithStationsDirectory
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (id)initWithStationsDirectory:(StationsDirectory *)theReceiverObject
{
    if (self = [super init])
    {
        receiverStationsDirectory = theReceiverObject;
        broadcastersList = [[NSMutableDictionary alloc] init]; // Create our stations list
    }
	return self;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// dealloc
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)dealloc
{	
	// no release needed since propertyNode is an autorelease mutablestring
	
	[super dealloc];
}

#pragma mark - XML parser

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// foundCharacters
//
// Parser has found a node value.
// currentPropertyNode has been instantiated before in open tag
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// didStartElement
//
// An open tag has been found
// we check its name and allocate the corresponding NSString in order to store it when the tag will close
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if (qName) 
	{
        elementName = qName;
    }
	
	// We are outside of everything, so we need a <station>
	if ([elementName isEqualToString:@"station"]) 
	{
		if ([attributeDict objectForKey:@"broadcaster"])
		{
			currentPropertyNode = [[NSMutableString stringWithString:[attributeDict objectForKey:@"broadcaster"]] retain];
		}
	}
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// didEndElement
//
// An close tag has been found
// we store the xml property in the right variable
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{    
	if (qName)
	{
        elementName = qName;
    }
	
	if (currentPropertyNode)
	{ 
		if ([elementName isEqualToString:@"station"])
		{
			if ([broadcastersList objectForKey:currentPropertyNode] == nil)
			{
				[broadcastersList setObject:currentPropertyNode forKey:currentPropertyNode];
			}
				
			[currentPropertyNode release];
			currentPropertyNode = nil; // Set nil
		}
	}
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// parserDidEndDocument
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)parserDidEndDocument:(NSXMLParser *)parser
{
	// we pass data to the receiver provisioning
	receiverStationsDirectory.broadcastersList = [[broadcastersList allValues] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]; 
	
	[xmlData release];
	xmlData = nil; // set it to nil to prevent being freed one more time by the pool
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// parseErrorOccurred
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
	[xmlData release];
	xmlData = nil; // set it to nil to prevent being freed one more time by the pool
}

@end
