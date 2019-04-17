//
//  CuePointHistory.m
//  TritonPlayerSDK
//
//  Created by Carlos Pereira on 2015-04-06.
//  Copyright (c) 2015 Triton Digital. All rights reserved.
//

#import "TDCuePointHistory.h"
#import "TDCuePointHistoryParser.h"
@import QuartzCore;

NSString *const TDCuePointHistoryErrorDomain = @"com.tritondigital.cuepointhistory.error";

NSString *const kNowPlayingURL = @"https://np.tritondigital.com/public/nowplaying";
NSString *const kNowPlayingURLPreprod = @"https://playerservices.preprod01.streamtheworld.net/public/nowplaying";

#define kDelayBetweenCalls 10.0f

@interface TDCuePointHistory ()

@property (nonatomic, strong) TDCuePointHistoryParser *parser;
@property (nonatomic, assign) NSTimeInterval lastRequestTime;

// The last request url to check if the user made the same request twice
@property (nonatomic, strong) NSString *lastRequestURL;

// Cache last data received so it can be sent again in case the user is time capped
@property (nonatomic, strong) NSArray *lastHistoryItemsReceived;
@property (nonatomic, strong) NSError *lastErrorReceived;

@end

@implementation TDCuePointHistory

-(instancetype)init {
    self = [super init];
    if (self) {
        _parser = [[TDCuePointHistoryParser alloc] init];
        
        // Put the last request time in an expired state so it can fire the first time
        _lastRequestTime = CACurrentMediaTime() - kDelayBetweenCalls - 1;
    }
    return self;
}

-(void)requestHistoryForMount:(NSString *)mountName
             withMaximumItems:(NSInteger)maximum
              eventTypeFilter:(NSArray*)filter
            completionHandler:(void (^)(NSArray *historyItems,
                                        NSError *error))completionHandler {
    
    // Return an error if the mount is invalid
    if (!mountName || [mountName isEqualToString:@""]) {
        NSError *error = [NSError errorWithDomain:TDCuePointHistoryErrorDomain code:TDCuePointHistoryInvalidMountError userInfo:@{NSLocalizedDescriptionKey : @"The mount was not specified or is invalid."}];
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            completionHandler(nil, error);
        }];
        
        return;
    }
    
    // Create the request url
    NSString *stringUrl = [self generateStreamURLForMount:mountName maximum:maximum filter:filter];
    
    BOOL requestCapped = NO;
    
    // If the request is the same, impose a delay between calls
    if ([self.lastRequestURL isEqualToString:stringUrl]) {
        // Limit the amount of calls the
        NSTimeInterval timeBetweenCalls = CACurrentMediaTime() - self.lastRequestTime;
        
        requestCapped = timeBetweenCalls < kDelayBetweenCalls;
    }
    
    
    __weak TDCuePointHistory *weakSelf = self;
    
    
    if (!requestCapped) {

        [self.parser requestHistoryForURL:[NSURL URLWithString:stringUrl] completionBlock:^(NSArray *historyList, NSError *error) {
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                completionHandler(historyList, error);
            }];
            
            weakSelf.lastHistoryItemsReceived = historyList;
            weakSelf.lastErrorReceived = error;
        }];
        
        self.lastRequestTime = CACurrentMediaTime();
        self.lastRequestURL = stringUrl;
        
    } else {
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            completionHandler(weakSelf.lastHistoryItemsReceived, weakSelf.lastErrorReceived);
        }];
    }
    
}

-(NSString*)generateStreamURLForMount:(NSString *)mountName maximum:(NSInteger)maximum filter:(NSArray*)filter {
    BOOL usePreprod = [mountName rangeOfString:@".preprod"].location != NSNotFound;
    NSString *cleanMountName;
    NSMutableString *stringUrl;
    
    if (usePreprod) {
        stringUrl = [NSMutableString stringWithString:kNowPlayingURLPreprod];
        cleanMountName = [[mountName stringByDeletingPathExtension] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
    } else {
        stringUrl = [NSMutableString stringWithString:kNowPlayingURL];
        cleanMountName = [mountName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    }
    
    [stringUrl appendFormat:@"?mountName=%@", cleanMountName];
    
    if (maximum > 0) {
        [stringUrl appendFormat:@"&numberToFetch=%zd", maximum];
    }
    
    for (NSString *eventType in filter) {
        if (eventType && ![eventType isEqualToString:@""]) {
            [stringUrl appendFormat:@"&eventType=%@", eventType];
        }
    }
    return stringUrl;
}

@end
