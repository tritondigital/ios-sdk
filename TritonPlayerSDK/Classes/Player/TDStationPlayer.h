//
//  TDStationPlayer.h
//  TritonPlayerSDK
//
//  Created by Carlos Pereira on 2015-03-12.
//  Copyright (c) 2015 Triton Digital. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TDMediaPlayback.h"

extern NSString *const SettingsStationPlayerUserAgentKey;
extern NSString *const SettingsStationPlayerMountKey;
extern NSString *const SettingsStationPlayerBroadcasterKey;
extern NSString *const SettingsStationPlayerForceDisableHLSkey;

@interface TDStationPlayer : NSObject<TDMediaPlayback>

-(NSString*) getCastStreamingUrl;
-(NSString*) getSideBandMetadataUrl;
@end
