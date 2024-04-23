//
//  LiveStreamProvisioningParser.m
//  iPhoneV2
//
//  Created by Thierry Bucco on 09-05-08.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//
//
// MountPoints array contains all servers object
//

#import <Foundation/Foundation.h>
#import "LiveStreamProvisioningParserDelegate.h"
#import "ProvisioningConstants.h"
#import "Server.h"
#import "MetadataConfiguration.h"

#define kSettingsKeyForceDisableHLS @"ExtraForceDisableHLS"

@interface LiveStreamProvisioningParserDelegate ()

@property (nonatomic, strong) NSMutableArray *mountPoints;	// an array of available servers for this mount
@property (nonatomic, assign) UInt8	totalServers; // number of servers
@property (nonatomic, strong) Provisioning	*receiverProvisioning;

// For xml parsing
@property (nonatomic, strong) Server *currentServerNode;
@property (nonatomic, strong) NSMutableString *currentPropertyNode;
@property (nonatomic, strong) NSMutableString *currentServerAddress;
@property (nonatomic, strong) NSMutableString *currentServerProtocol;

// Mount details
@property (nonatomic, strong) NSMutableString *mountName;
@property (nonatomic, strong) NSMutableString *mountFormat;
@property (nonatomic, strong) NSMutableString *mountBitrate;

@property (nonatomic, strong) NSMutableString *alternateMount;
@property (nonatomic, strong) NSString *alternateMediaUrl;


// xml data and url connection error
@property (nonatomic, strong)NSData			*xmlData;

@property (nonatomic, strong) MetadataConfiguration *sidebandMetadata;

@property (nonatomic, assign) BOOL hlsEnabled;

@property (nonatomic, strong) NSString *hlsMountSuffix;
@property (nonatomic, strong) NSString *cloudStreamingMountSuffix;

@property (nonatomic, strong) NSString *currentTransport;

@end

@implementation LiveStreamProvisioningParserDelegate


//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// initWithProvisioning
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (id)initWithProvisioning:(Provisioning *)theReceiverObject
{
    if (self = [super init])
    {
        _receiverProvisioning = theReceiverObject;
        _mountPoints = [[NSMutableArray alloc] init]; // Create our mounts list
    }
	return self;
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
	if (self.currentPropertyNode) {
        [self.currentPropertyNode appendString:string];
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
	
	if (self.currentServerNode)
	{ 
		// Are we in a <server> ?		
        if ([elementName isEqualToString:@"ip"])
		{
            self.currentPropertyNode = [NSMutableString string];
            
		} else if ( [elementName isEqualToString:@"port"] ){
            self.currentServerProtocol = [attributeDict objectForKey:@"type"];
            self.currentPropertyNode = [NSMutableString string];
        }
    }
	else
    {
		// We are outside of everything, so we need a <server>
        if ([elementName isEqualToString:@"server"]) 
		{
            self.currentServerNode = [[Server alloc] init];
        }
        else if ([elementName isEqualToString:@"mount"] || [elementName isEqualToString:@"format"] || [elementName isEqualToString:@"bitrate"] || [elementName isEqualToString:@"status-code"] || [elementName isEqualToString:@"url"] )
		{
            self.currentPropertyNode = [NSMutableString string];
        }
        else if ([elementName isEqualToString:@"sse-sideband"])
        {
            // Sideband metadata configuration
            self.sidebandMetadata = [[MetadataConfiguration alloc] init];
            self.sidebandMetadata.enabled = [[attributeDict objectForKey:@"enabled"]isEqualToString:@"true"];
            self.sidebandMetadata.metadataSuffix = [attributeDict objectForKey:@"metadataSuffix"];
        }
        else if ([elementName isEqualToString:@"transport"])
        {
            NSString* suffix  =[attributeDict objectForKey:@"mountSuffix"];
            NSString* timeshift  =[attributeDict objectForKey:@"timeshift"];
            
            if(suffix != nil && timeshift != nil && [[timeshift lowercaseString] isEqualToString:@"true"]){
                self.cloudStreamingMountSuffix = suffix;
                self.currentPropertyNode = [NSMutableString string];
            }
            
            if(suffix != nil && timeshift == nil && ([[suffix lowercaseString] rangeOfString:@"/hls/"].location!=NSNotFound))
            {
              self.hlsMountSuffix = suffix;
              self.currentPropertyNode = [NSMutableString string];
            }
        }
        else if ([elementName isEqualToString:@"alternate-content"])
        {
            self.alternateMount = [NSMutableString string];
        }
        else if ([elementName isEqualToString:@"url"])
        {
            self.alternateMediaUrl = [NSMutableString string];
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
	
	if (self.currentServerNode)
	{ 
		// Are we in a <server> ?
		if ([elementName isEqualToString:@"ip"])
		{
			self.currentServerNode.ip = self.currentPropertyNode;
        }
		else if ([elementName isEqualToString:@"port"])
		{
			// add complete url
			NSString *currentURL;
            
			
			currentURL = [[NSString alloc] initWithFormat:@"%@://%@:%@", self.currentServerProtocol, self.currentServerNode.ip, self.currentPropertyNode];
		
			[self.currentServerNode addUrl:currentURL];
			
			// add port
			[self.currentServerNode addPort:self.currentPropertyNode];
        }
		else if ([elementName isEqualToString:@"server"])
		{
			if (self.currentServerNode) [self.mountPoints addObject:self.currentServerNode];
			
			self.currentServerNode = nil; // Set nil
		}
		else if ([elementName isEqualToString:@"servers"])
		{
			self.currentServerNode = nil; // Set nil
		}
	}
	else
	{ 
		if ([elementName isEqualToString:@"mount"])
		{
            if (self.alternateMount != nil) {
                [self.alternateMount appendString:self.currentPropertyNode];
            }
            else
            {
                self.mountName = self.currentPropertyNode;
            }
            
        }
        else if ([elementName isEqualToString:@"url"])
        {
                self.alternateMediaUrl = self.currentPropertyNode;
        }
		else if ([elementName isEqualToString:@"format"])
		{
			self.mountFormat = self.currentPropertyNode;
		}
		else if ([elementName isEqualToString:@"bitrate"])
		{
			self.mountBitrate = self.currentPropertyNode;
		}
        else if ([elementName isEqualToString:@"alternate-content"])
        {
            if(self.alternateMediaUrl == nil) {
            self.receiverProvisioning.alternateMount = self.alternateMount;
            self.alternateMount = nil;
            }
        }
        
        else if ([elementName isEqualToString:@"transport"]) {
            
            self.currentTransport = self.currentPropertyNode ;
            if(self.currentTransport != nil && [self.currentTransport isEqualToString:@"hls"])
            {
                // Check whether the app forced HLS to be off. This is temporary until HLS is stable enough on the servers
                BOOL forceDisableHLS = self.receiverProvisioning.forceDisableHLS;
                self.hlsEnabled = [self.currentPropertyNode isEqualToString:@"hls"] && !forceDisableHLS;
            }
        
        } else if ([elementName isEqualToString:@"status-code"]) {
            int statusCode = [self.currentPropertyNode intValue];
            self.receiverProvisioning.statusCode = statusCode;
            
            if (statusCode != kProvisioningStatusCodeOk && statusCode != kProvisioningStatusCodeGeoblocked) {
                [parser abortParsing];
            }
        } else if ([elementName isEqualToString:@"metadata"]) {
            self.sidebandMetadata.mountSuffix = self.hlsMountSuffix;
        }
	}
		
	// We reset the currentPropertyNode, for the next textnodes..
	
	self.currentPropertyNode = nil;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// parserDidEndDocument
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)parserDidEndDocument:(NSXMLParser *)parser
{
	// we pass data to the receiver provisioning
	
	self.receiverProvisioning.totalServers = (UInt8)[self.mountPoints count];
	self.receiverProvisioning.mountPoints = self.mountPoints; // assigned
	self.receiverProvisioning.mountName = self.mountName;
	self.receiverProvisioning.mountFormat = self.hlsEnabled ? @"HLS" : self.mountFormat;
	self.receiverProvisioning.mountBitrate = self.mountBitrate;
    self.receiverProvisioning.sidebandMetadataInfo = self.sidebandMetadata;
    self.receiverProvisioning.alternateMediaUrl = self.alternateMediaUrl;
    self.receiverProvisioning.cloudStreamingSuffix = self.cloudStreamingMountSuffix;
		
	self.xmlData = nil; // set it to nil to prevent being freed one more time by the pool
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// parseErrorOccurred
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
	// called when somethings wrong with the parser
	self.receiverProvisioning.errorCode = kProvisioningParserUnableToParseXML;

	self.xmlData = nil; // set it to nil to prevent being freed one more time by the pool
}

@end
