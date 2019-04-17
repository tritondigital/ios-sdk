//
//  ProvisioningConstants.h
//  FLVStreamPlayerLib
//
//  Created by Thierry Bucco on 09-05-08.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//
#define kPlayserServices_DomainName_Prod                    @"playerservices.streamtheworld.com"
#define kProdProvisioningURL								(@"https://" kPlayserServices_DomainName_Prod @"/api/livestream?callsign=%@&version=1.9")
#define kProdProvisioningURLWithReferrerURL                 (@"https://" kPlayserServices_DomainName_Prod @"/api/livestream?callsign=%@&pageURL=%@&version=1.9")
#define kPreprodProvisioningURL								@"https://playerservices.preprod01.streamtheworld.net/api/livestream?callsign=%@&version=1.9"
#define kPreprodProvisioningURLReferrerURL                  @"https://playerservices.preprod01.streamtheworld.net/api/livestream?callsign=%@&pageURL=%@&version=1.9"
#define kProvisioningMaxRetryCount							1
#define kProvisioningConnectionTimeOut						10
// Provisioning Parser
#define kProvisioningParserNoError							0
#define kProvisioningParserUnableToParseXML					1
#define kProvisioningParserUnableToConnect					2
#define kProvisioningParserProvisioningReturnedBadRequest	3
#define	kProvisioningParserProvisioningReturnedNotFound		404
#define	kProvisioningParserForbidden						403
#define	kProvisioningParserGeoBlocked						453

#define kProvisioningStatusCodeOk                           200
#define kProvisioningStatusCodeNotImplemented               501
#define kProvisioningStatusCodeBadRequest                   400
#define kProvisioningStatusCodeNotFound                     404
#define kProvisioningStatusCodeGeoblocked                   453


#define kMountFormatFLV                                     @"FLV"
#define kMountFormatHLS                                     @"HLS"
