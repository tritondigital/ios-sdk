//
//  CuePointEvent.h
//  TritonPlayer
//
//  Copyright 2014 Triton Digital. All rights reserved.
//

#import <Foundation/Foundation.h>

// STR_CUE_TYPE values
extern NSString *const EventTypeAd;
extern NSString *const EventTypeAudio;
extern NSString *const EventTypeCustom;
extern NSString *const EventTypeProfanity;
extern NSString *const EventTypeRecording;
extern NSString *const EventTypeSidekick;
extern NSString *const EventTypeSpeech;
extern NSString *const EventTypeSweeper;
extern NSString *const EventTypeTrack;
extern NSString *const EventTypeUnknown;

// --------------------------------------------------------------------------------------------
// Common
// --------------------------------------------------------------------------------------------
extern NSString *const CommonCueDisplayKey;
extern NSString *const CommonCueTimeDurationKey;
extern NSString *const CommonCueTimeStartKey;
extern NSString *const CommonCueTitleKey;
extern NSString *const CommonCueTypeKey;

extern NSString *const CommonProgramTimeDurationKey;
extern NSString *const CommonProgramTimeStartKey;
extern NSString *const CommonProgramGuestNIdKey;
extern NSString *const CommonProgramGuestNNameKey;
extern NSString *const CommonProgramHostNIdKey;
extern NSString *const CommonProgramHostNNameKey;
extern NSString *const CommonProgramIdKey;
extern NSString *const CommonProgramTitleKey;
extern NSString *const CommonProgramGuestNHomepageKey;
extern NSString *const CommonProgramGuestNPictureURLKey;
extern NSString *const CommonProgramHomepageKey;
extern NSString *const CommonProgramHostNHomepage;
extern NSString *const CommonProgramHostPictureURLKey;
extern NSString *const CommonProgramImageKey;

// --------------------------------------------------------------------------------------------
// Ad
// --------------------------------------------------------------------------------------------
extern NSString *const AdReplaceKey;
extern NSString *const AdIdKey;
extern NSString *const AdTypeKey;
extern NSString *const AdVastKey;
extern NSString *const AdVastURLKey;
extern NSString *const AdURLKey;
extern NSString *const AdURL1Key;
extern NSString *const AdURL2Key;
extern NSString *const AdURL3Key;
extern NSString *const AdURL4Key;

// --------------------------------------------------------------------------------------------
// Sweeper
// --------------------------------------------------------------------------------------------
extern NSString *const SweeperIdKey;
extern NSString *const SweeperTypeKey;


// --------------------------------------------------------------------------------------------
// Track
// --------------------------------------------------------------------------------------------
extern NSString *const TrackGenreKey;
extern NSString *const TrackAlbumNameKey;
extern NSString *const TrackAlbumPublisherKey;
extern NSString *const TrackAlbumYearKey;
extern NSString *const TrackArtistNameKey;
extern NSString *const TrackFormatKey;
extern NSString *const TrackIdKey;
extern NSString *const TrackIsrcKey;
extern NSString *const TrackCoverURLKey;
extern NSString *const TrackNowPlayingURLKey;
extern NSString *const TrackProductURLKey;

// --------------------------------------------------------------------------------------------
// Deprecated
// --------------------------------------------------------------------------------------------
extern NSString *const LegacyTypeKey;
extern NSString *const LegacyAdImageURLKey;
extern NSString *const LegacyBuyURLKey;

@class CuePointEventController;

/**
 * CuePointEvent stores all the information about cue points received from the server (ads, track information etc.).
 * For more details, see *STWCue_Metadata_Dictionary.pdf*
 */
@interface CuePointEvent : NSObject

/// @name Cue Point Properties

/// Timestamp The *timestamp* in which the cuepoint event should be executed.
@property (readonly, nonatomic) NSTimeInterval timestamp;

/// Contains all cue point data, which can be accessed by the constants declare in CuePointEvent.h.
@property (readonly, strong) NSDictionary		*data;

/// The type of the cue point. Refer to *STWCue_Metadata_Dictionary.pdf* for available types. The constants for each available type is defined in CuePointEvent.h.
@property (readonly, strong) NSString           *type;

/// Tells whether the execution of the cue point was canceled.
@property (readonly, assign) BOOL executionCanceled;

/// @name Creating a CuePointEvent

/**
 * Initializes a CuePoitEvent object. This is the designated initializer.
 *
 * @param inAMFData Dictionary containing *data* in AMF format.
 * @param inTimestamp The *timestamp* in which the cuepoint event should be executed.
 *
 * @return The newly-initialized CuePointEvent object
 */

-(instancetype)initEventWithAMFObjectData:(NSDictionary *)inAMFData andTimestamp:(NSTimeInterval)inTimestamp;

/**
 * Initializes a CuePoitEvent object.
 *
 * @param data Dictionary containing *data* in AMF format.
 * @param timestamp The *timestamp* in which the cuepoint event should be executed.
 *
 * @return The newly-initialized CuePointEvent object
 */

-(instancetype)initWithData:(NSDictionary *)data andTimestamp:(NSTimeInterval)timestamp;

@end
