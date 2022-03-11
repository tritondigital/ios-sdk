//
//  TDSBMPlayer.m
//  FLVStreamPlayerLib64
//
//  Created by Carlos Pereira on 2014-10-08.
//
//

#import "TDSBMPlayer.h"
#import "TDEventSource.h"
#import "CuePointEvent.h"
#import "Logs.h"

@import QuartzCore;

#define kEventSourceTimeout 7200
#define kEventSourceMaxRetryCount 2
#define kCuePointEventType @"onCuePoint"

NSString *const SettingsSBMURLKey = @"SBMURL";

@interface TDSBMPlayer ()

@property (nonatomic, strong) TDEventSource *sidebandEventSource;
@property (nonatomic, assign) NSTimeInterval startTime;

@property (nonatomic, copy) NSURL *url;

@property (nonatomic, assign, getter=isStopped) BOOL stopped;

@end

@implementation TDSBMPlayer

+(NSString *)generateSBMSessionId {
    return [[[NSUUID UUID] UUIDString] lowercaseString];
}

-(instancetype)init {
    return [self initWithSettings:nil];
}

-(instancetype)initWithSettings:(NSDictionary *)settings {
    self = [super init];
    if (self) {
        _autoSynchronizeCuePoints = YES;

        [self updateSettings:settings];
    }
    return self;
}

-(void)updateSettings:(NSDictionary *)settings {
    
    self.url = settings[SettingsSBMURLKey];
}

-(void) play {
    
    if(self.sidebandEventSource != nil) return;
    
    self.sidebandEventSource = [[TDEventSource alloc] initWithURL:self.url timeoutInterval:kEventSourceTimeout maxRetries:kEventSourceMaxRetryCount];
    
    self.stopped = NO;
    
     __weak TDSBMPlayer *weakSelf = self;
    
    [self.sidebandEventSource onOpen:^(TDEvent *event) {
        if (self.isStopped) return;
        
        self.startTime = CACurrentMediaTime();
        
        if ([weakSelf.delegate respondsToSelector:@selector(sbmPlayerDidOpenConnection:)]) {
            [weakSelf.delegate sbmPlayerDidOpenConnection:weakSelf];
        }
    }];
    
    [self.sidebandEventSource onError:^(TDEvent *event) {
        if (self.isStopped) return;
        
        [weakSelf processErrorEvent:event];
    }];
    
    [self.sidebandEventSource onMessage:^(TDEvent *event) {
        if (self.isStopped) return;
        
        [weakSelf processMessageEvent:event];
    }];
}

-(void) stop {
    [self close];
}

-(void) close {
    self.stopped =YES;
    [self.sidebandEventSource close];
    self.sidebandEventSource = nil;
}

-(NSTimeInterval)currentPlaybackTime {
    return CACurrentMediaTime() - self.startTime;
}

-(CMTime)latestPlaybackTime {
    return CMTimeMake(1,10);
}

-(void)setSynchronizationOffset:(NSTimeInterval)synchronizationOffset {
    _synchronizationOffset = synchronizationOffset;
    PLAYER_LOG(@"Sync offset is %f", synchronizationOffset);
}

-(void) processMessageEvent:(TDEvent *) event {
    @autoreleasepool {
        NSError *error = nil;
        NSMutableDictionary *object = [NSJSONSerialization JSONObjectWithData:[event.data dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&error];
        
        if (error) {
            PLAYER_LOG(@"MetadataPlayer->Error parsing JSON: %@", error.localizedDescription);
        }
        
        // Ignore hls control cuePoints for the moment
        if ([[object objectForKey:@"name"] isEqualToString:@"hls"]) {
            return;
        }
        
        // Check for CuePoint event type
        if ([[object objectForKey:@"type"] isEqualToString:kCuePointEventType]) {
            CuePointEvent* cuePoint = [[CuePointEvent alloc] initEventWithAMFObjectData:object andTimestamp:[[object objectForKey:@"timestamp"] doubleValue]];
            
            PLAYER_LOG(@"TDSBMPlayer->cuepoint arrived with timestamp %f", [[object objectForKey:@"timestamp"] doubleValue]);
            
            __weak TDSBMPlayer *weakSelf = self;
            
            void (^delegateBlock)() = ^{
                if ([_delegate respondsToSelector:@selector(sbmPlayer:didReceiveCuePointEvent:)]) {
                    [_delegate sbmPlayer:weakSelf didReceiveCuePointEvent:cuePoint];
                }
            };
            
            if (self.autoSynchronizeCuePoints && cuePoint.timestamp != 0) {
                NSTimeInterval difference = (cuePoint.timestamp / 1000) - self.currentPlaybackTime + self.synchronizationOffset;
                
                PLAYER_LOG(@"TDSBMPlayer->dispatching in %f seconds", difference);
                
                if (difference < 0.0) {
                    difference = 0.0;
                }
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, difference * NSEC_PER_SEC), dispatch_get_main_queue(), delegateBlock);
                
            } else {
                delegateBlock();
            }
        }
    }
}

-(void) processErrorEvent:(TDEvent *) event {
    PLAYER_LOG(@"Side-Band Metadata failed. Closing and forwarding error");
    [self close];
    
    if ([self.delegate respondsToSelector:@selector(sbmPlayer:didFailConnectingWithError:)]) {
        [self.delegate sbmPlayer:self didFailConnectingWithError:event.error];
    }
}

@end
