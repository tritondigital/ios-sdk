//
//  StreamPlayer.m
//  Radio Disney
//
//  Created by Thierry Bucco on 09-04-13.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//

#import "StreamPlayer.h"
#include <stdlib.h>

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// AUDIO QUEUE CALLBACK FUNCTIONS
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

#pragma mark - Audio Queue callbacks

static void propertyListenerCallback(void *inClientData, AudioFileStreamID inAudioFileStream,AudioFileStreamPropertyID	inPropertyID, UInt32 * ioFlags)
{
	// Callback function that the parser calls when it finds a property value in the audio file stream. 
	
	StreamPlayer *player = (StreamPlayer*)inClientData;
	[player propertyChanged:inPropertyID flags:ioFlags];
}

static void packetsListenerCallback(void *inClientData, UInt32 inNumberBytes, UInt32 inNumberPackets, const void * inInputData, AudioStreamPacketDescription	*inPacketDescriptions)
{
	// Callback function that the parser calls when it finds audio data in the audio file stream. 
	
	StreamPlayer *player = (StreamPlayer*)inClientData;
	[player packetData:inInputData  numberOfPackets:inNumberPackets numberOfBytes:inNumberBytes packetDescriptions:inPacketDescriptions];
}

static void audioQueueOutputListenerCallback(void *inClientData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer)
{
	StreamPlayer *player = (StreamPlayer*)inClientData;
	
	pthread_mutex_lock(&player->mutex);
	
	[player outputCallbackWithBufferReference:inBuffer];
	
	pthread_cond_signal(&player->cond);
	pthread_mutex_unlock(&player->mutex);
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// audioQueueIsRunningCallback
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

static void audioQueueIsRunningCallback(void *inUserData, AudioQueueRef inAQ, AudioQueuePropertyID inID)
{
	StreamPlayer *player = (StreamPlayer*)inUserData;
	
	if (player)
	{
		[player retain];
		[player streamIsPlaying];
		[player release];
	}
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// audioSessionInteruptionListener
//
// Invoked if the audio session is interrupted (like when the phone rings)
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
static void audioSessionInteruptionListener(void *inClientData, UInt32 inInterruptionState)
{
	
}

@implementation StreamPlayer

@synthesize isPlaying;
@synthesize isBuffering;
@synthesize finished;
@synthesize failed;
@synthesize connected;
@synthesize bufferingDataSize;
@synthesize audioLevelTimer;
@synthesize streamSampleRate;
@synthesize streamFormatID;
@synthesize serverURL;


#pragma mark - Init / alloc / dealloc

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// setStreamURL
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)setStreamURL:(NSString *)inURL
{	
	if (serverURL)
	{
		[serverURL release];
		serverURL = nil;
	}
	
	serverURL = [inURL retain];
	isPlaying=false;
	finished=false;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// dealloc
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)dealloc
{
	[streamConnection release];
	[delegate release];
	[super dealloc];
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// setupPlaybackAudioQueueObject
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)setupPlaybackAudioQueueObject 
{	
	AudioSessionInitialize (
							NULL,                          // 'NULL' to use the default (main) run loop
							NULL,                          // 'NULL' to use the default run loop mode
							audioSessionInteruptionListener,  // a reference to your interruption callback
							self                       // data to pass to your interruption listener callback
							);
	
	//
	// Set the audio session category so that we continue to play if the
	// iPhone/iPod auto-locks.
	//
	
	UInt32 sessionCategory = kAudioSessionCategory_LiveAudio;
	AudioSessionSetProperty (kAudioSessionProperty_AudioCategory, sizeof (sessionCategory), &sessionCategory);
	AudioSessionSetActive(true);
	
	fileTypeHint = kAudioFileMP3Type;
	
	// create an audio file stream parser
	OSStatus err = AudioFileStreamOpen(self, propertyListenerCallback, packetsListenerCallback,  fileTypeHint, &audioFileStreamParser);
	
	if (err)
	{
		NSLog(@"AudioFileStreamOpen err");
	}
}

#pragma mark - Audio queue functions

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// streamIsPlaying
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (Boolean)streamIsPlaying
{
	UInt32		isRunning;
	UInt32		propertySize = sizeof (UInt32);
	OSStatus	result;
	
	result =	AudioQueueGetProperty (audioQueue, kAudioQueueProperty_IsRunning, &isRunning, &propertySize);
	
	if (result != noErr) 
	{
		[self errorOccuredOnStreamOperation:nil];
		return false;
	} 
	else 
	{
		self.isBuffering = FALSE;
		self.isPlaying = isRunning;
		self.finished = !isRunning;
		
		if (self.isPlaying == TRUE)
		{
			self.isBuffering = FALSE; // buffering = true, is setted in didreceive response from server
		}
		
		if (isRunning)
		{
			AudioSessionSetActive(true);
		}
		else
		{
			[NSRunLoop currentRunLoop];			
		}
	}
	
	return isRunning;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// startInThread
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)startInThread
{
	[self retain];
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// initialize a mutex and condition so that we can block on buffers in use.
	pthread_mutex_init(&mutex, NULL);
	pthread_cond_init(&cond, NULL);
	pthread_mutex_init(&copyDataToAQBufferMutex, NULL);
	
	self.bufferingDataSize = 0;
	
	[self setupPlaybackAudioQueueObject];
	
	// get stream to connect
	PLSParser *plsParser = [[PLSParser alloc] init];
	serverURL = [plsParser getServerURL];
	[serverURL retain];
	
	// we connect to the stream	
	streamRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:serverURL] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:15.0];
	streamConnection = [[NSURLConnection alloc] initWithRequest:streamRequest delegate:self];
	
	if (!streamConnection)
	{
		NSLog(@"connection failed");
	}
	
	do // main loop
	{
		CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.25, false);
		
		if (failed)
		{
			[self stop];
			
			NSLog(@"ERROR in thread");
		}
		
	} while ( (!finished || isPlaying) );
	
	if (streamConnection)
	{
		[streamConnection cancel];
		[streamConnection release];
		streamConnection = nil;
	}
	
	OSStatus err = AudioFileStreamClose(audioFileStreamParser);
	if (err) { NSLog(@"AudioFileStreamClose"); return; }
		
	if (started)
	{		
		err = AudioQueueDispose(audioQueue, true);
		if (err) { NSLog(@"AudioQueueDispose"); return; }
	}
	
	if ( [delegate respondsToSelector:@selector(streamPlayerReadyToBeReleased)] ) 
    {
        [delegate streamPlayerReadyToBeReleased];
    }
	
	[pool release];
	[self release];
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// play
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)play
{
	if (operationInProgress == FALSE)
	{
		operationInProgress = TRUE;
	
		// let the delegate knows
		[self connectingToStream:nil];
	
		[NSThread detachNewThreadSelector:@selector(startInThread) toTarget:self withObject:nil];
	}
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// stopPlaying
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)stop
{	
	OSStatus err;
	
	if (streamConnection)
	{
		[streamConnection cancel];
		[streamConnection release];
		streamConnection = nil;
		[self streamStopped:nil];
		
		if (finished)
		{
			return;
		}
		
		if (started)
		{
			pthread_mutex_lock(&copyDataToAQBufferMutex);

			if (audioQueue)
			{
				err = AudioQueueFlush(audioQueue);
				if (err) 
				{ 
					NSLog(@"Err AudioQueueFlush");
				}
				
				err = AudioQueueStop(audioQueue, true);
				if (err) 
				{ 
					NSLog(@"Err AudioQueueStop");
				}
			}
			
			finished = true;
			
			pthread_mutex_unlock(&copyDataToAQBufferMutex);
			
			pthread_mutex_lock(&mutex);
			pthread_cond_signal(&cond);
			pthread_mutex_unlock(&mutex);
		}
		else
		{
			self.isPlaying = FALSE;
			finished = TRUE;
		}
	}
}

#pragma mark - Connection related functions

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// connection
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data
{
	OSStatus err;
	
	if (failed || finished)
	{
		return;
	}
	
	// If we are buffering, we calculate buffered percentage
	if ((self.isBuffering == TRUE) && (self.isPlaying == FALSE) )
	{
		float bufferPercentageLoaded = 0;
		unsigned int totalDataBytesToLoadWhenBuffering = kAQBufSize;
		
		self.bufferingDataSize += [data length];
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
		
		[self streamBuffering:bufferPercentageLoaded];
	}
	
	if (discontinuous)
	{
		err = AudioFileStreamParseBytes(audioFileStreamParser, [data length], [data bytes], kAudioFileStreamParseFlag_Discontinuity);
	}
	else
	{
		err = AudioFileStreamParseBytes(audioFileStreamParser, [data length], [data bytes], 0);
	}
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// willCacheResponse
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
	return nil;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// connectionStoppedReconnect
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

-(void)connectionStoppedReconnect
{
	self.connected = false;
	[self stop];	
	
	[delegate performSelector:@selector(connectiondidFail)];
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// connectionDidFinishLoading
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)connectionDidFinishLoading:(NSURLConnection *)inConnection
{	
	[self connectionStoppedReconnect];
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// didFailWithError
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	[self connectionStoppedReconnect];
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// didReceiveResponse
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{ 	
	self.connected = true;
	self.isBuffering = true;
	
	operationInProgress = FALSE;
	
	// we receive a content-type
	// id different we restart audioqueue
	static NSString *oldContentType;
	
	if (contentType)
	{
		oldContentType = [NSString stringWithString:contentType];
	}
	
	contentType = [response MIMEType];

	if ([contentType compare:@"audio/mpeg"] == NSOrderedSame)
	{
		fileTypeHint = kAudioFileMP3Type;
	}
	else if ([contentType rangeOfString:@"audio/aac"].length > 0)
	{
		fileTypeHint = kAudioFileAAC_ADTSType;
	}
	else
	{
		// error
		[self stop];
		[delegate performSelectorOnMainThread:@selector(errorOccuredOnStreamOperation:) withObject:nil waitUntilDone:NO];
	}
} 

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// propertyChanged
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)propertyChanged:(AudioFileStreamPropertyID)propertyID flags:(UInt32*)flags
{
	OSStatus err = noErr;
	
	switch (propertyID)
	{
		case kAudioFileStreamProperty_ReadyToProducePackets:
		{			
			discontinuous = true;
			
			UInt32 asbdSize = sizeof(audioFormat);
			err = AudioFileStreamGetProperty(audioFileStreamParser,  kAudioFileStreamProperty_DataFormat, &asbdSize, &audioFormat);
			
			self.streamSampleRate = audioFormat.mSampleRate;
			self.streamFormatID = audioFormat.mFormatID;
						
			// Creates a new playback audio queue object.
			err = AudioQueueNewOutput(&audioFormat, audioQueueOutputListenerCallback, self, NULL, NULL, 0, &audioQueue);
			if (err) 
			{
				failed = true;
				break;
			}
			
			// listen to the "isRunning" property
			err = AudioQueueAddPropertyListener(audioQueue, kAudioQueueProperty_IsRunning, audioQueueIsRunningCallback, self);
			if (err)
			{
				failed = true;
				break;
			}
			
			// allocate audio queue buffers and enqueue buffers
			for (unsigned int i = 0; i < kNumAQBufs; i++)
				err = AudioQueueAllocateBuffer(audioQueue, kAQBufSize, &audioQueueBuffer[i]);
			
			// get the cookie size
			UInt32 cookieSize = 0;
			Boolean writable;
			err = AudioFileStreamGetPropertyInfo(audioFileStreamParser, kAudioFileStreamProperty_MagicCookieData, &cookieSize, &writable);
			if (!err) 
			{
				// get the cookie data
				void* cookieData = calloc(1, cookieSize);
				err = AudioFileStreamGetProperty(audioFileStreamParser, kAudioFileStreamProperty_MagicCookieData, &cookieSize, cookieData);
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
			
			AudioQueueEnqueueBuffer(audioQueue, audioQueueBuffer[fillBufferIndex], 0, NULL);
			
			[super setGain:gain];
			
			break;
		}
	}
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// packetData
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)packetData:(const void*)data numberOfPackets:(UInt32)numPackets numberOfBytes:(UInt32)numBytes packetDescriptions:(AudioStreamPacketDescription*)packetDescriptions
{
	discontinuous = false;
	
	// the following code assumes we're streaming VBR data.
	if (packetDescriptions)
	{
		for (int i = 0; i < numPackets; ++i)
		{		
			SInt64 packetOffset = packetDescriptions[i].mStartOffset;
			SInt64 packetSize = packetDescriptions[i].mDataByteSize;
			
			// if the space remaining in the buffer is not enough for this packet, then enqueue the buffer.
			size_t bufSpaceRemaining = kAQBufSize - bytesFilled;
			
			if (bufSpaceRemaining < packetSize)
			{
				[self enqueueBuffer];
			}
			
			pthread_mutex_lock(&copyDataToAQBufferMutex);
			
			// If the audio was terminated while waiting for a buffer, then
			// exit.
			if (finished == TRUE)
			{
				pthread_mutex_unlock(&copyDataToAQBufferMutex);
				return;
			}
			
			// copy data to the audio queue buffer
			AudioQueueBufferRef fillBuf = audioQueueBuffer[fillBufferIndex];
			memcpy((char*)fillBuf->mAudioData + bytesFilled, (const char*)data + packetOffset, packetSize);
			
			pthread_mutex_unlock(&copyDataToAQBufferMutex);
			
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

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// enqueueBuffer
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (OSStatus)enqueueBuffer
{
	OSStatus err = noErr;
	inuse[fillBufferIndex] = true; // set in use flag

	// enqueue buffer
	AudioQueueBufferRef fillBuf = audioQueueBuffer[fillBufferIndex];
	fillBuf->mAudioDataByteSize = bytesFilled;
	
	if (packetsFilled)
	{
		err = AudioQueueEnqueueBuffer(audioQueue, fillBuf, packetsFilled, packetDescs);
	}
	else
	{
		err = AudioQueueEnqueueBuffer(audioQueue, fillBuf, 0, NULL);
	}
	
	if (err)
	{
		failed = true;
		return err;
	}
	
	if (!started)
	{
		err = AudioQueuePrime(audioQueue, 1, NULL);   
		if (err)  
		{
			failed = true;
			return err;  
		}  
		
		err = AudioQueueStart(audioQueue, NULL); // start the queue if it has not been started already
		if (err)
		{
			failed = true;
			return err;
		}
		
		started = true;
	}
	
	// go to next buffer
	if (++fillBufferIndex >= kNumAQBufs) fillBufferIndex = 0;
	bytesFilled = 0;		// reset bytes filled
	packetsFilled = 0;		// reset packets filled
	
	// wait until next buffer is not in use
	
	pthread_mutex_lock(&mutex); 
	while (inuse[fillBufferIndex] && !finished) 
	{
		pthread_cond_wait(&cond, &mutex);
		
		if (finished)
		{
			break;
		}
	}
	pthread_mutex_unlock(&mutex);
	
	
	return err;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// findQueueBuffer
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (int)findQueueBuffer:(AudioQueueBufferRef)inBuffer
{
	for (unsigned int i = 0; i < kNumAQBufs; i++)
	{
		if (inBuffer == audioQueueBuffer[i]) return i;
	}
	return -1;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// outputCallbackWithBufferReference
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)outputCallbackWithBufferReference:(AudioQueueBufferRef)buffer
{
	unsigned int bufIndex = [self findQueueBuffer:buffer];
	inuse[bufIndex] = false;
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
	[del retain];
    delegate = del;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// delegate
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (id)delegate
{
    return delegate;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// streamBuffering
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)streamBuffering:(float)percentage
{
    if ( [delegate respondsToSelector:@selector(streamBuffering:)] ) 
    {
        [delegate streamBuffering:percentage];
    }
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// connectingToStream
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)streamPlaying:(NSNotification *)notification
{	
    if ( [delegate respondsToSelector:@selector(streamPlaying:)] ) 
    {
        [delegate streamPlaying:notification];
    }
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// connectingToStream
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)connectingToStream:(NSNotification *)notification
{	
    if ( [delegate respondsToSelector:@selector(connectingToStream:)] ) 
    {
        [delegate connectingToStream:notification];
    }
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// streamStopped
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)streamStopped:(NSNotification *)notification
{
	isBuffering = FALSE;
	self.bufferingDataSize = 0;
	operationInProgress = FALSE;
	
    if ( [delegate respondsToSelector:@selector(streamStopped:)] ) 
    {
        [delegate streamStopped:notification];
    }
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// errorOccuredOnStreamOperation
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)errorOccuredOnStreamOperation:(NSNotification *)notification
{
	isBuffering = FALSE;
	operationInProgress = FALSE;
	
    if ( [delegate respondsToSelector:@selector(errorOccuredOnStreamOperation:)] ) 
    {
        [delegate errorOccuredOnStreamOperation:notification];
    }
}

@end