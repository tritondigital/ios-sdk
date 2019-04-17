//
//  StreamsProvisioningController.h
//  iPhone V2
//
//  Created by Thierry Bucco on 08-11-04.
//  Copyright 2008 StreamTheWorld. All rights reserved.
//
//
// This data controller is instantiated in MainViewController and is the interface to access mounts/server data and stations guide
// This controller instantiate a Provisioning object for each callsign, stored in a NSMutableArray.
// MainViewController ask for a provisioning object at an index (PickerView selected index) and all infos can be accessed : mount name, servers list... 
//

#import <UIKit/UIKit.h>
#import "StationsGuide.h"

@class Provisioning;
@class StationsGuide;

@interface StreamsProvisioningController : NSObject
{
	// contains a list of stations
	StationsGuide	*stationsGuide;
	id				delegate;
	BOOL			fetchingData;
}

@property (nonatomic, retain) StationsGuide *stationsGuide;
@property BOOL fetchingData;

- (void)dealloc;
- (id)initWithStationsGuide:(StationsGuide *)theStationsGuide;
- (void)getAllProvisioning;
- (int)getNumberOfStreams;
- (Provisioning *)getProvisioningAtIndex:(int)theIndex;
- (Station *)getStationAtIndex:(int)theIndex;
- (StationsGuide *)getStations;
- (void)setDelegate:(id)del;
- (id)delegate;
- (void)orderByCity;
- (void)orderByLocation:(CLLocation *)currentLocation;
- (void)orderByStationName;
- (int)getRandomStationIndex;

@end
