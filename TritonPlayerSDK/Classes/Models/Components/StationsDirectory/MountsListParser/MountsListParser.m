//
//  MountsListParser.m
//  FLVStreamPlayerLib
//
//  Created by Thierry Bucco on 09-05-27.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//

#import "StationsDirectoryConstants.h"
#import "MountsListParser.h"
#import "MountsListParserDelegate.h"
#import "Station.h"

@implementation MountsListParser

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
// getMountsListXMLDataForStation
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)getMountsListXMLDataForStation:(Station *)inStation
{
	NSString *theURL = [NSString stringWithFormat:mountsListForStationURL, inStation.name];
	
	// creating request asking for gzipped content
	NSMutableURLRequest *xmlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[theURL stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:10.0];
	[xmlRequest setValue:@"utf-8" forHTTPHeaderField:@"Accept-Charset"];  
	
	NSHTTPURLResponse	*getXMLDataURLResponse; 
	NSError			*getXMLDataError = nil;
	
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
// getMountsListForStation
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (BOOL)getFLVMountsListForStation:(Station *)outStation
{
	BOOL success = FALSE;
    
	stationReceiver = outStation;
	
	[self getMountsListXMLDataForStation:outStation];
	
	NSXMLParser *mountsListXMLParser = [[NSXMLParser alloc] initWithData:xmlData];
	MountsListParserDelegate *parserDelegate = [[MountsListParserDelegate alloc] initWithStation:outStation];
	
	[mountsListXMLParser setDelegate:parserDelegate];
	[mountsListXMLParser setShouldProcessNamespaces:NO];
	[mountsListXMLParser setShouldReportNamespacePrefixes:NO];
	[mountsListXMLParser setShouldResolveExternalEntities:NO];
	
	success = [mountsListXMLParser parse];
	
	[mountsListXMLParser release];
	mountsListXMLParser = nil;
	
	[parserDelegate release];
	parserDelegate = nil;
	
	return success;
}


@end
