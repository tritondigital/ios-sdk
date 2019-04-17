//
//  Reachability.m
//  FLVStreamPlayerLib
//
//  Created by Thierry Bucco on 09-06-18.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//

#import <sys/socket.h>
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>

#import <CoreFoundation/CoreFoundation.h>

#import "TDReachability.h"

#define kShouldPrintReachabilityFlags 0

static void PrintReachabilityFlags(SCNetworkReachabilityFlags    flags, const char* comment)
{
#if kShouldPrintReachabilityFlags
    
    FLOG(@"Reachability Flag Status: %c%c %c%c%c%c%c%c%c %s\n",
            (flags & kSCNetworkReachabilityFlagsIsWWAN)                  ? 'W' : '-',
            (flags & kSCNetworkReachabilityFlagsReachable)            ? 'R' : '-',
            
            (flags & kSCNetworkReachabilityFlagsTransientConnection)  ? 't' : '-',
            (flags & kSCNetworkReachabilityFlagsConnectionRequired)   ? 'c' : '-',
            (flags & kSCNetworkReachabilityFlagsInterventionRequired) ? 'i' : '-',
            (flags & kSCNetworkReachabilityFlagsIsLocalAddress)       ? 'l' : '-',
            (flags & kSCNetworkReachabilityFlagsIsDirect)             ? 'd' : '-',
            comment
            );
#endif
}


@implementation TDReachability
static void ReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void* info)
{
    #pragma unused (target, flags)
    NSCAssert(info != NULL, @"info was NULL in ReachabilityCallback");
    NSCAssert([(__bridge NSObject*) info isKindOfClass: [TDReachability class]], @"info was wrong class in ReachabilityCallback");

    //We're on the main RunLoop, so an NSAutoreleasePool is not necessary, but is added defensively
    // in case someon uses the Reachablity object in a different thread.
    @autoreleasepool {
    
        TDReachability* noteObject = (__bridge TDReachability*) info;
        // Post a notification to notify the client that the network reachability changed.
        [[NSNotificationCenter defaultCenter] postNotificationName: kReachabilityChangedNotification object: noteObject];
    
    }
}

- (BOOL) startNotifer
{
    BOOL retVal = NO;
    SCNetworkReachabilityContext    context = {0, (__bridge void *)(self), NULL, NULL, NULL};
    if(SCNetworkReachabilitySetCallback(reachabilityRef, ReachabilityCallback, &context))
    {
        if(SCNetworkReachabilityScheduleWithRunLoop(reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode))
        {
            retVal = YES;
        }
    }
    return retVal;
}

- (void) stopNotifer
{
    if(reachabilityRef!= NULL)
    {
        SCNetworkReachabilityUnscheduleFromRunLoop(reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    }
}

- (void) dealloc
{
    [self stopNotifer];
    if(reachabilityRef!= NULL)
    {
        CFRelease(reachabilityRef);
    }
}

+ (TDReachability*) reachabilityWithHostName: (NSString*) hostName;
{
    TDReachability* retVal = NULL;
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(NULL, [hostName UTF8String]);
    if(reachability!= NULL)
    {
        retVal= [[self alloc] init];
        if(retVal!= NULL)
        {
            retVal->reachabilityRef = reachability;
            retVal->localWiFiRef = NO;
        }
    }
    return retVal;
}

+ (TDReachability*) reachabilityWithAddress: (const struct sockaddr_in*) hostAddress;
{
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr*)hostAddress);
    TDReachability* retVal = NULL;
    if(reachability!= NULL)
    {
        retVal= [[self alloc] init];
        if(retVal!= NULL)
        {
            retVal->reachabilityRef = reachability;
            retVal->localWiFiRef = NO;
        }
    }
    return retVal;
}

+ (TDReachability*) reachabilityForInternetConnection;
{
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    return [self reachabilityWithAddress: &zeroAddress];
}

+ (TDReachability*) reachabilityForLocalWiFi;
{
    [super init];
    struct sockaddr_in localWifiAddress;
    bzero(&localWifiAddress, sizeof(localWifiAddress));
    localWifiAddress.sin_len = sizeof(localWifiAddress);
    localWifiAddress.sin_family = AF_INET;
    localWifiAddress.sin_addr.s_addr = htonl(IN_LINKLOCALNETNUM);
    TDReachability* retVal = [self reachabilityWithAddress: &localWifiAddress];
    if(retVal!= NULL)
    {
        retVal->localWiFiRef = YES;
    }
    return retVal;
}

#pragma mark Network Flag Handling

- (NetworkStatus) localWiFiStatusForFlags: (SCNetworkReachabilityFlags) flags
{
    PrintReachabilityFlags(flags, "localWiFiStatusForFlags");

    BOOL retVal = NotReachable;
    if((flags & kSCNetworkReachabilityFlagsReachable) && (flags & kSCNetworkReachabilityFlagsIsDirect))
    {
        retVal = ReachableViaWiFi;    
    }
    return retVal;
}

- (NetworkStatus) networkStatusForFlags: (SCNetworkReachabilityFlags) flags
{
    PrintReachabilityFlags(flags, "networkStatusForFlags");
    if ((flags & kSCNetworkReachabilityFlagsReachable) == 0)
    {
        // if target host is not reachable
        return NotReachable;
    }

    BOOL retVal = NotReachable;
    
    if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0)
    {
        // if target host is reachable and no connection is required
        //  then we'll assume (for now) that your on Wi-Fi
        retVal = ReachableViaWiFi;
    }
          
    if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN)
    {
        // ... but WWAN connections are OK if the calling application
        //     is using the CFNetwork (CFSocketStream?) APIs.
        retVal = ReachableViaWWAN;
    }
    return retVal;
}

- (BOOL) connectionRequired;
{
    NSAssert(reachabilityRef != NULL, @"connectionRequired called with NULL reachabilityRef");
    SCNetworkReachabilityFlags flags;
    if (SCNetworkReachabilityGetFlags(reachabilityRef, &flags))
    {
        return (flags & kSCNetworkReachabilityFlagsConnectionRequired);
    }
    return NO;
}

- (NetworkStatus) currentReachabilityStatus
{
    NSAssert(reachabilityRef != NULL, @"currentNetworkStatus called with NULL reachabilityRef");
    NetworkStatus retVal = NotReachable;
    SCNetworkReachabilityFlags flags;
    if (SCNetworkReachabilityGetFlags(reachabilityRef, &flags))
    {
        if(localWiFiRef)
        {
            retVal = [self localWiFiStatusForFlags: flags];
        }
        else
        {
            retVal = [self networkStatusForFlags: flags];
        }
    }
    return retVal;
}
@end
