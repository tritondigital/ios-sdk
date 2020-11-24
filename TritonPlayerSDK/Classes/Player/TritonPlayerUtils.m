//
//  TritonPlayerUtils.m
//  TritonPlayerSDK
//
//  Created by Carlos Pereira on 2014-12-04.
//  Copyright (c) 2014 Triton Digital. All rights reserved.
//

#import "TritonPlayer.h"
#import "TritonPlayerUtils.h"
#import <AdSupport/AdSupport.h>
#import <AppTrackingTransparency/AppTrackingTransparency.h>

#define kPName @"TritonMobileSDK_IOS"

@implementation TritonPlayerUtils



+(NSString *)getListenerId {
    NSString *listenerId = nil;
    
    listenerId = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
        
    if (![listenerId  isEqual: @"00000000-0000-0000-0000-000000000000"]) {
        return [NSString stringWithFormat:@"idfa:%@",listenerId];
    } else {
        listenerId = [[NSUserDefaults standardUserDefaults] objectForKey:@"uuid"];
        if (![listenerId length])
        {
            listenerId = [[NSUUID UUID] UUIDString];
            [[NSUserDefaults standardUserDefaults] setObject:listenerId forKey:@"uuid"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        
        return [NSString stringWithFormat:@"app:%@",listenerId];
    }
}

+ (NSString *)targetingQueryParametersWithLocation:(CLLocation *) location andExtraParameters:(NSDictionary *) extraParameters withTtags:(NSArray*) tTags andToken:(NSString*) token {
    // get all params and create a string to be passed in GET
    // ?param1=value1&param2=value2...
    
    NSMutableString *queryParametersString = [NSMutableString stringWithCapacity:512];
    //Add Listener id
    [queryParametersString appendFormat:@"uuid=%@&", [TritonPlayerUtils getListenerId]];
    
    
    // Append tdsdk
    // Add tdsdk to query
    [queryParametersString appendString:[NSString stringWithFormat:@"tdsdk=iOS-%@&", TritonSDKVersion]];
    
    // Add pname
    [queryParametersString appendString: [NSString stringWithFormat:@"pname=%@&", kPName]];
    
    if (location) {
        [queryParametersString appendFormat:@"lat=%f&long=%f&", location.coordinate.latitude, location.coordinate.longitude];
    }
    
    //Add TTags
    if(tTags != nil && [tTags count] > 0)
    {
         [queryParametersString appendFormat:@"ttag=%@&", [tTags componentsJoinedByString:@","]];
    }
    
    //Add token
    if(token != nil && token.length > 0)
    {
       [queryParametersString appendFormat:@"tdtok=%@&", token];
    }
    
    // others parameters passed as Extra Parameters
    for (NSString *key in [extraParameters allKeys]) {
        [queryParametersString appendFormat:@"%@=%@&", key, [extraParameters objectForKey:key]];
    }
    
    // remove last &
    return [queryParametersString stringByReplacingCharactersInRange:NSMakeRange(queryParametersString.length-1, 1) withString:@""];
}

@end
