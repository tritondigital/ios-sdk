//
//  Mount.h
//  FLVStreamPlayerLib
//
//  Created by Thierry Bucco on 09-05-27.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//

#import "StationsDirectoryConstants.h"
#import <CoreLocation/CoreLocation.h>

@interface Mount : NSObject
{	
	NSString	*name;
	NSString	*container;
	NSNumber	*bitrate;
	NSString	*codec;
	NSString	*samplerate;
	BOOL		stereo;
}

@property (nonatomic, retain) NSNumber		*bitrate;
@property (nonatomic, retain) NSString		*name;
@property (nonatomic, retain) NSString		*container;
@property (nonatomic, retain) NSString		*codec;
@property (nonatomic, retain) NSString		*samplerate;
@property (assign) BOOL						stereo;

- (void)dealloc;

@end
