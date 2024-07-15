//
//  AudioPlayer.h
//  Emmis - Hot97
//
//  Created by Thierry Bucco on 09-04-13.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//

#include <pthread.h>
#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioQueue.h>
#import <AudioToolbox/AudioFileStream.h>
#include <AudioToolbox/AudioToolbox.h>

// AudioQueue
#define kMaxNumAQBufs					4096			// number of audio queue buffers we allocate
#define kAQMaxPacketDescs				65535
#define kAQBufSize						32 * 768

#define kNonDelayBufs                   20

#define kLowDelaySecondsStart           2
#define kBufferTimeMultiplierMax        4


@class AudioPlayerController;

@interface AudioPlayer : NSObject
{
	AudioQueueRef					audioQueue;
	AudioQueueBufferRef				audioQueueBuffer[kMaxNumAQBufs];
	AudioStreamPacketDescription	packetDescs[kAQMaxPacketDescs];
	AudioStreamBasicDescription		audioFormat;
//	AudioQueueLevelMeterState		*audioLevels;
	
	unsigned int					fillBufferIndex;
    size_t							bytesFilled;
	size_t							packetsFilled;
	
	BOOL							inuse[kMaxNumAQBufs];
	
	float							gain;
	
	AudioFileStreamID				audioFileStream;
	AudioFileTypeID					fileTypeHint;
//	NSURLConnection					*streamConnection;
//	NSMutableURLRequest				*streamRequest;
	
	double							sampleRate;
	double							packetDuration;		// sample rate times frames per packet
	UInt32							numberOfChannels;	// Number of audio channels in the stream (1 = mono, 2 = stereo)
    UInt32                          bitrate;
    UInt32                          playTime;
    UInt32                          bufSize;
    UInt32                          numAQBufs;
    
    UInt32 bufferIn;
    UInt32 bufferFree;
       
	OSStatus						err;
	
	NSThread						*internalThread;
	
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
	
	// public details of playing stream
	Float64 streamSampleRate;
	UInt32 streamFormatID;
	
	bool							operationInProgress;
	bool							isTerminating;
	
	bool							isCancelled;
	BOOL							isExecuting; // KVO
    
    bool                            forceStop;
    SInt32                          lowDelay;
	
    UInt32                            rebufferState;
    bool                            rebufferEnded;
    
	AudioPlayerController			*isExecutingDelegate;
    
    NSString    *lastMessage;

    // AUDIO QUEUE TAP
    UInt32 outMaxFrames;
    AudioStreamBasicDescription outProcessingFormat;
    AudioQueueProcessingTapRef outAQTap;

@public
	
	pthread_mutex_t mutex;			// a mutex to protect the inuse flags
	pthread_cond_t cond;			// a condition varable for handling the inuse flags
}

@property BOOL isExecuting; //KeyValue Observer (KVO) from MainController
@property BOOL isFinished;
@property bool isCancelled;
@property (readonly) bool operationInProgress;
@property bool isBuffering;
@property bool failed;
@property bool finished; // thread execution
@property bool connected;
@property bool forceStop;
@property SInt32 lowDelay;

@property UInt32 rebufferState;
@property bool rebufferEnded;

@property unsigned int bufferingDataSize;
@property Float64 streamSampleRate;
@property UInt32 streamFormatID;
@property UInt32 bitrate;
@property UInt32 playTime;
@property UInt32 bufSize;
@property UInt32 bufferIn;
@property UInt32 bufferFree;
@property NSString *lastMessage;

@property (nonatomic,strong) NSString *serverURL;


// Init / alloc / dealloc
- (void)setIsExecutingDelegate:(id)theDelegate;
- (void)start;
- (void)cancel;
- (void)parseAndPlayData:(NSData*)data;

- (AudioQueueRef)getAudioQueue;

// Delegate API
- (void)setDelegate:(id)del;
- (id)delegate;
- (void)audioPlayerBuffering:(NSString*)percentage;


// Volume Manipulation
- (void)mute;
- (void)unmute;
- (void)setVolume:(float)volume;

@end
