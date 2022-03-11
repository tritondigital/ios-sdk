//
//  CuePointEvent.m
//  iPhoneV2
//
//  Created by Thierry Bucco on 09-03-26.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//

#import "CuePointEventController.h"
#import "CuePointEvent.h"
#import "FLVStreamPlayerLibConstants.h"
#import "CuePointEventProtected.h"
#import "Logs.h"

// STR_CUE_TYPE values
NSString *const EventTypeAd         = @"ad";
NSString *const EventTypeAudio      = @"audio";
NSString *const EventTypeCustom     = @"custom";
NSString *const EventTypeProfanity  = @"profanity";
NSString *const EventTypeRecording  = @"recording";
NSString *const EventTypeSidekick   = @"sidekick";
NSString *const EventTypeSpeech     = @"speech";
NSString *const EventTypeSweeper    = @"sweeper";
NSString *const EventTypeTrack      = @"track";
NSString *const EventTypeUnknown    = @"unknown";

// Dictionary field representing all the cue point parameters
NSString *const CommonCueDataKey = @"cue_type_data";

// --------------------------------------------------------------------------------------------
// Common
// --------------------------------------------------------------------------------------------
NSString *const CommonCueDisplayKey                         = @"cue_display";
NSString *const CommonCueTimeDurationKey                    = @"cue_time_duration";
NSString *const CommonCueTimeStartKey                       = @"cue_time_start";
NSString *const CommonCueTitleKey                           = @"cue_title";
NSString *const CommonCueTypeKey                            = @"cue_type";

NSString *const CommonProgramTimeDurationKey                = @"program_time_duration";
NSString *const CommonProgramTimeStartKey                   = @"program_time_start";
NSString *const CommonProgramGuestNIdKey                    = @"program_guest_N_id";
NSString *const CommonProgramGuestNNameKey                  = @"program_guest_N_name";
NSString *const CommonProgramHostNIdKey                     = @"program_host_N_id";
NSString *const CommonProgramHostNNameKey                   = @"program_host_N_name";
NSString *const CommonProgramIdKey                          = @"program_id";
NSString *const CommonProgramTitleKey                       = @"program_title";
NSString *const CommonProgramGuestNHomepageKey              = @"program_guest_N_homepage_url";
NSString *const CommonProgramGuestNPictureURLKey            = @"program_guest_N_picture_url";
NSString *const CommonProgramHomepageKey                    = @"program_homepage_url";
NSString *const CommonProgramHostNHomepage                  = @"program_host_N_homepage_url";
NSString *const CommonProgramHostPictureURLKey              = @"program_host_N_picture_url";
NSString *const CommonProgramImageKey                       = @"program_image_url";


// --------------------------------------------------------------------------------------------
// Ad
// --------------------------------------------------------------------------------------------
NSString *const AdReplaceKey    = @"ad_replace";
NSString *const AdIdKey         = @"ad_id";
NSString *const AdTypeKey       = @"ad_type";
NSString *const AdVastKey       = @"ad_vast";
NSString *const AdVastURLKey    = @"ad_vast_url";
NSString *const AdURLKey        = @"ad_url";
NSString *const AdURL1Key       = @"ad_url_1";
NSString *const AdURL2Key       = @"ad_url_2";
NSString *const AdURL3Key       = @"ad_url_3";
NSString *const AdURL4Key       = @"ad_url_4";

// --------------------------------------------------------------------------------------------
// Sweeper
// --------------------------------------------------------------------------------------------
NSString *const SweeperIdKey   = @"sweeper_id";
NSString *const SweeperTypeKey = @"sweeper_type";


// --------------------------------------------------------------------------------------------
// Track
// --------------------------------------------------------------------------------------------
NSString *const TrackGenreKey                   = @"track_genre";
NSString *const TrackAlbumNameKey               = @"track_album_name";
NSString *const TrackAlbumPublisherKey          = @"track_album_publisher";
NSString *const TrackAlbumYearKey               = @"track_album_year";
NSString *const TrackArtistNameKey              = @"track_artist_name";
NSString *const TrackFormatKey                  = @"track_format";
NSString *const TrakIdKey                       = @"track_id";
NSString *const TrackIsrcKey                    = @"track_isrc";
NSString *const TrackCoverURLKey                = @"track_cover_url";
NSString *const TrackNowPlayingURLKey           = @"track_nowplaying_url";
NSString *const TrackProductURLKey              = @"track_product_url";

// --------------------------------------------------------------------------------------------
// Deprecated
// --------------------------------------------------------------------------------------------
NSString *const LegacyTypeKey       = @"legacy_type";
NSString *const LegacyAdImageURLKey = @"legacy_ad_image_url";
NSString *const LegacyBuyURLKey     = @"legacy_buy_url";

@interface CuePointEvent () 

@property (nonatomic, strong) NSDictionary *data;
@property (nonatomic, assign) BOOL executionCanceled;
@property (nonatomic, strong) NSString      *type;
@property (nonatomic, strong) CuePointEventController *cuePointEventController;
@property (nonatomic, assign) NSTimeInterval timestamp;

@end

@interface CuePointEvent (Private) 
- (void)executeEvent;
@end

@implementation CuePointEvent

@synthesize executionCanceled;

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// dealloc
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)dealloc
{
	FLOG(@"CuePointEvent RELEASED");

}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// initEventWithAMFObjectData
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (instancetype)initEventWithAMFObjectData:(NSDictionary *)inAMFData andTimestamp:(NSTimeInterval)inTimestamp
{
    self = [super init];
    
    if (self) {
        if (!inAMFData) {
            return nil;
        }
        
        self.type = [inAMFData objectForKey:@"name"];
        self.data = [inAMFData objectForKey:@"parameters"];
        self.timestamp = inTimestamp;
        
        if (![_data objectForKey:CommonCueTitleKey]) {
            [self convertEventToSTWCue];
        }else{
            
            [_data setValue:[self removeCarriageReturn:[_data objectForKey:TrackArtistNameKey]] forKey:TrackArtistNameKey];
            
            [_data setValue:[self removeCarriageReturn:[_data objectForKey:TrackAlbumNameKey]] forKey:TrackAlbumNameKey];
        }
    }
    
    return self;
}

- (instancetype) initWithDictionary:(NSDictionary *) dictionary {
    self = [super init];
    
    if (self) {
        _type = [dictionary objectForKey:CommonCueTypeKey];
        _data = [dictionary objectForKey:CommonCueDataKey];
        
        [_data setValue:[self removeCarriageReturn:[_data objectForKey:TrackArtistNameKey]] forKey:TrackArtistNameKey];
        
        [_data setValue:[self removeCarriageReturn:[_data objectForKey:TrackAlbumNameKey]] forKey:TrackAlbumNameKey];
        
        _timestamp = [[dictionary objectForKey:CommonCueTimeStartKey] intValue];
    }
    
    return self;
}

-(instancetype)initWithData:(NSDictionary *)data andTimestamp:(NSTimeInterval)timestamp {
    self = [super init];
    
    if (self) {
        if (!data) {
            return nil;
        }
        
        self.type = [data objectForKey:CommonCueTypeKey];
        self.data = data;
        self.timestamp = timestamp;
        
        if (![_data objectForKey:CommonCueTitleKey]) {
            [self convertEventToSTWCue];
        } else{
            
            [_data setValue:[self removeCarriageReturn:[_data objectForKey:TrackArtistNameKey]] forKey:TrackArtistNameKey];
            
            [_data setValue:[self removeCarriageReturn:[_data objectForKey:TrackAlbumNameKey]] forKey:TrackAlbumNameKey];
        }
    }
    
    return self;
}

- (void) convertEventToSTWCue {
    
    NSMutableDictionary *stwCueData = [[NSMutableDictionary alloc] init];
    [stwCueData setObject:self.type forKey:LegacyTypeKey];
    
    if ([self.type isEqualToString:@"NowPlaying"]) {
        self.type = EventTypeTrack;
        
        NSString *artist = [self removeCarriageReturn:[self.data objectForKey:@"Artist"]];
        NSString *album =  [self removeCarriageReturn:[self.data objectForKey:@"Album"]];
        
        [stwCueData setObject:album forKey:TrackAlbumNameKey];
        [stwCueData setObject:artist forKey:TrackArtistNameKey];
        [stwCueData setObject:[self objectOrNil:[self.data objectForKey:@"IMGURL"]] forKey:TrackCoverURLKey];
        [stwCueData setObject:[self objectOrNil:[self.data objectForKey:@"Label"]] forKey:TrackAlbumPublisherKey];
        [stwCueData setObject:[self objectOrNil:[self.data objectForKey:@"Title"]] forKey:CommonCueTitleKey];
        [stwCueData setObject:[self objectOrNil:[self.data objectForKey:@"BuyNowURL"]] forKey:LegacyBuyURLKey];
        
    } else if ([self.type isEqualToString:@"Ads"]) {
        self.type = EventTypeAd;
        
        [stwCueData setObject:[self objectOrNil:[self.data objectForKey:@"BREAKADID"]] forKey:AdIdKey];
        [stwCueData setObject:[self objectOrNil:[self.data objectForKey:@"BREAKTYPE"]] forKey:AdTypeKey];
        [stwCueData setObject:[self objectOrNil:[self.data objectForKey:@"IMGURL"]] forKey:LegacyAdImageURLKey];
        
    } else {
        self.type = EventTypeUnknown;
        
    }
    
    self.data = stwCueData;
}

- (id) objectOrNil:(id) object {
    if (object) return object;
    
    return [NSNull null];
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// determineCuePointEventKeyType
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)determineCuePointEventKeyType
{

}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// startTimer
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)startTimer
{
	FLOG(@"Event will be executed in %d seconds", (int)self.timestamp);
	
	if (self.timestamp == 0)
	{
		[self executeEvent];
	}
	else
	{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self performSelector:@selector(executeEvent) withObject:nil afterDelay:self.timestamp];
        });
	}
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// executeEvent
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)executeEvent
{
	if (self.executionCanceled == FALSE)
	{
		// send notification to view controller in order to display event
		
		[self.cuePointEventController executeCuePointEvent:self];
	}
	else
	{
		[self hasBeenExecuted];
	}
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// hasBeenExecuted
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)hasBeenExecuted
{
	[self.cuePointEventController cuePointEventHasBeenExecuted:self];
}

- (NSString *)removeCarriageReturn:(NSString *)data
{
    if ( data != nil){
        data = [data stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] ];
    }
    
    return data;
}

@end
