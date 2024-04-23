//
//  LiveStreamProvisioningParser.h
//  iPhoneV2
//
//  Created by Thierry Bucco on 09-05-08.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/NSXMLParser.h>
#import "Provisioning.h"

@class Provisioning;

@interface LiveStreamProvisioningParser : NSObject<NSXMLParserDelegate>
{	
	int			provisioningError;
}

@property (readonly) int provisioningError;

- (id)init;

- (void)getProvisioningFor:(Provisioning *)theReceiverObject
							withCallSign:(NSString *)inCallSign
							 referrerURL:(NSString *)inReferrerURL
						 withUserAgent:(NSString *)userAgent
                         withPlayerServicesRegion:(NSString*)psRegion
                        withCloudStreaming:(BOOL)cloudStreaming
                 completionHandler:(void(^)(BOOL))completionHandler;

- (void)getProvisioningFor:(Provisioning *)theReceiverObject
							withCallSign:(NSString *)inCallSign
							 referrerURL:(NSString *)inReferrerURL
						 withUserAgent:(NSString *)userAgent
                         withPlayerServicesRegion:(NSString*)psRegion
				 completionHandler:(void(^)(BOOL))completionHandler;

- (void)getProvisioningXMLDataForCallsign:(NSString *)inCallSign
															referrerURL:(NSString *)inReferrerURL
														withUserAgent:(NSString *)userAgent
                                                        withPlayerServicesRegion:(NSString*)psRegion
												completionHandler:(void(^)(NSData *))completionHandler;

@end
