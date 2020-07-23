//
//  TDAdRequestURLBuilder.h
//  TritonPlayerSDK
//
//  Copyright (c) 2014 Triton Digital. All rights reserved.
//

#import <Foundation/Foundation.h>

/// The different gender parameters that can be used for targeting
typedef NS_ENUM(NSInteger, TDGender) {
    /// The gender was not specified
    kTDGenderNotDefined,
    
    /// Gender is female
    kTDGenderFemale,
    
    /// Gender is male
    kTDGenderMale
};

/// The type of on-demand ad
typedef NS_ENUM(NSInteger, TDAdType) {
    /// Pre-roll ads. These are intended to be played before playback starts.
    kTDAdTypePreroll,
    
    /// Mid-roll ads. These are intended to be played during the session, between content elements such as songs.
    kTDAdTypeMidroll
};

/// The type of asset for the linear ad (The main media in the interstitial)
typedef NS_ENUM(NSInteger, TDAssetType) {
    
    /// There's no restriction in the type of asset returned for the ads.
    kTDAssetTypeNotDefined,
    
    /// Ads must be of type audio.
    kTDAssetTypeAudio,
    
    /// Ads must be of type video.
    kTDAssetTypeVideo,
    
    /// Ads must be of type audio or video
    kTDAssetTypeAudioVideo
};

/**
 * TDAdRequestURLBuilder helps to build ad requests for Triton's on-demand banners and interstitials (pre-roll, mid-roll), including targeting parameters and device capabilities specified in Triton's On-Demand Advertising Guide. 
 *
 * It also includes the user's IDFA (Id for Advertisers), when available, and can also incluse the user's GPS location to better target the ads. The url's generated or TDAdRequestURLBuilder itself can be passed directly to TDAdLoader.
 */
@interface TDAdRequestURLBuilder : NSObject

/// @name Creating a TDAdRequestURLBuilder

/**
 * Creates and initializes a request url builder.
 *
 * @param url the base url for the request url builder (the ad server url)
 * @return an instance of the request url builder
 */

+(instancetype)builderWithHostURL:(NSString *) url;

/**
 * Initializes a newly allocated a request url builder
 *
 * @param url the base url for the request url builder (the ad server url)
 * @return an instance of the request url builder
 */

-(instancetype)initWithHostURL:(NSString *) url;

/// @name Defining the ad type

/**
 * Defines the type of ad requested (preroll, midroll). The default value is preroll. There's no need to be defined for banner ads, just for interstitials.
 */

@property (nonatomic, assign) TDAdType adType;

/// @name Required parameters

/**
 * Either the Station ID or station name must be specified when calling the On-Demand Ad Request Service. While both IDs and names are supported, it is strongly recommended that clients use station names.
 * 
 * If both ID and name are provided, the name is used (there is no validation check that the ID matches the name). Triton Digital assigns station IDs and names when setting up a station.
 */

@property (nonatomic, assign) NSInteger stationId;

/**
 * Station names are case-sensitive. See stationId.
 */

@property (nonatomic, copy) NSString *stationName;

/// @name Location targeting

/**
 The postal/zip code of the listener. Must be a valid postal or zip code, without spaces. E.g., 89040 or H3G1R8.
 When using this property, it's recommended to also use country.
 */
@property (nonatomic, copy) NSString *postalCode;

/**
 The ISO 3166-1 alpha-2 two-letter country code (e.g., US). If using this property, it's recommended to also use postalCode.
 */
@property (nonatomic, copy) NSString *country;

/**
 The latitude and longitude of the listener obtained from CoreLocation or other source.
 
 @param latitude float value between -90.0 and 90.0.
 @param longitude float value between -180.0 and 180.0
 */
-(void)setLocationWithLatitude:(float) latitude andLongitude:(float) longitude;
/**
 The latitude of the listener obtained from CoreLocation or other source.
 Floating-point value: -90.0 to 90.0. Not required individually. If using, you must also specify longitude.
*/
@property (nonatomic, assign) float latitude;
/**
 The longitude of the listener obtained from CoreLocation or other source.
 Floating-point value: -180.0 to 180.0. Not required individually. If using, you must also specify latitude.
*/
@property (nonatomic, assign) float longitude;

/**
 Whether to use built-in Core Location manager to handle location. Default value is NO.
 When enabled it will override values obtained from setLocationWithLatitude:andLongitude
 */
@property (nonatomic, getter=isAutoLocationTrackingEnabled) BOOL autoLocationTrackingEnabled;

/// @name Demographic targeting

/**
 Integer value: 1 to 125
 */
@property (nonatomic, assign) NSInteger age;
/**
 The date of birth as an NSDate
 */
@property (nonatomic, copy) NSDate *dateOfBirth;
/**
 Set the date of birth as a string formatted as YYYY-MM-DD
 
 @param dateOfBirth the formatted string
 */
-(void)setDateOfBirthFromString:(NSString *)dateOfBirth;
/**
 Integer value: 1900 to 2005
 */
@property (nonatomic, assign) NSInteger yearOfBirth;
/**
 Possible values are kTDGenderFemale and kTDGenderMale
 */
@property (nonatomic, assign) TDGender gender;
/**
 Application package name e.g  com.tritondigital.tritonradio
 */
@property (nonatomic, assign) NSString *bundleId;
/**
 App Store identifier
 */
@property (nonatomic, assign) NSString *storeId;
/**
 App store url
 */
@property (nonatomic, assign) NSString *storeUrl;

/// @name Banner capabilities

/**
 * A string with a list of comma-separated banner sizes
 *
 * Players can provide details on their level of support for banners, such
 * as banner sizes and formats.
 *
 * The ordering of the capability formats is not important.
 *
 * @note Before attempting to use player capability targeting, please contact
 * the Triton Digital Support Team to enable Player Capability Targeting for
 * your broadcaster. Currently, Player Capability Targeting only works with
 * Tap advertising.
 *
 * Supported Formats
 *
 * <table>
 *      <tr><th>Capability</th><th>Description</th></tr>
 *      <tr><td>970x250</td>   <td>IAB Billboard (970x250)</td></tr>
 *      <tr><td>120x60</td>    <td>IAB Button 2 (120x60)</td></tr>
 *      <tr><td>300x600</td>   <td>IAB Half Page/Filmstrip (300x600)</td></tr>
 *      <tr><td>728x90</td>    <td>IAB Leaderboard (728x90)</td></tr>
 *      <tr><td>970x100</td>   <td>IAB Leaderboard (970x100)</td></tr>
 *      <tr><td>300x250</td>   <td>IAB Medium Rectangle (300x250)</td></tr>
 *      <tr><td>88x31</td>     <td>IAB Microbar (88x31)</td></tr>
 *      <tr><td>300x1050</td>  <td>IAB Portrait (300x1050)</td></tr>
 *      <tr><td>970x90</td>    <td>IAB Pushdown (970x90)</td></tr>
 *      <tr><td>180x150</td>   <td>IAB Rectangle (180x150)</td></tr>
 *      <tr><td>320x480</td>   <td>IAB Smartphone Portrait (320x480)</td></tr>
 *      <tr><td>300x50</td>    <td>IAB Smartphone Static Banner (300x50)</td></tr>
 *      <tr><td>320x50</td>    <td>IAB Smartphone Static Wide Banner (320x50)</td></tr>
 *      <tr><td>300x300</td>   <td>IAB Square (300x300)</td></tr>
 *      <tr><td>970x66</td>    <td>IAB Super Leaderboard (970x66)</td></tr>
 *      <tr><td>160x600</td>   <td>IAB Wide Skyscraper (160x600)</td></tr>
 *      <tr><td>Client-defined (w x h)</td><td>Custom banner size</td></tr>
 * </table>
 */
@property (nonatomic, copy) NSString *banners;

/**
 Integer value: 1 to 1000000
 
 Broadcasters that want to differentiate their listeners into custom
 broadcaster-specific segments may use the Custom Segment Targeting
 capability of Tap.
 
 @note Before use by players, please contact the Triton Digital Support
 Team to enable Custom Segment ID Targeting for your broadcaster.
 Currently, Custom Segment ID Targeting only works with Tap advertising.
*/
@property (nonatomic, assign) NSInteger customSegmentId;

/// @name Asset constraints

/**
 Change this if you would like to impose constraints on the type of asset returned. Possible values are:
 kTDAssetTypeNotDefined, kTDAssetTypeAudio, kTDAssetTypeVideo and kTDAssetTypeAudioVideo.
 */
@property (nonatomic, assign) TDAssetType    assetType;

/**
 All the parameters non supported by properties can be passed by key/value pair.
 Situations in which you would use this property:
 - When defining Asset Constraints (Section 3.3.5 of Triton's On-Demand Advertising guide);
 - Custom parameters
 - New supported targeting parameters without a corresponding propery. 
 - Standard parameters can also be passed using this dictionary and they will override the values set by each property or setter method.
 */
@property (nonatomic, copy)   NSDictionary *extraParameters;

/**
 An Array of NSString
 - When defining Custom TTag Targeting
*/
@property (nonatomic, copy)   NSArray *TTags;

/// @name Generating the Ad request URL

/**
 Build and return a string containing the ad request URL for on-demand ads.
 
 @return NSString containing the ad request. It will return nil if host is not specified and if both station name and station id are not specified.
 */
-(NSString*)generateAdRequestURL;

/**
 Resets the TDAdRequestURLBuiler to its default values and keeps the host url. You can use this to reuse the same object for different requests to the same host. 
 */
-(void)reset;
@end
