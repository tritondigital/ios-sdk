//
//  Provisioning.m
//  iPhone V2
//
//  Created by Thierry Bucco on 08-12-01.
//  Copyright 2008 StreamTheWorld. All rights reserved.
//

#import "Provisioning.h"
#import "LiveStreamProvisioningParser.h"
#import "ProvisioningConstants.h"
#import "Server.h"
#import "Logs.h"
#include <unistd.h>

@interface Provisioning ()

@property (nonatomic, strong) LiveStreamProvisioningParser	*provisioningParser;

@end

@implementation Provisioning

@synthesize callSign;
@synthesize userAgent;
@synthesize mountPoints;
@synthesize mountName;
@synthesize mountFormat;
@synthesize mountBitrate;
@synthesize currentServer;
@synthesize totalServers;
@synthesize allServerScanned;
@synthesize operationInProgress;
@synthesize referrerURL;
@synthesize playerServicesRegion;

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// dealloc
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=


//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// initWithCallsign
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (instancetype)initWithCallsign:(NSString *)theCallSign
{
    if (self = [super init])
    {
        allServerScanned = false;
        usedServerIndex = 0;
        self.callSign = theCallSign;
    }
	return self;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// initWithCallsign:mobileMarketingEnabled:mobileMarketingParameter:
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (instancetype)initWithCallsign:(NSString *)theCallSign referrerURL:(NSString *)inReferrerURL
{
    self = [self initWithCallsign:theCallSign];
    
    if (self)
    {
        self.referrerURL = inReferrerURL;
    }
	return self;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// getProvisioning
// 
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)getProvisioning:(void(^)(BOOL))completionHandler {

		allServerScanned = FALSE;
		usedServerIndex = 0;
		operationInProgress = TRUE;

		// allocate provisioning parser
		self.provisioningParser = [[LiveStreamProvisioningParser alloc] init];

		// Try to obtain the provisioning. If there's a connection problem, try again until retry count expires
			[self.provisioningParser getProvisioningFor:self withCallSign:callSign referrerURL:self.referrerURL withUserAgent: self.userAgent withPlayerServicesRegion:self.playerServicesRegion completionHandler:^(BOOL success) {
					BOOL provFetchWithSuccess;
					
					if ( self.provisioningParser.provisioningError != kProvisioningParserNoError ){
							// we remove this callsign
							provFetchWithSuccess = FALSE;
					}
					else
					{
							// get next available server to use
							[self getNextAvailableServer];
	
							provFetchWithSuccess = TRUE;
					}
					
					operationInProgress = FALSE;
					completionHandler(provFetchWithSuccess);
					
			} ];

}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// getNextAvailalbleServer
//
// called to retrieve next available server to connect to
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=   f     -=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (BOOL)getNextAvailableServer
{
	// we retrieve next server to connect to in a round robin way	
	// if we are at the end of the array we go to the first element
    
	// put current server pointer on a server to use.
	
	if (mountPoints == nil) return NO;
	
	@try 
	{
		self.currentServer = [mountPoints objectAtIndex:usedServerIndex];
	}
	@catch (NSException * e) 
	{
		FLOG(@"Exception : %@ : %@", [e name], [e reason]);
		return NO;
	}
	
	// get next url of current server
	if ([currentServer getNextAvailableUrl] == FALSE) // no more url available
	{
		// find next server
		usedServerIndex++;
        
		if (usedServerIndex == totalServers) // no more server
		{
			allServerScanned = TRUE;
			usedServerIndex = 0;
			return FALSE;
		}
		
		self.currentServer = [mountPoints objectAtIndex:usedServerIndex];
		return [currentServer getNextAvailableUrl];
	}
	
	return TRUE;
}

- (BOOL)hasReachedEndOfServerList
{
    return allServerScanned;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// rewindServerList
//
// change the selected server for the first one
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)rewindServerList
{
    allServerScanned = NO;
	usedServerIndex = 0;
	self.currentServer = [mountPoints objectAtIndex:usedServerIndex];
}

@end
