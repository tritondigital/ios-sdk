//
//  AudioPlayer.m
//
//  Created by Thierry Bucco on 09-04-13.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//

#import "AudioPlayer.h"
#import "AudioPlayerController.h"
#import "Logs.h"

#include <stdlib.h>

#if TARGET_OS_IPHONE			
#import <CFNetwork/CFNetwork.h>
#import "UIDevice+Hardware.h"

#define kCFCoreFoundationVersionNumber_MIN 550.32
#else
#define kCFCoreFoundationVersionNumber_MIN 550.00
#endif


/// "Protected" methods needed to support the C callbacks only
@interface AudioPlayer (ProtectedForCallbacks)

- (void)onAudioQueueIsRunningChanged;
- (void)propertyChanged:(AudioFileStreamPropertyID)propertyID flags:(UInt32*)flags;
- (void)packetData:(const void*)data numberOfPackets:(UInt32)numPackets numberOfBytes:(UInt32)numBytes packetDescriptions:(AudioStreamPacketDescription*)packetDescriptions;
- (void)outputCallbackWithBufferReference:(AudioQueueBufferRef)buffer;

@end

@interface AudioPlayer (Private)

- (void)audioPlayerPlaying:(NSNotification *)notification;
- (void)audioPlayerStopped:(NSNotification *)notification;
- (void)audioPlayerBufferTimeout:(NSNumber*)bufferTime;
- (void)audioPlayerDidPlayBuffer:(AudioBufferList *)buffer;

- (OSStatus)enqueueBuffer;
- (int)findQueueBuffer:(AudioQueueBufferRef)inBuffer;

@end


#pragma mark - Audio Queue callbacks


//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// AUDIO QUEUE CALLBACK FUNCTIONS
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

// Called by the AudioFileStream (on the TritonPlayer thread) when it finds a property value in the audio file stream.
static inline void propertyListenerCallback(void *inClientData, AudioFileStreamID inAudioFileStream, AudioFileStreamPropertyID inPropertyID, UInt32* ioFlags)
{
	AudioPlayer *player = (__bridge AudioPlayer*)inClientData;
	[player propertyChanged:inPropertyID flags:ioFlags];
}


// Called by the AudioFileStream (on the TritonPlayer thread) when it finds audio data in the audio file stream.
static inline void packetsListenerCallback(void *inClientData, UInt32 inNumberBytes, UInt32 inNumberPackets, const void * inInputData, AudioStreamPacketDescription	*inPacketDescriptions)
{
	AudioPlayer *player = (__bridge AudioPlayer*)inClientData;
	[player packetData:inInputData numberOfPackets:inNumberPackets numberOfBytes:inNumberBytes packetDescriptions:inPacketDescriptions];
}


// Called by the AudioQueue (on the coreaudio.AQClient thread) when a new audio queue buffer is available.
static inline void audioQueueOutputListenerCallback(void *inClientData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer)
{
	AudioPlayer *player = (__bridge AudioPlayer*)inClientData;
	
	[player outputCallbackWithBufferReference:inBuffer];
}


// Called by the AudioQueue (on the coreaudio.AQClient thread) when an audio queue property has changed
static void audioQueueIsRunningCallback(void *inUserData, AudioQueueRef inAQ, AudioQueuePropertyID inID)
{
	AudioPlayer *player = (__bridge AudioPlayer*)inUserData;
	if (player)
	{
		[player onAudioQueueIsRunningChanged];
	}
}

static void audioQueueTapCallback(
                                  void *inClientData,
                                  AudioQueueProcessingTapRef inAQTap,
                                  UInt32 inNumberFrames,
                                  AudioTimeStamp *ioTimeStamp,
                                  AudioQueueProcessingTapFlags *ioFlags,
                                  UInt32 *outNumberFrames,
                                  AudioBufferList *ioData
                                  ) 
{
    OSStatus status = AudioQueueProcessingTapGetSourceAudio(inAQTap, inNumberFrames, ioTimeStamp, ioFlags, outNumberFrames, ioData);
    if (status != noErr) {
        NSLog(@"Error getting source audio: %d", status);
        return;
    }
    AudioPlayer *player = (__bridge AudioPlayer*)inClientData;
    [player audioPlayerDidPlayBuffer: ioData];
}


static UInt32 bufferTimeMultiplier=1;

@implementation AudioPlayer

@synthesize isExecuting,isFinished,isCancelled;
@synthesize isBuffering;
@synthesize finished;
@synthesize failed;
@synthesize connected;
@synthesize bufferingDataSize;
@synthesize streamSampleRate;
@synthesize streamFormatID;
@synthesize serverURL;
@synthesize operationInProgress;
@synthesize bitrate;
@synthesize playTime;
@synthesize forceStop;
@synthesize rebufferState;
@synthesize rebufferEnded;
@synthesize lowDelay;
@synthesize bufSize;
@synthesize bufferIn;
@synthesize bufferFree;
@synthesize lastMessage;

#pragma mark - Init / alloc / dealloc


- (AudioQueueRef)getAudioQueue
{
	return audioQueue;
}


#pragma mark - Audio queue functions


//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// onAudioQueueIsRunningChanged
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)onAudioQueueIsRunningChanged
{
	/// \note Because this is a callback from the AudioQueue object, and the thing we might want to protect in this
	/// object is the AudioQueue itself, we can probably take the chance of running this bit of code unsynchronized.
//	@synchronized(self)
	{
		UInt32		isRunning;
		UInt32		propertySize = sizeof(UInt32);
		OSStatus	result = AudioQueueGetProperty(audioQueue, kAudioQueueProperty_IsRunning, &isRunning, &propertySize);
		
		if (result == noErr)
		{
			self.isBuffering = FALSE;
			self.isExecuting = (bool)isRunning;
			
			if (isRunning == TRUE)
			{
				[self performSelectorOnMainThread:@selector(audioPlayerPlaying:) withObject:nil waitUntilDone:NO];
			}
        }
	}
}


//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// start
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

-(void)start
{
	internalThread = [[NSThread alloc]
                      initWithTarget:self
                      selector:@selector(startInternal)
                      object:nil];
    internalThread.name = @"TritonPlayer-AudioPlayer";
    [internalThread start];
}


//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// startInternal
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)startInternal
{
	@autoreleasepool
	{
		@synchronized(self)
		{
			// Open AudioFileStream
            AudioFileStreamOpen((__bridge void *)(self), propertyListenerCallback, packetsListenerCallback, fileTypeHint, &audioFileStream);

			// initialize a mutex and condition so that we can block on buffers in use.
			pthread_mutex_init(&mutex, NULL);
			pthread_cond_init(&cond, NULL);

            bufferIn = 0;
            bufferFree = 0;
            rebufferState = 0;

			isBuffering = TRUE;
			isCancelled = FALSE;

            lastMessage = @"";

			self.isExecuting = TRUE;
		}

		// Run outside the lock - the delegate will never change after creation so we should be OK
		[isExecutingDelegate isExecutingNotificationReceived:TRUE];

		[[NSRunLoop currentRunLoop] addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
		while (!isCancelled && self.isExecuting)
		{
			CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.30, FALSE); 
		}

cleanup:

		@synchronized(self)
		{
			self.isExecuting = NO;

			// Close the audio file stream
			if (audioFileStream)
			{
				err = AudioFileStreamClose(audioFileStream);
				audioFileStream = nil;
			}

			// Dispose of the Audio Queue
			if (audioQueue)
			{
				err = AudioQueueDispose(audioQueue, true);
				audioQueue = nil;
			}
        
			pthread_mutex_destroy(&mutex);
			pthread_cond_destroy(&cond);
        			
			self.isExecuting = NO;
			
			internalThread = nil;
		}

		[isExecutingDelegate isExecutingNotificationReceived:NO];
	}
}


- (void)cleanUp
{
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// cancel
// PUBLIC API - called by the AudioPlayerController on an NSOperationQueue thread (sometimes on the TritonPlayer thread?)
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)cancel
{
	@synchronized(self)
    {
		if (audioQueue)
		{
			AudioQueuePause(audioQueue);
			AudioQueueStop(audioQueue, TRUE);
		}

		isCancelled = TRUE;
        if ( !forceStop )
		{
			// reset the multiplier for buffer if it's a user initiated stop
			bufferTimeMultiplier = 1;
		}
    }
}


#pragma mark - Connection related functions


//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// connection
/// Called by AudioPlayerController on the TritonPlayer thread
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)parseAndPlayData:(NSData*)data
{
	if (isCancelled == TRUE)
	{
		return;
	}
    
    if (!data)
    {
        return;
    }
	
	// If we are buffering, we calculate buffered percentage
	if ((self.isBuffering == TRUE) && (self.isExecuting == FALSE))
	{
		float bufferPercentageLoaded = 0;
		unsigned int totalDataBytesToLoadWhenBuffering = bufSize;
		
		self.bufferingDataSize += (UInt32)[data length];
		if (self.bufferingDataSize > totalDataBytesToLoadWhenBuffering)
		{
			self.bufferingDataSize = totalDataBytesToLoadWhenBuffering;
			bufferPercentageLoaded = 100;
			self.isBuffering = FALSE;
		}
		else
		{
			bufferPercentageLoaded = (self.bufferingDataSize * 100) / totalDataBytesToLoadWhenBuffering;
		}

        [self audioPlayerBuffering:[NSString stringWithFormat:@"%f", bufferPercentageLoaded]];
	}

	/// \note Because we can only get here from the NSURLConnection data callback starting in FLVStream, which runs
	/// synchronized, we can expect the AudioFileStream will not change on us, so it should be safe to run the code
	/// below without a synchronize. This is important because one call here can lead to a large number of callbacks
	/// in packetData:numberOfPackets:numberOfBytes:packetDescriptions: and we would be holding the lock all that time.
	/// Since the callback can stall when it's waiting for audio buffers to become available, we want the lock to get
	/// released every time we exit the callback.
	@synchronized(self)
	{
		if (discontinuous)
		{
			err = AudioFileStreamParseBytes(audioFileStream, (UInt32)[data length], [data bytes], kAudioFileStreamParseFlag_Discontinuity);
		}
		else
		{
			err = AudioFileStreamParseBytes(audioFileStream, (UInt32)[data length], [data bytes], 0);
		}
	}
}

//
// createQueue
//
// Method to create the AudioQueue from the parameters gathered by the AudioFileStream.
//
// Creation is deferred to the handling of the first audio packet (although it could be handled any time after
// kAudioFileStreamProperty_ReadyToProducePackets is true).
//
/// PRIVATE API - must be called from @synchronized code
//
- (void)createQueue
{
	sampleRate = audioFormat.mSampleRate;
	packetDuration = audioFormat.mFramesPerPacket / sampleRate;
	numberOfChannels = audioFormat.mChannelsPerFrame;
	
	// Creates a new playback audio queue object.
	err = AudioQueueNewOutput(&audioFormat, audioQueueOutputListenerCallback, (__bridge void *)(self), NULL, NULL, 0, &audioQueue);
	if (err) 
	{
		failed = true;
		return;
	}

	// listen to the "isRunning" property
	err = AudioQueueAddPropertyListener(audioQueue, kAudioQueueProperty_IsRunning, audioQueueIsRunningCallback, (__bridge void *)(self));
	if (err)
	{
		failed = true;
		return;
	}
    
    bufSize = kAQBufSize; // original buffer size found
    numAQBufs = kNonDelayBufs;
    
    if ( bitrate && lowDelay != 0 )
    {
        if ( lowDelay == -1 )
        {
            bufSize = (( bitrate / 8 ));
    
            playTime = (kLowDelaySecondsStart * bufferTimeMultiplier);
            if ( playTime == 2 )
                playTime = 3;
    
       
            numAQBufs = ((playTime * kLowDelaySecondsStart) + kLowDelaySecondsStart);
        }
        if ( lowDelay > 0 )
        {
            if ( lowDelay == 1)
                lowDelay = 2;
            
            bufSize = (( bitrate / 8 ));
            
            playTime = lowDelay ;
            
            numAQBufs = playTime * 3;
        }
    }

    // allocate audio queue buffers and enqueue buffers
    for (unsigned int i = 0; i < numAQBufs; i++)
    {
        err = AudioQueueAllocateBuffer(audioQueue, bufSize, &audioQueueBuffer[i]);
    }

	// get the cookie size
	UInt32 cookieSize = 0;
	Boolean writable;
	err = AudioFileStreamGetPropertyInfo(audioFileStream, kAudioFileStreamProperty_MagicCookieData, &cookieSize, &writable);
	if (!err) 
	{
		// get the cookie data
		void* cookieData = calloc(1, cookieSize);
		err = AudioFileStreamGetProperty(audioFileStream, kAudioFileStreamProperty_MagicCookieData, &cookieSize, cookieData);
		if (err)
		{
			
		}
		else
		{
			// set the cookie on the queue.
			err = AudioQueueSetProperty(audioQueue, kAudioQueueProperty_MagicCookie, cookieData, cookieSize);
			if (err)
			{
				
			}	
		}
		
		free(cookieData); 
	}

    err = AudioQueueProcessingTapNew(
                                     audioQueue,
                                     audioQueueTapCallback,
                                     (__bridge void *)(self),
                                     kAudioQueueProcessingTap_PostEffects,
                                     &outMaxFrames,
                                     &outProcessingFormat,
                                     &outAQTap
                                     );

    if (err)
    {
        failed = true;
        NSLog(@"got error for tap: %d", err);
        raise(1);
        return;
    }
}


//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// propertyChanged
/// PROTECTED API - only called from a static callback function
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)propertyChanged:(AudioFileStreamPropertyID)propertyID flags:(UInt32*)flags
{
	@synchronized(self)
	{
		if (propertyID == kAudioFileStreamProperty_ReadyToProducePackets)
		{	
			discontinuous = true;
		}
		else if (propertyID == kAudioFileStreamProperty_DataFormat)
		{
			if (audioFormat.mSampleRate == 0)
			{
				UInt32 asbdSize = sizeof(audioFormat);
				
				// get the stream format.
				err = AudioFileStreamGetProperty(audioFileStream, kAudioFileStreamProperty_DataFormat, &asbdSize, &audioFormat);
			}
		}
		else if (propertyID == kAudioFileStreamProperty_FormatList)
		{
			Boolean outWriteable;
			UInt32 formatListSize;
			err = AudioFileStreamGetPropertyInfo(audioFileStream, kAudioFileStreamProperty_FormatList, &formatListSize, &outWriteable);
			if (err)
			{
				return;
			}
			
			AudioFormatListItem *formatList = malloc(formatListSize);
			err = AudioFileStreamGetProperty(audioFileStream, kAudioFileStreamProperty_FormatList, &formatListSize, formatList);
			if (err)
			{
				free(formatList);
				return;
			}
			
			for (int i = 0; i * sizeof(AudioFormatListItem) < formatListSize; i += sizeof(AudioFormatListItem))
			{
				audioFormat = formatList[i].mASBD;
			}
			free(formatList);
        }
	}
}


//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// packetData
/// PROTECTED API - only called from a static callback function
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)packetData:(const void*)data numberOfPackets:(UInt32)numPackets numberOfBytes:(UInt32)numBytes packetDescriptions:(AudioStreamPacketDescription*)packetDescriptions
{

	discontinuous = false;
	
	if (isCancelled == TRUE) 
	{
		return;
	}
	
	if (discontinuous)
	{
		discontinuous = false;
	}

	/// the synchronize is probably redundant
	@synchronized(self)
	{
		if (!audioQueue)
		{
			[self createQueue];
		}
		
        // the following code assumes we're streaming VBR data.
        if (packetDescriptions)
        {
            for (int i = 0; i < numPackets; ++i)
            {		
                SInt64 packetOffset = packetDescriptions[i].mStartOffset;
                UInt32 packetSize = packetDescriptions[i].mDataByteSize;
                
                // if the space remaining in the buffer is not enough for this packet, then enqueue the buffer.
                size_t bufSpaceRemaining = bufSize - bytesFilled;
                if (bufSpaceRemaining < packetSize)
                {
	//NSLog(@"%ld bytes remaining in buffer %ld, not enough for next packet of size %ld – enqueueing buffer", bufSpaceRemaining, (long)fillBufferIndex, (long)packetSize);
                    [self enqueueBuffer];
                }

                // copy data to the audio queue buffer
                AudioQueueBufferRef fillBuf = audioQueueBuffer[fillBufferIndex];

                if (isCancelled == TRUE) 
                {
                    return;
                }
                
                if (data)
                {
                    memcpy((char*)fillBuf->mAudioData + bytesFilled, (const char*)data + packetOffset, packetSize);
                    
                    // fill out packet description
                    packetDescs[packetsFilled] = packetDescriptions[i];
                    packetDescs[packetsFilled].mStartOffset = bytesFilled;
                    
                    // keep track of bytes filled and packets filled
                    bytesFilled += packetSize;
                    packetsFilled += 1;
                    
                    // if that was the last free packet description, then enqueue the buffer.
                    size_t packetsDescsRemaining = kAQMaxPacketDescs - packetsFilled;
                    if (packetsDescsRemaining == 0) [self enqueueBuffer];
                }
            }
        }
	}
}


//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// enqueueBuffer
/// PRIVATE API - must be called from @synchronized code
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (OSStatus)enqueueBuffer
{
	inuse[fillBufferIndex] = true; // set in use flag
    
	// enqueue buffer
	AudioQueueBufferRef fillBuf = audioQueueBuffer[fillBufferIndex];
	fillBuf->mAudioDataByteSize = (UInt32)bytesFilled;
	
	if (packetsFilled)
	{
		err = AudioQueueEnqueueBuffer(audioQueue, fillBuf, (UInt32)packetsFilled, packetDescs);
	}
	else
	{
		err = AudioQueueEnqueueBuffer(audioQueue, fillBuf, 0, NULL);
	}

	if (!err && !started && (bufferIn >= playTime || lowDelay == 0 ))
	{
		err = AudioQueuePrime(audioQueue, 1, NULL);
		if (!err)
		{
			err = AudioQueueStart(audioQueue, NULL); // start the queue if it has not been started already
			if (!err)
			{
				started = true;
			}
		}
	}
	
	if (err)
	{
		failed = true;
	
		inuse[fillBufferIndex] = false; // set in use flag
        bytesFilled = 0;		// reset bytes filled
	    packetsFilled = 0;		// reset packets filled
        
        AudioQueueFlush(audioQueue);
	    AudioQueueReset(audioQueue);
	}
	else
	{
		// go to next buffer
		if (++fillBufferIndex >= numAQBufs) fillBufferIndex = 0;
		bytesFilled = 0;		// reset bytes filled
		packetsFilled = 0;		// reset packets filled
	
		// wait until next buffer is not in use
		/// need to clarify exactly what we're trying to do and if there's a better/safer way to do it
		pthread_mutex_lock(&mutex);
		while (inuse[fillBufferIndex] && !isCancelled)
		{
			pthread_cond_wait(&cond, &mutex);

			if (isCancelled == TRUE) 
			{
				break;
			}
		}
		pthread_mutex_unlock(&mutex);
        
        bufferIn ++;
	}
    
    if (started == false)
    {
        [self audioPlayerBuffering:[NSString stringWithFormat:@"Buffering : %u", (unsigned int)(bufferIn-1)]];
    }
    
    if (started && rebufferState == 2)
    {
        UInt32 dist = playTime + 1;
        UInt32 delta = bufferIn - bufferFree;
        
        if (delta >= (dist+1))
        {
            err = AudioQueueStart(audioQueue, NULL); // play the queue
            rebufferState = 0;
            rebufferEnded = true;
        }
    }
	
   	return err;
}


//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// findQueueBuffer
/// PRIVATE API - must be called from @synchronized code
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (int)findQueueBuffer:(AudioQueueBufferRef)inBuffer
{
	for (unsigned int i = 0; i < numAQBufs; i++)
	{
		if (inBuffer == audioQueueBuffer[i]) return i;
	}

	return -1;
}


//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// This is the AudioQueue output callback.
/// PROTECTED API - only called from a static callback function
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)outputCallbackWithBufferReference:(AudioQueueBufferRef)buffer
{
	UInt32		isRunning = 0;
	UInt32		propertySize = sizeof(UInt32);
	OSStatus	result;

	/// \note This method gets called by the AQClient OS thread when a buffer is available. We expect the TritonPlayer
	/// thread to be paused inside the enqueueBuffer method, where we are inside a @synchronized block AND a lock on
	/// the explicit mutex, which is released through the condition. In theory, this call will then come in, grab the
	/// lock, trigger the condition and exit, thus waking up the TritonPlayer thread. In that context, we CANNOT make
	/// this code @synchronized, but what happens if we get called while the TritonPlayer thread is NOT waiting for us?
	/// We might end up accessing the audioQueue in parallel with other code that operates using a @synchronize only...
	/// I suspect this code is not entirely safe, but I'm not clear enough on the AudioQueue callback to be sure.
	pthread_mutex_lock(&mutex);

	unsigned int bufIndex = [self findQueueBuffer:buffer];
	inuse[bufIndex] = false;
	
	result = AudioQueueGetProperty(audioQueue, kAudioQueueProperty_IsRunning, &isRunning, &propertySize);
	if (!result && isRunning && !forceStop && !isCancelled && lowDelay != 0)
	{
		bufferFree++;

		[self audioPlayerBuffering:[NSString stringWithFormat:@"Buffer remaining: %ds", (unsigned int)((bufferIn-1)-bufferFree)]];
   
		if (bufferFree == bufferIn - 1)
		{
			if (!rebufferEnded || lowDelay > 0)
			{
				AudioQueuePause(audioQueue); // pause the queue
				rebufferState = 2;
				[self audioPlayerBuffering:[NSString stringWithFormat:@"Rebuffering to %ds", (unsigned int)playTime]];
			}
			if (rebufferEnded && lowDelay == -1)
			{
				forceStop = true;
				bufferTimeMultiplier *= 2;
				if (bufferTimeMultiplier > kBufferTimeMultiplierMax)
					bufferTimeMultiplier = 1;
			
				[self audioPlayerBuffering:[NSString stringWithFormat:@"Reconnecting: %ds", (unsigned int)(kLowDelaySecondsStart * bufferTimeMultiplier)]];

				[self performSelectorOnMainThread:@selector(audioPlayerBufferTimeout:) withObject:[NSNumber numberWithInt: kLowDelaySecondsStart * bufferTimeMultiplier] waitUntilDone:NO];
			}
		}
	}

	pthread_cond_signal(&cond);
	pthread_mutex_unlock(&mutex);
}


//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// Delegates functions for caller
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

#pragma mark - Delegates

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// setDelegate
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)setDelegate:(id)del
{
    delegate = del;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// delegate
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (id)delegate
{
    return delegate;
}


- (void)setIsExecutingDelegate:(id)theDelegate
{
	isExecutingDelegate = theDelegate;
}


#pragma mark - Notifications

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// streamBuffering
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)audioPlayerBuffering:(NSString*)percentage
{

}


//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// audioPlayerPlaying
/// PRIVATE API - must be called from @synchronized code
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)audioPlayerPlaying:(NSNotification *)notification
{
	if ( [delegate respondsToSelector:@selector(audioPlayerPlaying:)] )
	{
		[delegate audioPlayerPlaying:notification];
	}
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// audioPlayerStopped
/// PRIVATE API - must be called from @synchronized code
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)audioPlayerStopped:(NSNotification *)notification
{
	isBuffering = FALSE;
	self.bufferingDataSize = 0;
	
    if ( [delegate respondsToSelector:@selector(audioPlayerStopped:)] ) 
    {
        [delegate audioPlayerStopped:notification];
    }
}


//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// audioPlayerBufferTimeout
/// PRIVATE API - must be called from @synchronized code
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)audioPlayerBufferTimeout:(NSNumber*)bufferTime;
{
    isBuffering = FALSE;
    self.bufferingDataSize = 0;
    
    if ( [delegate respondsToSelector:@selector(audioPlayerBufferTimeout:)] )
    {
        [delegate audioPlayerBufferTimeout:bufferTime];
    }
}

- (void)audioPlayerDidPlayBuffer:(AudioBufferList *)buffer {
    if ([delegate respondsToSelector:@selector(audioPlayerDidPlayBuffer:)]) {
        [delegate audioPlayerDidPlayBuffer:buffer];
    }
}

#pragma mark - Volume manipulation


/// PUBLIC API - must be protected by synchronized
- (void)setVolume:(float)volume
{
	@synchronized(self)
	{
		AudioQueueSetParameter(audioQueue, kAudioQueueParam_Volume, volume);
	}
}


/// PUBLIC API but thread-safe
- (void)mute
{
    [self setVolume:0.0f];
}


/// PUBLIC API but thread-safe
- (void)unmute
{
    [self setVolume:1.0f];
}

@end
