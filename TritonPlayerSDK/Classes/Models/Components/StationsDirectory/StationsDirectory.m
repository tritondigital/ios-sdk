//
//  StationsDirectory.m
//  FLVStreamPlayerLib
//
//  Created by Thierry Bucco on 09-05-27.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//

#import "StationsDirectoryConstants.h"
#import "StationsDirectory.h"
#import "StationsListParser.h"
#import "BroadcastersListParser.h"
#import "MountsListParser.h"
#include <unistd.h>

@implementation StationsDirectory

@synthesize broadcaster;
@synthesize stationsList;
@synthesize broadcastersList;

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// stationsDirectoryWithBroadcaster
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (id)init
{
	self = [super init];
	if (self)
	{
	}
	return self;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// dealloc
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)dealloc
{	
	[broadcaster release];
	[super dealloc];
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// getBroadcastersList
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (BOOL)getBroadcastersList
{
	BOOL resultsFetchedWithSuccess;

	BroadcastersListParser *broadcastersListParser = [BroadcastersListParser new];
	
	while ( ([broadcastersListParser getBroadcastersListForStationDirectory:self] == FALSE) && (broadcastersListParser.parserError == kParserUnableToConnect) )
	{
		sleep(1);
	}
	
	if (broadcastersListParser.parserError != kParserNoError)
	{
		resultsFetchedWithSuccess = FALSE;
	}
	else
	{
		resultsFetchedWithSuccess = TRUE;
	}
	
	[broadcastersListParser release];
	
	return resultsFetchedWithSuccess;	
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// getStationsList
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (BOOL)getStationsListForBroadcaster:(NSString *)inBroadcaster
{
	BOOL resultsFetchedWithSuccess;
	
	self.broadcaster = inBroadcaster;
	
	StationsListParser *stationsListParser = [StationsListParser new];
	
	while ( ([stationsListParser getStationsListForStationDirectory:self] == FALSE) && (stationsListParser.parserError == kParserUnableToConnect) )
	{
		sleep(1);
	}
	
	if (stationsListParser.parserError != kParserNoError)
	{
		resultsFetchedWithSuccess = FALSE;
	}
	else
	{
		resultsFetchedWithSuccess = TRUE;
	}
	
	[stationsListParser release];
	
	return resultsFetchedWithSuccess;	
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// getStationsList
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (BOOL)getFLVMountsListForStation:(Station *)outStation
{
	BOOL resultsFetchedWithSuccess;
	
	MountsListParser *mountsListParser = [MountsListParser new];
	
	while ( ([mountsListParser getFLVMountsListForStation:outStation] == FALSE) && (mountsListParser.parserError == kParserUnableToConnect) )
	{
		sleep(1);
	}
	
	if (mountsListParser.parserError != kParserNoError)
	{
		resultsFetchedWithSuccess = FALSE;
	}
	else
	{
		resultsFetchedWithSuccess = TRUE;
	}
	
	[mountsListParser release];
	
	return resultsFetchedWithSuccess;
}


@end
