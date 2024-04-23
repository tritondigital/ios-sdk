# Changelog
#### TritonPlayerSDK-iOS-2.7.7 - 2024-04-23
- Make Companion Banner Clickable

#### TritonPlayerSDK-iOS-2.7.6 - 2024-01-09
- Implement Timeshift
- Change podcast speed

#### TritonPlayerSDK-iOS-2.7.5 - 2024-01-09
- Location manager update

#### TritonPlayerSDK-iOS-2.7.4 - 2023-12-07
- Multi-Listener ID

#### TritonPlayerSDK-iOS-2.7.3 - 2023-09-06
- Fix Companion ads not displaying

#### TritonPlayerSDK-iOS-2.7.2 - 2022-08-16
- Add DMP Segment headers
- Expose ad duration
- Implement add countdown display on interstitial ads

#### TritonPlayerSDK-iOS-2.7.1 - 2022-03-11
- Raise a "didReceiveAnalyticsEvent" to expose the AVPlayerItemAccessLogEvent.
- Re-generate secure token on stream reconnect.
- Parse the companion banner StaticResource element in the VAST response.
- Timeshift implementation (Alpha).
- Support for "other" gender added.
- Change the uuid parameter in the stream connection to lsid because uuid has been deprecated.
- Fix VAST Wrapper ads not displaying.

#### TritonPlayerSDK-iOS-2.6.7 - 2021-02-26
- Sync the SBM cuepoints to the stream.
- Open syncbanner link when the syncbanner is clicked.

#### TritonPlayerSDK-iOS-2.6.6 - 2020-10-26
- URLEncode VAST Impression url
- Start the stream with the volume button from a muted state

#### TritonPlayerSDK-iOS-2.6.5 - 2020-09-11
- Remove analytics tracker reference that broke the build.

#### TritonPlayerSDK-iOS-2.6.4 - 2020-07-23
- Fixed video impression tracking.
- VAST Wrapper support added.
- Cleanup unused observers.
- Added bundleId, storeId, and storeUrl on-demand parameters.
- Fixed TDPlayer memory leak when switching between stations.
- Fixed wrong selector called on WKWebView.

#### TritonPlayerSDK-iOS-2.6.3 - 2020-03-18
- Handle url alternate content when station is geo-blocked.
- Fix a deadlock when player is not a TDFLVPlayer.
- Fix Google ads error, by running on the mainRunloop.
- Fix close button that does not display on pre-roll ad.
- Stop when volume is muted.
- Replace UIWebView with WKWebView.
- Raise TDPlayerDeviceMuted error when stream is played and the phone is muted.
- Try all posibilities to get the correct banner.

#### TritonPlayerSDK-iOS-2.6.2 - 2019-11-20
- Replace MPMoviePlayerViewController with AVPlayerViewController

#### TritonPlayerSDK-iOS-2.6.0 - 2019-04-17
- First release of the open source Triton Mobile SDK for iOS
- Add the ability to set the distribution parameter
- Fix Low Delay feature when it is set to a value between 2 and 60

#### TritonPlayerSDK-iOS-2.5.1 - 2018-11-08
- Fix SettingsPlayerServicesRegion duplicate variable issue

#### TritonPlayerSDK-iOS-2.5.0 - 2018-02-16
 - New key in the Player settings to target a specific region: e.g: AP

### TritonPlayerSDK-iOS-2.4.3 - 2018-01-09
 - Fix secure token not well sent to Triton Digital servers
 - fix TTags params sent to Triton Digital servers


### TritonPlayerSDK-iOS-2.4.2 - 2017-12-13
 - Handle network errors/disconnection properly
 - Fix invalid secure token

### TritonPlayerSDK-iOS-2.4.1 - 2017-11-22
 - Fix Pause/Seek issue when playing an OnDemand stream.

### TritonPlayerSDK-iOS-2.4.0 - 2017-11-16
 - Support onMetaData Event in FLV.

### TritonPlayerSDK-iOS-2.3.12 - 2017-10-11
 - Fix the in-stream ads randomly crashing when playing HLS stream. HLS eventsource reconnections fixed.
 - Fix the player buffering info not forwarded 

### TritonPlayerSDK-iOS-2.3.11 - 2017-09-22
 - Remove the fix for the player buffering info not forwarded, added on 2.3.10

### TritonPlayerSDK-iOS-2.3.10 - 2017-09-21
 - Fix the player buffering info not forwarded 
 - Fix the ads banner view randomly crashing du to javascript rendering
 - Update api reference document for companion banner
 - Fix advertisement id not sent in the right format for in-stream ads
 - Update the sample app by displaying banners on the player ViewController 

### TritonPlayerSDK-iOS-2.3.9 - 2017-06-05
 - Fix pause issue when playing a podcast or an ondemand stream.

### TritonPlayerSDK-iOS-2.3.8 - 2017-06-01
 - Fix Player states when playing a podcast or an ondemand stream.

### TritonPlayerSDK-iOS-2.3.7 - 2017-05-30
 - Memory management improvement in the FLV Player

### TritonPlayerSDK-iOS-2.3.6 - 2017-05-16
 - Fix Multi-thread possible crashes on the stop

### TritonPlayerSDK-iOS-2.3.5 - 2017-05-12
 - Fix Memory leaks in the FLV Player

### TritonPlayerSDK-iOS-2.3.4 - 2017-05-10
 - Minor fixes when switching from HLS to FLV, issue introduced on version 2.3.3

### TritonPlayerSDK-iOS-2.3.3 - 2017-05-03
 - Refactor player: adding operation queue
 - Fix start-stop: synchronizing stop with debounced play

### TritonPlayerSDK-iOS-2.3.2 - 2017-04-26
 - Refactor Player State-machine
 - TDAdRequestURLBuilder: small fixes for extra parameters

### TritonPlayerSDK-iOS-2.3.1 - 2017-04-17
 - Prevent re-queuing metadata after being received (HLS)
 - Fix metadata delay on play (HLS)

### TritonPlayerSDK-iOS-2.3.0 - 2017-03-22
 - HTTPS support fixes
 - HLS streaming support fixes
 - add Debouncing support for the Play 
     
### TritonPlayerSDK-iOS-2.2.14 - 2017-01-11
 - HTTPS support 
     
### TritonPlayerSDK-iOS-2.2.11 - 2016-07-28
 - Pname support
 - Add banners and version as mandatory params 

### TritonPlayerSDK-iOS-2.2.7 - 2016-05-25
 - Low Delay support
 - TTag support
 - HtmlResource support in the VAST

### TritonPlayerSDK-iOS-2.1 - 2015-05-01
- Improvements for Advertising:
	- Possibility of loading a TDInterstitialAd directly from a TDAdRequestURLBuilder

- Improvements in Triton Player
	- Added TDCuePointHistory class for receiving cue point history from the now playing history service.
	- Support for playing external on-demand streams (ads, podcasts) through Triton Player
	- Standalone player (TDSBMPlayer) for receiving stream metadata using Triton’s Side-band metadata technology 
	- Changed how state change and informations callbacks are handled by the player

### TritonPlayerSDK-iOS-2.0.0 - 2015-02-25
- Improvements for Advertising:
	- Created TDAdLoader to allow loading Triton ads and displaying it with custom UI
	- Created TDSyncBannerView to play a sync banner ad directly from a cue point
- Improvements in the player connection provisioning
	- Support for playing an alternative mount when the current mount is geoblocked
	- player:wasGeoBlocked callback is deprecated. player:didFailConnectingWithError has geoblocking information
	- Improvements in the reconnection when a error occurs 

### TritonPlayerSDK-iOS-1.1.0 - 2015-01-27
- Included Advertising functionality (companion banners, interstitials)

### TritonPlayerSDK-iOS-1.0.4 - 2014-12-08
- Fixed a bug that was making the library crash when a cue point is not properly decoded

### TritonPlayerSDK-iOS-1.0.3 - 2014-11-24
- Requesting “When in use permission” for CLLocation manager when location tracking is enabled
- Stream stops when headset is unplugged
- Added shouldResumePlaybackAfterInterruption property to TritonPlayer
- Re-included armv7s as a supported architecture 
- Eliminated the need to use -all_load to load some categories
- Minor improvements

### TritonPlayerSDK-iOS-1.0.2 - 2014-10-30
- Removed dependencies that were causing problems when compiling to 64-bit 
- Minor improvements

### TritonPlayerSDK-iOS-1.0.1 - 2014-10-08
- Rebuilt library with iOS 8 SDK 
- Minor improvements


### TritonPlayerSDK-iOS-0.2.1 - 2014-06-10
- Added TritonPlayerDelegate methods:
	- mute
	- unmute
	- setVolume

### TritonPlayerSDK-iOS-0.2.0 - 2014-05-07
- Changed TritonPlayerDelegate methods:
	- Standardized signatures with the player as a parameter
	- Error objects as parameters for error callbacks
	- Included callback support for handling phone interruptions
- Fixed a bug which was preventing geo blocking notifications from being triggered
- Added legacy AndoXML cue point format support
- Included a simple VAST parser in the sample application for parsing companion banners ads
- Minor improvements in the sample application

### TritonPlayerSDK-iOS-0.1.0 - 2014-05-02
- First version
