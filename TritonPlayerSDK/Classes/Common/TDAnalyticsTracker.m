//
//  TDAnalyticsTracker.m
//  TritonPlayerSDK
//
//  Created by Mahamadou KABORE on 2016-04-26.
//  Copyright © 2016 Triton Digital. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TDAnalyticsTracker.h"
#import "TritonPlayer.h"

#define kCounterUpInterval         0.1f
#define kDictionaryInitialCapacity 15

NSString *const Key_TRACKER_ID                      = @"tid";
NSString *const Key_GA_VERSION                      = @"v";
NSString *const Key_USER_ID                         = @"cid";
NSString *const Key_TYPE                            = @"t";
NSString *const Key_APP_NAME                        = @"an";
NSString *const Key_APP_VERSION                     = @"av";
NSString *const Key_APP_MAJOR_VERSION               = @"aid";
NSString *const Key_APP_CATEGORY                    = @"aiid";

NSString *const Key_CATEGORY                        = @"ec";
NSString *const Key_ACTION                          = @"ea";
NSString *const Key_LABEL                           = @"el";
NSString *const Key_METRIC                          = @"cm";



NSString *const GA_RELEASE_HOST                     = @"https://www.google-analytics.com/collect";
NSString *const GA_DEBUG_HOST                       = @"https://www.google-analytics.com/debug/collect";
NSString *const GA_VERSION                          = @"1";
NSString *const GA_DEBUG_TRACKER_ID                 = @"";
NSString *const GA_RELEASE_TRACKER_ID               = @"";

NSString *const SDK_NAME                            = @"ios-sdk";
NSString *const SDK_CATEGORY_TRITON                 = @"player";
NSString *const SDK_CATEGORY_DEFAULT                = @"custom";



//Dimension Values
NSString *const DIMENSION_TECH                     = @"cd1";
NSString *const DIMENSION_MEDIA_TYPE               = @"cd2";
NSString *const DIMENSION_MOUNT                    = @"cd3";
NSString *const DIMENSION_STATION                  = @"cd4";
NSString *const DIMENSION_BROADCASTER              = @"cd5";
NSString *const DIMENSION_MEDIA_FORMAT             = @"cd6";
NSString *const DIMENSION_AD_SOURCE                = @"cd8";
NSString *const DIMENSION_AD_FORMAT                = @"cd9";
NSString *const DIMENSION_AD_PARSER                = @"cd10";
NSString *const DIMENSION_AD_BLOCK                 = @"cd11";
NSString *const DIMENSION_SBM                      = @"cd12";
NSString *const DIMENSION_HLS                      = @"cd13";
NSString *const DIMENSION_AUDIO_ADAPTIVE           = @"cd14";
NSString *const DIMENSION_IDFA                     = @"cd15";
NSString *const DIMENSION_ALTERNATE_CONTENT        = @"cd16";
NSString *const DIMENSION_AD_COMPANIONTYPE         = @"cd17";


//Streaming Connection States
NSString *const CONNECTION_SUCCESS                 = @"Success";
NSString *const CONNECTION_UNAVAILABLE             = @"Unavailable";
NSString *const CONNECTION_ERROR                   = @"Stream Error";
NSString *const CONNECTION_GEOBLOCKED              = @"GeoBlocking";
NSString *const CONNECTION_FAILED                  = @"Failed";


@interface TDAnalyticsTracker ()

@property (nonatomic, strong) NSString *userId;
@property (nonatomic, strong) NSTimer *counterUpTimer;
@property (nonatomic, strong) NSDate *upDate;
@property                     NSTimeInterval elapsetime;
@property                     BOOL  isTritonStdApp;
@property                     BOOL  hasBeenInitialized;



@property (nonatomic, copy)   NSString *hostURL;
@property (nonatomic, strong) NSMutableDictionary *requestParameters;

@end


@implementation TDAnalyticsTracker



+(instancetype)sharedTracker:(BOOL) isTritonApp
{

    static TDAnalyticsTracker *sharedTracker = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedTracker = [[self alloc] init];
        sharedTracker.isTritonStdApp = isTritonApp;
    });
    return sharedTracker;
}


+(instancetype)sharedTracker
{
    return [TDAnalyticsTracker sharedTracker:FALSE];
}



-(instancetype)init
{
    self = [super init];
    if (self)
    {
        self.requestParameters = [NSMutableDictionary dictionaryWithCapacity:kDictionaryInitialCapacity];
        self.elapsetime        = 0;
        self.userId            = [self createListenerId];
        
    }
    return self;
}


-(void) initialize
{
   if(!self.hasBeenInitialized)
   {
       self.hasBeenInitialized = YES;
       
       [self addMandatoryParams];
       
       
       [self addType:@"event"];
       
       [self addCategory:@"Init"];
       [self addAction:@"Config"];
       [self addLabel:@"Success"];
       
       [self addDimension:@"iOS"   withKey:DIMENSION_TECH];
       [self addDimension:@"false" withKey:DIMENSION_AD_BLOCK];
       [self addDimension:@"true"  withKey:DIMENSION_SBM];
       [self addDimension:@"true"  withKey:DIMENSION_HLS];
       [self addDimension:@"false" withKey:DIMENSION_AUDIO_ADAPTIVE];
       [self addDimension:@"true"  withKey:DIMENSION_IDFA];
       
       [self addMetric:0];
       
       
       //Send Request
       [self sendRequest];
   }

}

-(void) resetTracker
{
    [self resetParameters];
    [self.counterUpTimer invalidate];
    self.elapsetime = 0;

    [self addMandatoryParams];
}

-(NSString*) createListenerId
{
    NSString* listenerId = [[NSUserDefaults standardUserDefaults] objectForKey:@"uuid"];
    if (![listenerId length])
    {
        listenerId = [[NSUUID UUID] UUIDString];
        [[NSUserDefaults standardUserDefaults] setObject:listenerId forKey:@"uuid"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    return listenerId;
}

- (void) timerFired
{
    self.elapsetime+=kCounterUpInterval;
}

-(void) startTimer
{
    self.elapsetime = 0;
    
    self.counterUpTimer = nil;
    self.upDate         = nil;
    
    self.counterUpTimer = [NSTimer scheduledTimerWithTimeInterval:kCounterUpInterval target:self selector:@selector(timerFired) userInfo:nil repeats:YES];
   [self.counterUpTimer fire];
    self.upDate = [NSDate date];
}

-(NSTimeInterval) stopTimer
{
    if(self.counterUpTimer  != nil)
    {
        [self.counterUpTimer invalidate];
    }

    return -[self.upDate timeIntervalSinceNow]*1000;  //in milliseconds
}



-(void) sendRequest
{
   
    __weak TDAnalyticsTracker* weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW,0),^{
        
        NSString* requestUrl = [weakSelf buildRequest];
        
        // To avoid reaching the Google Analytics limit, we send 5% of the requests.
        int randomValue = arc4random_uniform(100);
        
        if(randomValue < 5 && requestUrl != nil)
        {
            // Create the request.
            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:requestUrl]];
            
            // Create url connection and fire request
            NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:nil];
            
        }
    
    });
    
}

-(NSString*) buildRequest
{
    // Fail when there's no mandatory fields
    if (self.hostURL == nil) {
        NSLog(@"TDAnalyticsTracker error: The host URL must be set.");
        return nil;
    }
    
    
    NSURLComponents *components = [NSURLComponents componentsWithString:self.hostURL];
    
    @autoreleasepool {
        
        NSMutableArray *query       = [NSMutableArray array];
        NSMutableDictionary *params = [self.requestParameters mutableCopy];
        
        
        for (NSString *key in params.allKeys) {
            [query addObject:[NSString stringWithFormat:@"%@=%@", key, params[key]]];
        }
        
        
        components.query = [query componentsJoinedByString:@"&"];
        
    }
    
    return [components.URL absoluteString];
}


-(void) addMandatoryParams
{
    
#if DEBUG
    NSString *host      = GA_DEBUG_HOST;
    NSString *trackerId = GA_DEBUG_TRACKER_ID;
#else
     NSString *host = GA_RELEASE_HOST;
     NSString *trackerId = GA_RELEASE_TRACKER_ID;
#endif
    
    [self setHostURL:host];
    
    [self addQueryParameterWithKey:Key_TRACKER_ID andValue:trackerId];
    
    //Version
    [self addQueryParameterWithKey:Key_GA_VERSION andValue:GA_VERSION];
    
    //User id
    [self addQueryParameterWithKey:Key_USER_ID andValue:self.userId];
    
    //App name
    [self addQueryParameterWithKey:Key_APP_NAME andValue:SDK_NAME];
    
    //App Major Version
    [self addQueryParameterWithKey:Key_APP_MAJOR_VERSION andValue:[TritonSDKVersion substringToIndex:3]];
    
    //App version
    [self addQueryParameterWithKey:Key_APP_VERSION andValue:TritonSDKVersion];
    
    
    //SDK Category
    NSString*sdkCat = self.isTritonStdApp ? SDK_CATEGORY_TRITON : SDK_CATEGORY_DEFAULT;
    [self addQueryParameterWithKey:Key_APP_CATEGORY andValue:sdkCat];
    

}


-(void) addType:(NSString*) type
{
    [self addQueryParameterWithKey:Key_TYPE andValue:type];
}


-(void) addCategory:(NSString*) category
{
    [self addQueryParameterWithKey:Key_CATEGORY andValue:category];
}

-(void) addAction:(NSString*) action
{
    [self addQueryParameterWithKey:Key_ACTION andValue:action];
}

-(void) addLabel:(NSString*) label
{
    [self addQueryParameterWithKey:Key_LABEL andValue:label];
}

-(void) addDimension:(NSString*) dimen withKey:(NSString*) key
{
    [self addQueryParameterWithKey:key andValue:dimen];
}



-(void) addMetric:(NSTimeInterval) metric
{
    [self addQueryParameterWithKey:Key_METRIC andValue:[NSString stringWithFormat:@"%f",metric]];
}


-(void)resetParameters {
    self.requestParameters = [NSMutableDictionary dictionaryWithCapacity:kDictionaryInitialCapacity];
}

-(void)setHostURL:(NSString *)hostURL {
    _hostURL = hostURL;
}


-(void) addQueryParameterWithKey:(NSString*) key andValue:(NSString*) value
{
 if(value != nil)
 {
    self.requestParameters[key] = value;
 }
}

-(void) addQueryParameterWithKey:(NSString*) key andBoolValue:(BOOL) value
{
    [self addQueryParameterWithKey:key andValue: [NSString stringWithFormat:@"%@", @(value)]];
}





#pragma mark - Streaming Connection
-(void) trackStreamingConnectionSuccessWithMount:(NSString*) mount withBroadcaster:(NSString*) broadcaster withLoadTime: (NSTimeInterval) loadTime
{
    NSDictionary* dimens = [self createStreamingDimensionsWithMount:mount withBroadcaster:broadcaster];
    [self trackStreamingConnectionWithState:CONNECTION_SUCCESS withDimensions:dimens withLoadTime:loadTime];
}

-(void) trackStreamingConnectionUnavailableWithMount:(NSString*) mount withBroadcaster:(NSString*) broadcaster withLoadTime: (NSTimeInterval) loadTime
{
    NSDictionary* dimens = [self createStreamingDimensionsWithMount:mount withBroadcaster:broadcaster];
    [self trackStreamingConnectionWithState:CONNECTION_UNAVAILABLE withDimensions:dimens withLoadTime:loadTime];
}

-(void) trackStreamingConnectionErrorWithMount:(NSString*) mount withBroadcaster:(NSString*) broadcaster withLoadTime: (NSTimeInterval) loadTime
{
    NSDictionary* dimens = [self createStreamingDimensionsWithMount:mount withBroadcaster:broadcaster];
    [self trackStreamingConnectionWithState:CONNECTION_ERROR withDimensions:dimens withLoadTime:loadTime];

}

-(void) trackStreamingConnectionGeoblockedWithMount:(NSString*) mount withBroadcaster:(NSString*) broadcaster withLoadTime: (NSTimeInterval) loadTime
{
    NSDictionary* dimens = [self createStreamingDimensionsWithMount:mount withBroadcaster:broadcaster];
    [self trackStreamingConnectionWithState:CONNECTION_GEOBLOCKED withDimensions:dimens withLoadTime:loadTime];

}

-(void) trackStreamingConnectionFailedWithMount:(NSString*) mount withBroadcaster:(NSString*) broadcaster withLoadTime: (NSTimeInterval) loadTime
{
    NSDictionary* dimens = [self createStreamingDimensionsWithMount:mount withBroadcaster:broadcaster];
    [self trackStreamingConnectionWithState:CONNECTION_FAILED withDimensions:dimens withLoadTime:loadTime];

}

-(NSDictionary*) createStreamingDimensionsWithMount:(NSString*)mount withBroadcaster:(NSString*) broadcaster
{
    NSDictionary* dimens =  @{DIMENSION_MEDIA_TYPE :  @"Audio" ,
                              DIMENSION_MOUNT :       mount,
                              DIMENSION_BROADCASTER : broadcaster,
                              DIMENSION_HLS :         @"true"
                              };
    
    return dimens;
}


-(void) trackStreamingConnectionWithState:(NSString*) state withDimensions: (NSDictionary*) dimens withLoadTime:(NSTimeInterval) loadtime
{
    [self resetTracker];
    
    [self addType:@"event"];
    [self addCategory:@"Streaming"];
    [self addAction:@"Connection"];
    [self addLabel:state];
    
    if(dimens != nil  && [dimens count]> 0)
    {
      for(NSString* key in [dimens allKeys])
      {
          [self addDimension:[dimens objectForKey:key] withKey:key];
      }
    }
    
    [self addMetric:loadtime];
    
    //send request
    [self sendRequest];

}


#pragma mark - Ad Preroll
-(void) trackAdPrerollSuccessWithFormat:(NSString*) adFormat isVideo:(BOOL) isvideo withLoadTime: (NSTimeInterval) loadTime
{
    [self trackAdPrerollWithFormat:adFormat withResult:@"Success" withLoadTime:loadTime andKindOf:isvideo];

}

-(void) trackAdPrerollErrorWithFormat:(NSString*) adFormat isVideo:(BOOL) isvideo withLoadTime: (NSTimeInterval) loadTime
{
    [self trackAdPrerollWithFormat:adFormat withResult:@"Error" withLoadTime:loadTime andKindOf:isvideo];

}

-(void) trackAdPrerollWithFormat:(NSString*) adFormat withResult:(NSString*) result withLoadTime:(NSTimeInterval) loadTime andKindOf:(BOOL) isVideo
{

    [self resetTracker];
    
    [self addType:@"event"];
    [self addCategory:@"Ad"];
    [self addAction:@"Preroll"];
    [self addLabel:result];
    [self addMetric:loadTime];
    
    NSDictionary* dimens = [self createAdPrerollDimensionsWithFormat:adFormat ofKind:isVideo];
    if(dimens != nil  && [dimens count]> 0)
    {
        for(NSString* key in [dimens allKeys])
        {
            [self addDimension:[dimens objectForKey:key] withKey:key];
        }
    }
    
    
    //send request
    [self sendRequest];

}

-(NSDictionary*) createAdPrerollDimensionsWithFormat:(NSString*) adFormat ofKind:(BOOL) isVideo
{
    NSString* mediaType  = isVideo? @"Video":@"Audio";
    NSDictionary* dimens =  @{DIMENSION_AD_FORMAT :       adFormat ,
                              DIMENSION_AD_PARSER :       @"VASTModule" ,
                              DIMENSION_AD_SOURCE :       @"TAP" ,
                              DIMENSION_MEDIA_TYPE :      mediaType
                              };

    return dimens;
}

#pragma mark - On demand
-(void) trackOnDemandSuccess
{
    [self trackOndemandPlayWithResult:@"Success"];
}

-(void) trackOnDemandError
{
   [self trackOndemandPlayWithResult:@"Error"];
}


-(void) trackOndemandPlayWithResult:(NSString*) result
{
    [self resetTracker];
    
    [self addType:@"event"];
    [self addCategory:@"On Demand"];
    [self addAction:@"Play"];
    [self addLabel:result];
    
    
    
    //send request
    [self sendRequest];

}
@end
