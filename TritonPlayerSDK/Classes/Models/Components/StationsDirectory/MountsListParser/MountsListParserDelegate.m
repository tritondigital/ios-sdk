//
//  MountsListParserDelegate.m
//  FLVStreamPlayerLib
//
//  Created by Thierry Bucco on 09-05-27.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//

#import "MountsListParserDelegate.h"
#import "Mount.h"
#import "Station.h"

@implementation MountsListParserDelegate

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// initWithStation
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (id)initWithStation:(Station *)theReceiverObject
{
    if (self = [super init])
    {
        receiverStation = theReceiverObject;
        mountsList = [[NSMutableArray alloc] init];
    }
	return self;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// dealloc
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)dealloc
{	
	// no release needed since propertyNode is an autorelease mutablestring
	[mountsList release];
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
	if (currentPropertyNode) {
        [currentPropertyNode appendString:string];
    }	
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
	
	if (currentMountNode) 
	{ 		
        if ([elementName isEqualToString:@"container"])
		{
            currentPropertyNode = [[NSMutableString alloc] init];
		}
		else if ([elementName isEqualToString:@"audio"] )
		{
			// get audio properties
			if ([attributeDict objectForKey:@"bitrate"])
			{
				currentMountNode.bitrate = [attributeDict objectForKey:@"bitrate"];
			}
			
			if ([attributeDict objectForKey:@"codec"])
			{
				currentMountNode.codec = [NSString stringWithString:[attributeDict objectForKey:@"codec"]];
			}
			
			if ([attributeDict objectForKey:@"samplerate"])
			{
				currentMountNode.samplerate = [attributeDict objectForKey:@"samplerate"];
			}
			
			if ([attributeDict objectForKey:@"stereo"])
			{
				currentMountNode.stereo = (bool)[attributeDict objectForKey:@"stereo"];
			}
        }
    }
	else
	{ 		
        if ([elementName isEqualToString:@"mount"]) 
		{
            currentMountNode = [[Mount alloc] init];
			currentMountNode.name = [NSString stringWithString:[attributeDict objectForKey:@"name"]];
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
	
	if (currentMountNode)
	{ 
		// Are we in a <server> ?
		if ([elementName isEqualToString:@"container"])
		{
			currentMountNode.container = currentPropertyNode;
			[currentPropertyNode release];
			currentPropertyNode = nil;	
        }
		else if ([elementName isEqualToString:@"mount"])
		{
			if ([currentMountNode.container isEqualToString:@"FLV"])
			{
				[mountsList addObject:currentMountNode];
				[currentMountNode release];
			}
				
			currentMountNode = nil; // Set nil
		}
	}
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// parserDidEndDocument
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)parserDidEndDocument:(NSXMLParser *)parser
{
	// we pass data to the receiver
	
	receiverStation.mounts = mountsList;
	[mountsList release];
	
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
