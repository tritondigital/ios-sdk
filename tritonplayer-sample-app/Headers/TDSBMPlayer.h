//
//  TDSBMPlayer.h
//  Triton iOS SDK
//
//  Copyright (c) 2015 Triton Digital. All rights reserved.
//

#import <Foundation/Foundation.h>

/// An NSURL representing the side-band metadata 
extern NSString *const SettingsSBMURLKey;

@class TDSBMPlayer;
@class CuePointEvent;

/**
 * TDSBMPlayerPlayerDelegate defines methods you can implement to handle connection notifications and to receive cue point events from the TDSBMPlayer.
 */

@protocol TDSBMPlayerPlayerDelegate <NSObject>

/// @name Handling cue point events

/**
 * Called when there's a Cue Point available to be processed. A NSDictionary is passed containing the Cue Point metadata. All the available keys are defined in CuePointEvent.h.
 * See STWCue_Metadata_Dictionary.pdf for more details on the available cue point information.
 *
 * @param player The SBM player which is receiving cue point events
 * @param cuePointEvent A CuePointEvent object containing all cue point information.
 */

- (void) sbmPlayer:(TDSBMPlayer *) player didReceiveCuePointEvent:(CuePointEvent *) cuePointEvent;

/// @name Connection state

/**
 * Tells the delegate that the SBM player was unable to connect to the server.
 *
 * The SBM player tries to reconnect automatically three times. It will call this callback method after the third attempt fails.
 */

- (void) sbmPlayer:(TDSBMPlayer *) player didFailConnectingWithError:(NSError *) error;

@optional

/**
 * Called when the SBM player established a connection with the server and is ready to receive cue points.
 *
 * @param player The SBM player whose connection was opened.
 */

- (void) sbmPlayerDidOpenConnection:(TDSBMPlayer *) player;

@end

/**
 * Sideband Metadata (SBM) is a metadata transport mechanism offered to players that are unable to use metadata multiplexed into the stream itself (as with FLV, SHOUTcast V1/V2, etc.), either because it is impossible, difficult, or resource-intensive.
 * 
 * TDSBMPlayer handles the connection/play/stop flow and the reception of cue points using Triton's Side-Band Metadata technology. If also provides synchronization facilities with the user's audio player.
 * 
 * When using TDSBMPlayer, the developer is responsible of connecting and playing the main audio stream, this includes adding audience targeting parameters when connecting to the stream and also the responsibility of closing the SBM player when the main audio connection drops.
 * To a more high-level approach, use TritonPlayer, which handles automatically audience targetting and the metadata connection.
 */
@interface TDSBMPlayer : NSObject

/// @name Managing the delegate

/**
 * The delegate responsible for handling callbacks
 */

@property (weak, nonatomic) id<TDSBMPlayerPlayerDelegate> delegate;

/// @name Playback information

/**
 * The time in seconds from the beginning of playback
 */

@property (assign, readonly) NSTimeInterval currentPlaybackTime;

/// @name Stream synchronization

/**
 * Defines a difference in seconds between this SBMPlayer's currentPlaybackTime and the media player's current playback time (playhead position).
 * 
 * Cue points delivered by the TDSBMPlayer are synchronized with the side-band metadata current playback time by default. 
 * Depending on the time it takes to instantiate the application's media player and the companion TDSBMPlayer, there can be a time offset between both.
 */

@property (assign, nonatomic) NSTimeInterval synchronizationOffset;

/**
 * Whether or not to let TDSBMPlayer synchronize the cue points automatically with it's currentPlaybackTime and synchronizationOffset.
 *
 * If you need to have more fine-grained control over the synchronization, you can set it to NO and the cue points will arrive some seconds in advance and you will be able
 * to enqueue and dequeue them based on their [CuePointEvent timestamp] property. This is usually done with help of a timed event from the media player. 
 *
 * Default value is YES.
 */

@property (assign, nonatomic) BOOL autoSynchronizeCuePoints;

/// @name Utility methods

/**
 * Utility method for creating a new sbmid session id to be shared between the audio player and the TDSBMPlayer
 *
 * @return a NSString representing a Type 4 (i.e. random) UUID, formatted as a lowercase hex string, such as: fde807eb-6931-47db-a758-9c3b0c7e84d5
 */

+(NSString *)generateSBMSessionId;

/// @name Instantiating and configuring a player

/**
 * Initializes a TDSBMPlayer with settings.
 *
 * @param settings A NSDictionary containing the SBM settings. See constants in TDSBMPlayer.h for possible keys.
 */

-(instancetype)initWithSettings:(NSDictionary *)settings;

/**
 * Update the SBM player settings. All the information passed overrides the current settings and will take effect the next time the play method is called.
 *
 * @param settings A NSDictionary containing the SBM settings. See constants in TDSBMPlayer.h for possible keys.
 */

-(void)updateSettings:(NSDictionary *)settings;

/// @name Controlling the player

/**
 * Start playing the Side-band metadata player
 */

-(void)play;

/**
 * Stop playing the Side-band metadata player
 */

-(void)stop;

/**
 * Close the metadata connection.
 */

-(void)close;

@end
