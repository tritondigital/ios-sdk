//
//  StationsDirectoryConstants.h
//  FLVStreamPlayerLib
//
//  Created by Thierry Bucco on 09-05-27.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//

// xml parser errors
#define kParserNoError							0
#define kParserUnableToParseXML					1
#define kParserUnableToConnect					2
#define kParserProvisioningReturnedBadRequest	3
#define	kParserProvisioningReturnedNotFound		4

// web services

#define broadcastersListsForBroadcasterURL @"http://playerservices.streamtheworld.com/api/stationdirectory"
#define stationsListsForBroadcasterURL @"http://playerservices.streamtheworld.com/api/stationdirectory?sections=geolocation,description&broadcasters=%@" // when app loading
#define mountsListForStationURL @"http://playerservices.streamtheworld.com/api/stationdirectory?sections=mounts,mediaformat&stations=%@"
