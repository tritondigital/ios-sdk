//
//  StreamsProvisioningController.m
//  iPhone V2
//
//  Created by Thierry Bucco on 08-11-04.
//  Copyright 2008 StreamTheWorld. All rights reserved.
//

#import "StreamsProvisioningController.h"
#import "Provisioning.h"
#import "Station.h"
#import "CLLocation+Transform.h"

@implementation StreamsProvisioningController

@synthesize stationsGuide;
@synthesize fetchingData;

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// dealloc
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)dealloc
{
	[self.stationsGuide release];
	[super dealloc];
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// initWithStationsGuide
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (id)initWithStationsGuide:(StationsGuide *)theStationsGuide
{
	self.stationsGuide = theStationsGuide;
	[self orderByStationName];
	return self;
}


//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// getAllProvisioning
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)getAllProvisioning
{
	Station *aStation;
	BOOL provOK = false;
	NSMutableArray *stationsToRemove = [[NSMutableArray alloc] init];
	
	fetchingData = TRUE;
	
	NSEnumerator *stationsEnumerator = [self.stationsGuide.stationsList objectEnumerator];
	
	// in stations dictionary
	while ((aStation = (Station *)[stationsEnumerator nextObject]) != nil)
	{
		Provisioning *prov = [[Provisioning alloc] initWithCallsign:aStation.callsign];
		
		provOK = [prov getProvisioning];
		if (provOK)
		{
			aStation.provisioning = prov; // attach this provisioning to this station
			
			// send the progress information to the delegate
			if ( [delegate respondsToSelector:@selector(newStationLoaded)] ) 
			{
				[delegate performSelector:@selector(newStationLoaded)];
			}
		}
		else
		{
			// we need to remove this station from the station guide, we don't want it appears on stations list
			// can remove it now, since we use a NSEnumerator
			[stationsToRemove addObject:aStation];
			[prov release];
		}
	}
	
	// send the progress information to the delegate
	if ( [delegate respondsToSelector:@selector(stationDetailsLoading:)] ) 
	{
		[delegate performSelector:@selector(stationDetailsLoading:) withObject:[NSNumber numberWithFloat:1.0F]];
	}
	
	// we remove station if needed
	NSEnumerator *stationsToRemoveEnumerator = [stationsToRemove objectEnumerator];
	Station *aStationToRemove;
	
	// in stations dictionary
	
	while ((aStationToRemove = (Station *)[stationsToRemoveEnumerator nextObject]) != nil)
	{
		[self.stationsGuide removeStation:aStationToRemove];
	}
	
	[stationsToRemove release];
	
	if ( [delegate respondsToSelector:@selector(provisioningLoaded:)] ) 
	{
		[delegate performSelector:@selector(provisioningLoaded:) withObject:[NSNumber numberWithInt:[self.stationsGuide count]]];
	}	
	
	fetchingData = FALSE;
	
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// getRandomStationIndex
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (int)getRandomStationIndex
{
	int nb = [self.stationsGuide count];
	int randomIndex = random() % nb;
	return randomIndex;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// getNumberOfStreams
//
// Accessor methods for streams list
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (int)getNumberOfStreams 
{
	int nb = [self.stationsGuide count];
	return nb;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// objectInListAtIndex
// return a provisioning objet for selected index
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (Provisioning *)getProvisioningAtIndex:(int)theIndex 
{
	Station *aStation;
	aStation = [self.stationsGuide stationAtIndex:theIndex];
	
	if (aStation.provisioning == nil) return nil;
	
	// if index is out of bounds, it's because the table view want to have stream info on the last row which can be "Add a new Stream"
	if ( ([self.stationsGuide count] == 0) || (theIndex > [self.stationsGuide count]-1) ) return nil;
	
	
	return aStation.provisioning;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// getStationAtIndex
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (Station *)getStationAtIndex:(int)theIndex 
{
	if (self.stationsGuide == nil) return nil;
	
	if ( ([self.stationsGuide count] == 0) || (theIndex > [self.stationsGuide count]-1) ) return nil;
	else return [self.stationsGuide stationAtIndex:theIndex];
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// getStationAtIndex
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (StationsGuide *)getStations
{
	return self.stationsGuide;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// Delegates functions for caller
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

#pragma mark - Delegates

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// setDelegate
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)setDelegate:(id)del
{
	[del retain];
    delegate = del;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// delegate
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (id)delegate
{
    return delegate;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// orderByCity
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)orderByCity
{
	[self.stationsGuide orderByCity];
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// orderByLocation
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)orderByLocation:(CLLocation *)currentLocation
{
	Station* aStation;
	NSEnumerator *stationsEnumerator = [self.stationsGuide.stationsList objectEnumerator];
	
	CLLocation *currentStationLocation = [[CLLocation alloc] init];
	
	while ((aStation = (Station*)[stationsEnumerator nextObject]) != nil)
	{
		[currentStationLocation setLocationFromString:aStation.coordinates];
		
		aStation.distance = [currentLocation getDistanceFrom:currentStationLocation];
	}
	
	[currentStationLocation release];
	
	[self.stationsGuide orderByLocation];
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// orderByStationName
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)orderByStationName
{
	[self.stationsGuide orderByStationName];
}


@end
