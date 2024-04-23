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
#import "LiveStreamProvisioningParser.h"
#import "LiveStreamProvisioningParserDelegate.h"
#import "ProvisioningConstants.h"
#import "TritonSDKUtils.h"
#import "Logs.h"


@implementation LiveStreamProvisioningParser

@synthesize provisioningError;

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


//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// getProvisioningXMLDataForCallsign
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)getProvisioningXMLDataForCallsign:(NSString *)inCallSign referrerURL:(NSString *)inReferrerURL  withUserAgent:(NSString *)userAgent   withPlayerServicesRegion:(NSString *)psRegion completionHandler:(void(^)(NSData *))completionHandler{
    if(!inCallSign)
    {
//        return nil;
				completionHandler(nil);
    }
    
    NSData *xmlData = nil;
		NSMutableString *theURL = nil;
    BOOL usePreprod = ([inCallSign rangeOfString:@".preprod"].length > 0);
    NSString *callsign = nil;
    
    if (usePreprod == YES)
    {
        callsign = [inCallSign stringByDeletingPathExtension];
    }
    else
    {
        callsign = inCallSign;
    }
    
    if (([inCallSign rangeOfString:@"SECURESTREAMING"].location != NSNotFound) || (usePreprod == YES) ) // testing secure stream
    {
        // secure stream, we need to pass pageURL too.
        // should always have referrerURL set
        
        if (inReferrerURL) theURL = [NSMutableString stringWithFormat:kPreprodProvisioningURLReferrerURL, callsign, inReferrerURL]; // secure stream, we need to pass pageURL too.
        else theURL = [NSMutableString stringWithFormat:kPreprodProvisioningURL, callsign];
    }
    else
    {
        if (inReferrerURL) theURL = [NSMutableString stringWithFormat:kProdProvisioningURLWithReferrerURL, callsign, inReferrerURL]; // secure stream, we need to pass pageURL too.
        else theURL = [NSMutableString stringWithFormat:kProdProvisioningURL, callsign];
        
        if(psRegion!=nil && [psRegion length] >0)
        {
            NSString* targetDomainName = [NSString stringWithFormat:@"%@-%@",[psRegion lowercaseString],kPlayserServices_DomainName_Prod];
            theURL =[[theURL stringByReplacingOccurrencesOfString:kPlayserServices_DomainName_Prod withString:targetDomainName  options: 0 range: NSMakeRange(0, 10+[kPlayserServices_DomainName_Prod length])
                                                                         ] mutableCopy];
        }
    }
    
    FLOG(@"getProvisioningXMLDataForCallsign : %@", theURL);
    
	NSMutableURLRequest *provRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:theURL]
																														 cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
																												 timeoutInterval:kProvisioningConnectionTimeOut];
		
		[provRequest setValue:@"utf-8" forHTTPHeaderField:@"Accept-Charset"];
		if(userAgent != nil)
		{
			[provRequest setValue:userAgent  forHTTPHeaderField:@"User-Agent"];
		}
		

	FLOG(@"Getting provisioning : %@", theURL);
		
		NSHTTPURLResponse	*getXMLDataURLResponse;
		NSError			*getXMLDataError = nil;
		
		xmlData = [NSURLConnection sendSynchronousRequest:provRequest returningResponse:&getXMLDataURLResponse error:&getXMLDataError];
		completionHandler(xmlData);

}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// getProvisioning
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
- (void)getProvisioningFor:(Provisioning *)theReceiverObject
                            withCallSign:(NSString *)inCallSign
                             referrerURL:(NSString *)inReferrerURL
                         withUserAgent:(NSString *)userAgent
                         withPlayerServicesRegion:(NSString*)psRegion
         completionHandler:(void(^)(BOOL))completionHandler {

    [self getProvisioningFor: theReceiverObject withCallSign:inCallSign referrerURL:inReferrerURL withUserAgent:userAgent withPlayerServicesRegion:psRegion withCloudStreaming:NO completionHandler:completionHandler];
}
- (void)getProvisioningFor:(Provisioning *)theReceiverObject
							withCallSign:(NSString *)inCallSign
							 referrerURL:(NSString *)inReferrerURL
						 withUserAgent:(NSString *)userAgent
                         withPlayerServicesRegion:(NSString*)psRegion
                        withCloudStreaming:(BOOL)cloudStreaming
				 completionHandler:(void(^)(BOOL))completionHandler {
		
   
    // Request the download of the XML provisioning file
    [self getProvisioningXMLDataForCallsign:inCallSign referrerURL:inReferrerURL withUserAgent:userAgent withPlayerServicesRegion: psRegion completionHandler:^(NSData *xmlData){
				BOOL success = FALSE;
				if (!xmlData) {
						provisioningError = kProvisioningParserUnableToConnect;
						
				} else {
						
						// Parse the provisioning XML file
						NSXMLParser *provisioningParser = [[NSXMLParser alloc] initWithData:xmlData];
						LiveStreamProvisioningParserDelegate *parserDelegate = [[LiveStreamProvisioningParserDelegate alloc] initWithProvisioning:theReceiverObject];
						
						[provisioningParser setDelegate:parserDelegate];
						[provisioningParser setShouldProcessNamespaces:NO];
						[provisioningParser setShouldReportNamespacePrefixes:NO];
						[provisioningParser setShouldResolveExternalEntities:NO];
						
						success = [provisioningParser parse];
						
						if (success) {
								provisioningError = kProvisioningParserNoError;
								
						} else if (provisioningParser.parserError.code == NSXMLParserDelegateAbortedParseError) {
								// The delegate aborts when it finds an error status code in XML even though the provisioning is ok, so consider this also a success.
								provisioningError = kProvisioningParserNoError;
								success = YES;
								
						} else {
								// Error while parsing
								provisioningError = kProvisioningParserUnableToParseXML;
						}
						
						theReceiverObject.errorCode = provisioningError;
						
						provisioningParser = nil;
						parserDelegate = nil;
				}
				
				completionHandler(success);

		}];
		
}




@end
