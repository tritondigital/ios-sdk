//
//  StationsListParser.m
//  FLVStreamPlayerLib
//
//  Created by Thierry Bucco on 09-05-27.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//

#import "StationsDirectoryConstants.h"
#import "StationsListParser.h"
#import "StationsListParserDelegate.h"


@implementation StationsListParser

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

- (void)getStationsListXMLDataForBroadcaster:(NSString *)inBroadcasterName;
{
	NSString *theURL = [NSString stringWithFormat:stationsListsForBroadcasterURL, inBroadcasterName];
	
	// creating request asking for gzipped content
	NSMutableURLRequest *xmlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[theURL stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:10.0];
	[xmlRequest setValue:@"utf-8" forHTTPHeaderField:@"Accept-Charset"];  
	
	NSHTTPURLResponse	*getXMLDataURLResponse; 
	NSError			*getXMLDataError = nil;
	
	[[NSURLCache sharedURLCache] setMemoryCapacity:0];
	[[NSURLCache sharedURLCache] setDiskCapacity:0];
	
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

- (BOOL)getStationsListForStationDirectory:(StationsDirectory *)outStationsDirectory
{
	BOOL success = FALSE;
	
	stationsDirectoryReceiver = outStationsDirectory;
	
	[self getStationsListXMLDataForBroadcaster:outStationsDirectory.broadcaster];
	
	NSXMLParser *stationsListXMLParser = [[NSXMLParser alloc] initWithData:xmlData];
	StationsListParserDelegate *parserDelegate = [[StationsListParserDelegate alloc] initWithStationsDirectory:stationsDirectoryReceiver];
	
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
