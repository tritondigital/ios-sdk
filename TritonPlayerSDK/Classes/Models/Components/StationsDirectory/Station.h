//
//  Station.h
//  FLVStreamPlayerLib
//
//  Created by Thierry Bucco on 09-05-27.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

@interface Station : NSObject
{	
	NSMutableArray  *mounts;
	NSString        *name;
	NSString        *display_name;
	NSString        *genre;
	NSString        *description;
	NSString        *city;
	NSString        *ad;
	NSDictionary	*adDict;
    NSArray	        *widgetsDict;
    NSString        *defaultCoverArtURL;
	NSString        *rss;
	NSString        *facebook;
	NSString        *coordinates;
	NSString        *website;
	NSMutableDictionary *customDataDict;
	
	
	NSString        *playerWebAdminId;
	NSString        *playerWebAdminSection;
	
	NSString        *playerTheme;
    NSDictionary    *theme;
	BOOL			nowPlaying;
	NSString        *logoName;
	NSString        *smallLogoName;
	id				smallLogo; // no UImage instead, because I don't want to link against UIKit
	CLLocationDistance	distance;
	NSString        *iTMSClickTroughPartnerUrl;
	NSString        *last10songsBuggyTextToExclude;
	id				playingSong;
	BOOL			gettingPlayingSong;
	BOOL			isTalkRadio;
	
	BOOL			mobileMarketingEnabled;
	NSString		*mobileMarketingParameter;
	BOOL			mobileMarketingTargeted;
	NSInteger		mobileMarketingPositionInURL;
}

@property (nonatomic, retain) NSMutableArray	*mounts;
@property (nonatomic, retain) NSString          *genre;
@property (nonatomic, retain) NSString          *name; // callsign
@property (nonatomic, retain) NSString          *display_name;
@property (nonatomic, retain) NSString          *description;
@property (nonatomic, retain) NSString          *city;
@property (nonatomic, retain) NSString          *ad;
@property (nonatomic, retain) NSDictionary		*adDict;
@property (nonatomic, retain) NSArray			*widgetsDict;
@property (nonatomic, retain) NSString			*defaultCoverArtURL;
@property (nonatomic, retain) NSMutableDictionary *customDataDict;
@property (nonatomic, retain) NSString          *rss;
@property (nonatomic, retain) NSString          *twitter;
@property (nonatomic, retain) NSString          *facebook;
@property (nonatomic, retain) NSString          *website;
@property (nonatomic, retain) NSString          *playerTheme;
@property (nonatomic, retain) NSDictionary      *theme; // StdApp v4 has the theme in the Station directly instead of a second file.
@property (nonatomic, retain) NSString          *playerWebAdminId;
@property (nonatomic, retain) NSString          *playerWebAdminSection;
@property (nonatomic, retain) NSString          *coordinates; // "lattitude, longitude"
@property BOOL									nowPlaying;
@property CLLocationDistance					distance;
@property (nonatomic, retain) NSString          *logoName;
@property (nonatomic, retain) NSString          *smallLogoName;
@property (nonatomic, retain) id				smallLogo;
@property (nonatomic, retain) NSString          *iTMSClickTroughPartnerUrl;
@property (nonatomic, retain) NSString          *last10songsBuggyTextToExclude;
@property (nonatomic, retain) id				playingSong; // SongTrack
@property BOOL									gettingPlayingSong;
@property BOOL									isTalkRadio;

@property BOOL									mobileMarketingEnabled;
@property (nonatomic, retain) NSString			*mobileMarketingParameter;
@property BOOL									mobileMarketingTargeted;
@property (nonatomic, assign) NSInteger			mobileMarketingPositionInURL;


- (void)dealloc;
- (NSComparisonResult)compareCity:(Station *)station;
- (NSComparisonResult)compareStationName:(Station *)station;
- (NSComparisonResult)compareGenre:(Station *)station;
- (NSComparisonResult)compareStationDistance:(Station *)station;

@end
