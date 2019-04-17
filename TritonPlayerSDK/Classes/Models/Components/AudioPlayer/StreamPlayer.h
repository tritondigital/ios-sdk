//
//  StreamPlayer.h
//  Radio Disney
//
//  Created by Thierry Bucco on 09-04-13.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//

#include <pthread.h>
#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioQueue.h>
#import <AudioToolbox/AudioFileStream.h>
#import "AudioQueue.h"
#import "Constants.h"
#import "PLSParser.h"


@interface StreamPlayer : AudioQueue
{
	AudioFileStreamID				audioFileStreamParser;
	AudioFileTypeID					fileTypeHint;
	NSURLConnection					*streamConnection;
	NSURLRequest					*streamRequest;
	
	bool isBuffering;
	bool started;					// flag to indicate that the queue has been started
	bool failed;					// flag to indicate an error occurred
	bool finished;					// flag to inidicate that termination is requested
	bool connected;					// flag to indicate that we are connected		

	bool discontinuous;				// flag to trigger bug-avoidance
	NSString						*contentType;
	NSString						*serverURL;
	id								delegate;
	
	unsigned int					bufferingDataSize;
	NSTimer							*audioLevelTimer;
	
	BOOL							operationInProgress;
	
	// public details of playing stream
	Float64 streamSampleRate;
	UInt32 streamFormatID;
	
@public
	pthread_mutex_t mutex;			// a mutex to protect the inuse flags
	pthread_cond_t cond;			// a condition varable for handling the inuse flags
	pthread_mutex_t copyDataToAQBufferMutex;			// a mutex to protect the AudioQueue buffer
	NSThread *controlThread;
}

@property bool isPlaying; //KeyValue Observer (KVO) from MainController
@property bool isBuffering;
@property bool failed;
@property bool finished;
@property bool connected;
@property unsigned int bufferingDataSize;
@property (nonatomic,retain) NSTimer *audioLevelTimer;
@property Float64 streamSampleRate;
@property UInt32 streamFormatID;
@property (nonatomic,retain) NSString *serverURL;

// Audio Queue callbacks

static void propertyListenerCallback(void *inClientData, AudioFileStreamID inAudioFileStream,AudioFileStreamPropertyID	inPropertyID, UInt32 * ioFlags);
static void packetsListenerCallback(void *inClientData, UInt32 inNumberBytes, UInt32 inNumberPackets, const void * inInputData, AudioStreamPacketDescription	*inPacketDescriptions);
static void audioQueueOutputListenerCallback(void *inClientData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer);
static void audioQueueIsRunningCallback(void *inUserData, AudioQueueRef inAQ, AudioQueuePropertyID inID);
// Init / alloc / dealloc

- (void)dealloc;
- (void)setupPlaybackAudioQueueObject;
- (Boolean)streamIsPlaying;
- (void)startInThread;
- (void)play;
- (void)stop;

// Connection related functions

- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data;
- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse;
- (void)connectionDidFinishLoading:(NSURLConnection *)inConnection;
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;

// Audio Queue

- (void)propertyChanged:(AudioFileStreamPropertyID)propertyID flags:(UInt32*)flags;
- (void)packetData:(const void*)data numberOfPackets:(UInt32)numPackets numberOfBytes:(UInt32)numBytes packetDescriptions:(AudioStreamPacketDescription*)packetDescriptions;
- (OSStatus)enqueueBuffer;
- (int)findQueueBuffer:(AudioQueueBufferRef)inBuffer;
- (void)outputCallbackWithBufferReference:(AudioQueueBufferRef)buffer;

// Delegates / Notifications

- (void)setDelegate:(id)del;
- (id)delegate;
- (void)streamBuffering:(float)percentage;
- (void)connectingToStream:(NSNotification *)notification;
- (void)streamStopped:(NSNotification *)notification;
- (void)errorOccuredOnStreamOperation:(NSNotification *)notification;


@end