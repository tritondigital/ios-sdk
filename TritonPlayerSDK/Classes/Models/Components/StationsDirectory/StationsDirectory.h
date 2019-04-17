//
//  StationsDirectory.h
//  FLVStreamPlayerLib
//
//  Created by Thierry Bucco on 09-05-27.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Station;
@class StationsListParser;

@interface StationsDirectory : NSObject 
{
	NSString				*broadcaster;
	NSArray					*stationsList;
	NSArray					*broadcastersList;
}

@property (nonatomic,retain) NSString		*broadcaster;
@property (retain) NSArray					*stationsList;
@property (retain) NSArray					*broadcastersList;

- (id)init;
- (BOOL)getBroadcastersList;
- (BOOL)getStationsListForBroadcaster:(NSString *)inBroadcaster;
- (BOOL)getFLVMountsListForStation:(Station *)outStation;

@end
