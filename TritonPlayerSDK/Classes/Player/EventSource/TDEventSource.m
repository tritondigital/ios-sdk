//
//  EventSource.m
//  EventSource
//
//  Created by Neil on 25/07/2013.
//  Copyright (c) 2013 Neil Cowburn. All rights reserved.
//

#import "TDEventSource.h"
#import <CoreGraphics/CGBase.h>

static CGFloat const ES_RETRY_INTERVAL = 0.3;
static CGFloat const ES_DEFAULT_TIMEOUT = 300.0;
static NSInteger const ES_DEFAULT_MAX_RETRIES = 5;

static NSString *const ESKeyValueDelimiter = @":";
static NSString *const ESEventSeparatorLFLF = @"\n\n";
static NSString *const ESEventSeparatorCRCR = @"\r\r";
static NSString *const ESEventSeparatorCRLFCRLF = @"\r\n\r\n";
static NSString *const ESEventKeyValuePairSeparator = @"\n";

static NSString *const ESEventDataKey = @"data";
static NSString *const ESEventIDKey = @"id";
static NSString *const ESEventEventKey = @"event";
static NSString *const ESEventRetryKey = @"retry";

@interface TDEventSource () <NSURLConnectionDelegate, NSURLConnectionDataDelegate> {
    BOOL wasClosed;
}

@property (nonatomic, strong) NSURL *eventURL;
@property (nonatomic, strong) NSURLConnection *eventSource;
@property (nonatomic, strong) NSMutableDictionary *listeners;
@property (nonatomic, assign) NSTimeInterval timeoutInterval;
@property (nonatomic, assign) NSTimeInterval retryInterval;
@property (nonatomic, strong) id lastEventID;
@property (nonatomic, strong) NSMutableString *dataBuffer;

/// The number of reattempts to connect when there's a timeout or when the server is down. Cleared when the connection is established.
@property (nonatomic, assign) NSInteger numberOfRetries;

@property (nonatomic, assign) NSInteger maximumNumberOfRetries;

- (void)open;

@end

@implementation TDEventSource

+ (id)eventSourceWithURL:(NSURL *)URL
{
    return [[TDEventSource alloc] initWithURL:URL];
}

+ (id)eventSourceWithURL:(NSURL *)URL timeoutInterval:(NSTimeInterval)timeoutInterval maxRetries:(NSInteger) maxRetries
{
    return [[TDEventSource alloc] initWithURL:URL timeoutInterval:timeoutInterval maxRetries:maxRetries];
}

- (id)initWithURL:(NSURL *)URL
{
    return [self initWithURL:URL timeoutInterval:ES_DEFAULT_TIMEOUT maxRetries:ES_DEFAULT_MAX_RETRIES];
}

- (id)initWithURL:(NSURL *)URL timeoutInterval:(NSTimeInterval)timeoutInterval maxRetries:(NSInteger) maxRetries
{
    self = [super init];
    if (self) {
        _listeners = [NSMutableDictionary dictionary];
        _eventURL = URL;
        _timeoutInterval = timeoutInterval;
        _retryInterval = ES_RETRY_INTERVAL;
        _dataBuffer = [[NSMutableString alloc] init];
        _maximumNumberOfRetries = maxRetries;
        
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_retryInterval * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self open];
        });
    }
    return self;
}

- (void)addEventListener:(NSString *)eventName handler:(EventSourceEventHandler)handler
{
    if (self.listeners[eventName] == nil) {
        [self.listeners setObject:[NSMutableArray array] forKey:eventName];
    }
    
    [self.listeners[eventName] addObject:handler];
}

- (void)onMessage:(EventSourceEventHandler)handler
{
    [self addEventListener:MessageEvent handler:handler];
}

- (void)onError:(EventSourceEventHandler)handler
{
    [self addEventListener:ErrorEvent handler:handler];
}

- (void)onOpen:(EventSourceEventHandler)handler
{
    [self addEventListener:OpenEvent handler:handler];
}

- (void)open
{
    wasClosed = NO;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.eventURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:self.timeoutInterval];
    if (self.lastEventID) {
        [request setValue:self.lastEventID forHTTPHeaderField:@"Last-Event-ID"];
    }
    
    [request setHTTPMethod:@"GET"];
    
    self.eventSource = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
    
    if (![NSThread isMainThread]) {
        CFRunLoopRun();
    }
}

- (void)close
{
    wasClosed = YES;
    if(self.eventSource != nil)
    {
        [self.eventSource cancel];
        self.eventSource = nil;
    }
}

// ---------------------------------------------------------------------------------------------------------------------

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    if (httpResponse.statusCode == 200) {
        // Opened
        TDEvent *e = [TDEvent new];
        e.readyState = kEventStateOpen;
        
        NSArray *openHandlers = self.listeners[OpenEvent];
        for (EventSourceEventHandler handler in openHandlers) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.numberOfRetries = 0;
                handler(e);
            });
        }
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (self.numberOfRetries < self.maximumNumberOfRetries) {
        self.numberOfRetries++;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.retryInterval * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self open];
        });
    
    } else {
    
        TDEvent *e = [TDEvent new];
        e.readyState = kEventStateClosed;
        e.error = error;
        
        NSArray *errorHandlers = self.listeners[ErrorEvent];
        for (EventSourceEventHandler handler in errorHandlers) {
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(e);
            });
        }
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
		NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		
		if ([dataString hasSuffix:ESEventSeparatorLFLF] ||
				[dataString hasSuffix:ESEventSeparatorCRCR] ||
				[dataString hasSuffix:ESEventSeparatorCRLFCRLF]) {
				dataString = [dataString stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
				
				NSArray *events = [dataString componentsSeparatedByString:ESEventSeparatorLFLF];
				
				for (NSString *eventString in events) {
						TDEvent *e = [TDEvent new];
						e.readyState = kEventStateOpen;
						e.event = MessageEvent;
						
						NSMutableArray *components = [[eventString componentsSeparatedByString:ESEventKeyValuePairSeparator] mutableCopy];
						
						for (NSString *component in components) {
								if (component.length == 0) {
										continue;
								}
								
								NSInteger index = [component rangeOfString:ESKeyValueDelimiter].location;
								if (index == NSNotFound || index == (component.length - 2)) {
										continue;
								}
								
								NSString *key = [component substringToIndex:index];
								NSString *value = [component substringFromIndex:index + ESKeyValueDelimiter.length];
								
								if ([key isEqualToString:ESEventDataKey]) {
										[self.dataBuffer appendFormat:@"%@\n", value];
										
								} else if ([key isEqualToString:ESEventIDKey]) {
										e.id = value;
										self.lastEventID = e.id;
										
								} else if ([key isEqualToString:ESEventEventKey]) {
										e.event = value;
										
								} else if ([key isEqualToString:ESEventRetryKey]) {
										self.retryInterval = [value doubleValue];
										
								}
						}
						
						e.data = self.dataBuffer;
						self.dataBuffer = [NSMutableString string];
						
						NSArray *namedEventhandlers = self.listeners[e.event];
						for (EventSourceEventHandler handler in namedEventhandlers) {
								dispatch_async(dispatch_get_main_queue(), ^{
										handler(e);
								});
						}
				}
		}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (wasClosed) {
        return;
    }

    if (self.numberOfRetries < self.maximumNumberOfRetries) {
        self.numberOfRetries++;

        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.retryInterval * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self open];
        });
    } else {

        TDEvent *e = [TDEvent new];
        e.readyState = kEventStateClosed;
        e.error = [NSError errorWithDomain:@""
                                      code:e.readyState
                                  userInfo:@{ NSLocalizedDescriptionKey: @"Connection with the event source was closed." }];

        NSArray *errorHandlers = self.listeners[ErrorEvent];
        for (EventSourceEventHandler handler in errorHandlers) {
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(e);
            });
        }
    }
}


-(void)dealloc {
    [self close];
}



@end

// ---------------------------------------------------------------------------------------------------------------------

@implementation TDEvent

- (NSString *)description
{
    NSString *state = nil;
    switch (self.readyState) {
        case kEventStateConnecting:
            state = @"CONNECTING";
            break;
        case kEventStateOpen:
            state = @"OPEN";
            break;
        case kEventStateClosed:
            state = @"CLOSED";
            break;
    }
    
    return [NSString stringWithFormat:@"<%@: readyState: %@, id: %@; event: %@; data: %@>",
            [self class],
            state,
            self.id,
            self.event,
            self.data];
}

@end

NSString *const MessageEvent = @"message";
NSString *const ErrorEvent = @"error";
NSString *const OpenEvent = @"open";
