//
//  TritonPlayerConstants.h
//  FLVStreamPlayerLib64
//
//  Created by Carlos Pereira on 2014-04-14.
//
//

#ifndef FLVStreamPlayerLib64_StreamControllerConstants_h
#define FLVStreamPlayerLib64_StreamControllerConstants_h

#define kLocationUpdateInterval 900.0f

#define kNotificationUserInfo                  @"NotificationUserInfo"
#define kChangeTargetingLocationNotification   @"changeTargetingLocationNotification"

#define kDefaultAppName                        @"CustomPlayer1" 

typedef NS_ENUM(NSInteger, TDPlayerAction) {
    kTDPlayerActionJumpToNextState,
    kTDPlayerActionPlay,
    kTDPlayerActionStop,
    kTDPlayerActionPause,
    kTDPlayerActionError,
		kTDPlayerActionReconnect
};

#endif
