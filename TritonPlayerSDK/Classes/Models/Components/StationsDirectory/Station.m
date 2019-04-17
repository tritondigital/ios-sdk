//
//  Station.m
//  FLVStreamPlayerLib
//
//  Created by Thierry Bucco on 09-05-27.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//

#import "Station.h"
#import "StationsDirectoryConstants.h"

@implementation Station

@synthesize mounts;
@synthesize name;
@synthesize display_name;
@synthesize genre;
@synthesize description;
@synthesize city;
@synthesize ad;
@synthesize adDict;
@synthesize widgetsDict;
@synthesize defaultCoverArtURL;
@synthesize customDataDict;
@synthesize rss;
@synthesize twitter;
@synthesize facebook;
@synthesize website;
@synthesize playerTheme;
@synthesize theme;
@synthesize playerWebAdminId;
@synthesize playerWebAdminSection;
@synthesize coordinates;
@synthesize distance;
@synthesize nowPlaying;
@synthesize logoName;
@synthesize smallLogoName;
@synthesize smallLogo;
@synthesize iTMSClickTroughPartnerUrl;
@synthesize last10songsBuggyTextToExclude;
@synthesize playingSong;
@synthesize gettingPlayingSong;
@synthesize isTalkRadio;

@synthesize mobileMarketingEnabled;
@synthesize mobileMarketingParameter;
@synthesize mobileMarketingTargeted;
@synthesize mobileMarketingPositionInURL;

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// dealloc
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)dealloc
{
	self.mounts = nil;
	self.name = nil;
	self.display_name = nil;
	self.genre = nil;
	self.description = nil;
	self.city = nil;
	self.ad = nil;
	self.adDict = nil;
    self.widgetsDict = nil;
    self.defaultCoverArtURL = nil;
	self.customDataDict = nil;
	self.rss = nil;
	self.twitter = nil;
	self.rss = nil;
	self.website = nil;
	self.coordinates = nil;
	self.smallLogo = nil;
	self.smallLogoName = nil;
	self.playerTheme = nil;
    self.theme = nil;
	self.playerWebAdminId = nil;
	self.playerWebAdminSection = nil;
	self.iTMSClickTroughPartnerUrl = nil;
	self.last10songsBuggyTextToExclude = nil;
	self.playingSong = nil;
	self.mobileMarketingParameter = nil;
	
	[super dealloc];
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// Sort
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (NSComparisonResult)compareStationName:(Station *)station // we compare the display name not callsign
{
    return [self.display_name compare:station.display_name options:NSCaseInsensitiveSearch];
}

- (NSComparisonResult)compareCity:(Station *)station
{
    return [self.city compare:station.city];
}

- (NSComparisonResult)compareGenre:(Station *)station
{
    return [self.genre compare:station.genre];
}

- (NSComparisonResult)compareStationDistance:(Station *)station
{
    if (self.distance > station.distance) return NSOrderedDescending;
	else if (self.distance < station.distance) return NSOrderedAscending;
	else if (self.distance == station.distance)
	{
		// same distance, we sort by station name
		return [self.name compare:station.display_name options:NSNumericSearch];
	}
	
    return NSOrderedAscending; 
}

@end
