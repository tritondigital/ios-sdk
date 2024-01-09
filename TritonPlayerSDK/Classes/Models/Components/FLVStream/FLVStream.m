//
//  FLVStream.m
//  iPhoneV2
//
//  Created by Thierry Bucco on 09-03-23.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//
//
//
//
// 26/06/09
// streamStoppedNotification is no more sent from FLVStream
// this is the responsability of StreamController to send it when components are closed (audio / network)
// StreamController use KVO notification from FLVStream & AudioPlayerController


#import "FLVStreamPlayerLibConstants.h"
#import "FLVStream.h"
#import "FLVHeader.h"
#import "FLVDecoder.h"
#import "TritonPlayer.h"
//#import "TritonPlayer+SecureStreamPrivate.h"
#import "TritonPlayerConstants.h"
#import "TritonPlayerProtected.h"
#import "AudioPlayerController.h"
#import "Logs.h"
#import <AudioToolbox/AudioFileStream.h>
#import <UIKit/UIKit.h>


@interface FLVStream (Private)

- (void)closeConnection;

// delegate notification
- (void)connectingToStreamNotification:(NSNotification *)notification;
- (void)connectedToStreamNotification:(NSNotification *)notification;
- (void)connectionFailedNotification:(NSNotification *)notification;

@end



@implementation FLVStream

@synthesize flvHeader;
@synthesize flvDecoder;
@synthesize audioPlayerController;
@synthesize streamURL;
@synthesize secID;
@synthesize referrerURL;
@synthesize lowDelay;

@synthesize operationInProgress;
@synthesize isExecuting;

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// initWithDelegate
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (id)initWithDelegate:(id)inDelegate andAudioPlayerController:(AudioPlayerController *)inAudioPlayerController secID:(NSString *)inID secReferrerURL:(NSString *)inReferrerURL lowDelay:(UInt32)lowDelay
{	
	self = [super init];
	if (self)
	{
		delegate = inDelegate;
		self.audioPlayerController = inAudioPlayerController;    
        self.secID = inID;
        self.referrerURL = inReferrerURL;
        self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        self.lowDelay = ( lowDelay < 30 ) ? 30 : lowDelay;
	}
	return self;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// dealloc
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=


//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// setStreamURL
/// PUBLIC API - called from TDFLVPlayer on the TritonPlayer thread
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)setStreamURL:(NSString *)inStreamURL
{
	@synchronized(self)
	{
		if (self.isExecuting == YES)
		{
			FLOG(@"setStreamURL called while stream is still executing");
		}

		if (streamURL != inStreamURL)
		{
			if (self.referrerURL)
			{
				// set referrer URL
				if ([inStreamURL rangeOfString:@"?"].location == NSNotFound)
				{
					streamURL = [NSString stringWithFormat:@"%@?pageURL=%@", inStreamURL, referrerURL];
				}
				else
				{
					streamURL = [NSString stringWithFormat:@"%@&pageURL=%@", inStreamURL, referrerURL];
				}
			}
			else
			{
				streamURL = inStreamURL;
			}
		}
	}
}


//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// start
/// PUBLIC API - called from TDFLVPlayer on the TritonPlayer thread
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)start
{
    @synchronized(self)
	{
		if (self.operationInProgress == FALSE)
		{
			self.operationInProgress = TRUE;

            self.operationInProgress = FALSE;
			self.isExecuting = YES;

// Leave this up to the AudioPlayer & controller, when they actually start
//			[delegate isExecutingNotificationReceived:self.isExecuting];
			
			[self connectingToStreamNotification:nil];
    
            FLOG(@"Connecting to %@", streamURL);
            
			// setting user-agent
			NSMutableURLRequest *lURLRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString: streamURL] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:(double)self.lowDelay];
            [lURLRequest setValue:self.userAgent  forHTTPHeaderField:@"User-Agent"];

            if(self.dmpSegments != [NSNull null]){
                NSError *error;
                NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self.dmpSegments options:0 error:&error];
                self.dmpSegmentsJson = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                [lURLRequest addValue:self.dmpSegmentsJson forHTTPHeaderField:@"X-DMP-Segment-IDs"];
            }
			streamConnection = [[NSURLConnection alloc] initWithRequest:lURLRequest delegate:self];
			if (!streamConnection)
			{
				FLOG(@"Connection failed");
				
				[self closeConnection];
				[self connectionFailedNotification:nil];
			}
		}
		else
		{
			FLOG(@"operationInProgress");
		}
	}
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// stop
/// PUBLIC API - called from TDFLVPlayer on the TritonPlayer thread (or sometimes on an NSOperationQueue thread)
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)stop
{
	@synchronized(self)
	{
        if (operationInProgress == FALSE)
        {
            [self closeConnection];
        }
        else
        {
            FLOG(@"operationInProgress");
        }
	}
}


//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// closeConnection
/// PRIVATE API - must be called from synchronized code
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)closeConnection
{
	[streamConnection cancel];
	streamConnection = nil;

	if (secureAuthenticationMustReconnect == NO)
	{
		self.operationInProgress = FALSE;
		self.isExecuting = FALSE;

		if (self.audioPlayerController.isExecuting == YES) 
		{
			[self.audioPlayerController stop];
		}
		else
		{
			[delegate isExecutingNotificationReceived:self.isExecuting];
		}
	}
	else
	{
		[self start];
	}
}


/// PUBLIC API - called from TDFLVPlayer on the TritonPlayer thread
-(void)cancelBackgoundTasks
{
	@synchronized(self)
	{
		if (self.backgroundTaskIdentifier != UIBackgroundTaskInvalid)
		{
			[[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskIdentifier];
			self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
		}
	}
}


#pragma mark - Connection related functions


//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// didReceiveData
/// PUBLIC API - NSURLConnection delegate method, called on the TritonPlayer thread
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)inData
{
	
		if (self.backgroundTaskIdentifier != UIBackgroundTaskInvalid)
		{
			[[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskIdentifier];
			self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
		}

		if (flvDecoder && inData)
		{

			// we pass received data to the decoder
			[flvDecoder decodeStreamData:inData];
            inData= nil;
		}
	
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// willCacheResponse
/// PUBLIC API - NSURLConnection delegate method, called on the TritonPlayer(?) thread
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
	return nil;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// connectionDidFinishLoading
/// PUBLIC API - NSURLConnection delegate method, called on the TritonPlayer(?) thread
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	@synchronized(self)
	{
		self.backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
			[[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskIdentifier];
		}];
		
		PLAYER_LOG(@"FLVStream->connectionDidFinishLoading");
		
		[self closeConnection];
		[self connectionFailedNotification:nil];
	}
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// didFailWithError
/// PUBLIC API - NSURLConnection delegate method, called on the TritonPlayer(?) thread
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	@synchronized(self)
	{
		self.backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
			[[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskIdentifier];
		}];
		
		PLAYER_LOG(@"FLVStream->connection:didFailWithError: %@", error);
        
        if( [error code] != -1005 ){
            [self closeConnection];
        }
        
        [self connectionFailedNotification:nil];
		
	}
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// connection:willSendRequest:redirectResponse:
/// PUBLIC API - NSURLConnection delegate method, called on the TritonPlayer thread
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (NSURLRequest *)connection: (NSURLConnection *)inConnection
             willSendRequest: (NSURLRequest *)inRequest
            redirectResponse: (NSURLResponse *)inRedirectResponse;
{
   return inRequest;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// didReceiveResponse
/// PUBLIC API - NSURLConnection delegate method, called on the TritonPlayer thread
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	@synchronized(self)
	{
		NSString *contentType = [response MIMEType];
		NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
		NSNotification	*failedNotification = [NSNotification notificationWithName:kStreamFailedNotification object:[NSNumber numberWithInteger:[httpResponse statusCode]]];
		
		PLAYER_LOG(@"FLVStream->connection:didReceiveResponse, statusCode %ld", (long)[httpResponse statusCode]);
		
		switch ([httpResponse statusCode]) 
		{
			case kStatusCodeNotFound:
			case kStatusCodeGeoBlocked:
			case kStatusCodeServiceUnavailable:
				
				[self closeConnection];
				[self connectionFailedNotification:failedNotification];
				
				break;
				
			case kStatusCodeOK:
				
				[self.audioPlayerController start];
				
				[self connectedToStreamNotification:nil];
				
				if ([contentType rangeOfString:kMIME_TYPE_FLV].length == 0) // should not happen since provisioning send us a FLV mount
				{
					FLOG(@"Content-type is %@", contentType);

					// not flv we stop streamConnection
					[self closeConnection];
					[self connectionFailedNotification:nil];
				}
				
				break;				
		
			default:
				[self closeConnection];
				[self connectionFailedNotification:failedNotification];
				break;
		}
	}
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// Delegates functions for caller
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

#pragma mark - Delegates

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// connectingToStream
/// PRIVATE API
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)connectingToStreamNotification:(NSNotification *)notification
{	
    if ( [delegate respondsToSelector:@selector(connectingToStreamNotification:)] ) 
    {
        [delegate connectingToStreamNotification:notification];
    }
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// connectedToStreamNotification
/// PRIVATE API
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)connectedToStreamNotification:(NSNotification *)notification
{	
    if ( [delegate respondsToSelector:@selector(connectedToStreamNotification:)] ) 
    {
        [delegate connectedToStreamNotification:notification];
    }
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// connectionFailedNotification
/// PRIVATE API
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)connectionFailedNotification:(NSNotification *)notification
{	
    if ( [delegate respondsToSelector:@selector(connectionFailedNotification:)] ) 
    {
        [delegate connectionFailedNotification:notification];
    }
    
    PLAYER_LOG(@"FLVStream->connectionFailedNotification");
}

@end
