//
//  StationsListParser.m
//  FLVStreamPlayerLib
//
//  Created by Thierry Bucco on 09-05-27.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//

#import "StationsDirectoryConstants.h"
#import "BroadcastersListParser.h"
#import "BroadcastersListParserDelegate.h"


@implementation BroadcastersListParser

@synthesize parserError;




//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// init
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (id)init
{
	return [super init];
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// dealloc
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)dealloc
{	
	[super dealloc];
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// getStationsListXMLDataForBroadcaster
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)getBroadcastersListXMLData
{
	NSString *theURL = broadcastersListsForBroadcasterURL;
	
	// creating request asking for gzipped content
	NSMutableURLRequest *xmlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:theURL] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:10.0];
	[xmlRequest setValue:@"utf-8" forHTTPHeaderField:@"Accept-Charset"];  
	
	NSHTTPURLResponse	*getXMLDataURLResponse; 
	NSError				*getXMLDataError = nil;
	
	xmlData = [NSURLConnection sendSynchronousRequest:xmlRequest returningResponse:&getXMLDataURLResponse error:&getXMLDataError];
	
	// test for status code
	if (getXMLDataError != nil)
	{
		// unable to connect
		parserError = kParserUnableToConnect;
	}
	else
	{		
		NSInteger statusCode = [getXMLDataURLResponse statusCode];
		switch(statusCode)
		{
			case 400: // bad request
				parserError = kParserProvisioningReturnedBadRequest;
				break;
				
			case 404: // not found
				parserError = kParserProvisioningReturnedNotFound;
				break;
				
			case 200:
				parserError = kParserNoError;
				break;	
		}
	}
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// getStationsListForStationDirectory
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (BOOL)getBroadcastersListForStationDirectory:(StationsDirectory *)outStationsDirectory
{
	BOOL success = FALSE;
	
	stationsDirectoryReceiver = outStationsDirectory;
	
	[self getBroadcastersListXMLData];
	
	NSXMLParser *stationsListXMLParser = [[NSXMLParser alloc] initWithData:xmlData];
	BroadcastersListParserDelegate *parserDelegate = [[BroadcastersListParserDelegate alloc] initWithStationsDirectory:stationsDirectoryReceiver];
	
	[stationsListXMLParser setDelegate:parserDelegate];
	[stationsListXMLParser setShouldProcessNamespaces:NO];
	[stationsListXMLParser setShouldReportNamespacePrefixes:NO];
	[stationsListXMLParser setShouldResolveExternalEntities:NO];
	
	success = [stationsListXMLParser parse];
	
	[stationsListXMLParser release];
	stationsListXMLParser = nil;
	
	[parserDelegate release];
	parserDelegate = nil;
	
	return success;
}


@end
