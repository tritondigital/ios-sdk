//
//  Provisioning.h
//  iPhone V2
//
//  Created by Thierry Bucco on 08-12-01.
//  Copyright 2008 StreamTheWorld. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LiveStreamProvisioningParser;
@class Server;
@class MetadataConfiguration;

@interface Provisioning : NSObject
{	
	NSMutableArray *mountPoints;	// an array of available servers for this mount
	NSString *callSign; // the mount sign we use to query provisioning : ex KROQFM
    NSString *userAgent; //User-Agent to send to the TD PlayerServices
    NSString *playerServicesRegion; //When there is a need to use a specific player services region.
	
	// Mount details
	NSMutableString *mountName;
	NSString *mountFormat;
	NSMutableString *mountBitrate;
	
	UInt8	usedServerIndex;
	UInt8	totalServers; // number of servers
	
	Server *currentServer; // current server used
	BOOL	allServerScanned; // indicate that we tried all servers without success
	
	BOOL	problemDuringParsing;
	BOOL	operationInProgress;
    
	NSString    *__weak referrerURL;
}

// Used as a way to disable HLS through the application
@property (nonatomic, assign) BOOL forceDisableHLS;

@property (nonatomic, strong) NSString *callSign;
@property (nonatomic, strong) NSString *userAgent;
@property (nonatomic, strong) NSString *playerServicesRegion;
@property (nonatomic, strong) NSMutableArray *mountPoints;
@property (nonatomic, strong) NSMutableString *mountName;
@property (nonatomic, strong) NSString *mountFormat;
@property (nonatomic, strong) NSMutableString *mountBitrate;
@property (nonatomic, strong) Server *currentServer;
@property (nonatomic, strong) MetadataConfiguration *sidebandMetadataInfo;

@property (nonatomic, strong) NSString *alternateMount;

@property (weak) NSString					*referrerURL;

@property UInt8	totalServers;
@property BOOL	allServerScanned;
@property (readonly) BOOL	operationInProgress;
@property int	statusCode;
@property int   errorCode;

- (instancetype)initWithCallsign:(NSString *)theCallSign;
- (instancetype)initWithCallsign:(NSString *)theCallSign referrerURL:(NSString *)inReferrerURL;
- (void)getProvisioning:(void(^)(BOOL))completionHandler;
- (BOOL)getNextAvailableServer;
- (void)rewindServerList;
- (BOOL)hasReachedEndOfServerList;

@end
