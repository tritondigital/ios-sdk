//
//  FLVStream.h
//  iPhoneV2
//
//  Created by Thierry Bucco on 09-03-23.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioFileStream.h>
#import <UIKit/UIKit.h>

@class FLVHeader;
@class FLVDecoder;
@class AudioPlayerController;
@class TritonPlayer;

@interface FLVStream : NSObject
{
	NSURLConnection			*streamConnection; // has a pointer on it, since FLVStream must stop or start AudioController
	NSString				*streamURL;
	FLVHeader				*flvHeader;
	FLVDecoder				*flvDecoder;
	AudioPlayerController	*audioPlayerController;
	id                      delegate;
	
	BOOL					operationInProgress;
    BOOL                    secureAuthenticationMustReconnect;
	BOOL					isExecuting;
    
    // content protection
    NSString                *secID;
    NSString                *referrerURL;
    NSString                *secCode;
    NSString                *secSession;
    NSString                *secChallenge;
}

@property (nonatomic, strong)  NSString                 *secID;
@property (nonatomic, strong)  NSString                 *referrerURL;
@property (nonatomic)          UInt32                   lowDelay;

@property (nonatomic, strong) FLVHeader					*flvHeader;
@property (nonatomic, strong) FLVDecoder				*flvDecoder;
@property (nonatomic, strong) AudioPlayerController		*audioPlayerController;
@property (nonatomic, strong) NSString					*streamURL;
@property (nonatomic, strong) NSString					*userAgent;
@property (nonatomic, strong) NSDictionary              *dmpSegments;
@property (nonatomic, strong) NSString                  *dmpSegmentsJson;

@property (nonatomic, assign) UIBackgroundTaskIdentifier  backgroundTaskIdentifier;

@property BOOL operationInProgress;
@property BOOL isExecuting;

- (id)initWithDelegate:(id)inDelegate andAudioPlayerController:(AudioPlayerController *)inAudioPlayerController secID:(NSString *)inID secReferrerURL:(NSString *)inReferrerURL lowDelay:(UInt32)lowDelay;
- (void)setStreamURL:(NSString *)inStreamURL;
- (void)start;
- (void)stop;

// URLConnection delegate
- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)inData;
- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse;
- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;

// Used for other objects to notify this class that there's no need to keep background tasks anymore
- (void)cancelBackgoundTasks;

@end
