
#import <UIKit/UIKit.h>
#import <TritonPlayerSDK/TritonPlayerSDK.h>

typedef void(^ControlFiredBlock)(UIButton *sender);

typedef NS_ENUM(NSInteger, EmbeddedPlayerState) {
		kEmbeddedStateConnecting,
		kEmbeddedStatePlaying,
		kEmbeddedStateStopped,
		kEmbeddedStateError
};

typedef NS_ENUM(NSInteger, EmbeddedTransportMethod) {
		kEmbeddedTransportMethodFLV,
		kEmbeddedTransportMethodHLS,
		kEmbeddedTransportMethodOther
};

@interface MultiStationViewController : UIViewController
{
		NSString*    playingStation;
		NSDictionary            *configDictionary;
		NSArray *   loadedStationsArray;
		NSArray*    stationList; //default
}

@property (strong, nonatomic)  NSArray*    stationFLVList;
@property (strong, nonatomic)  NSArray*    stationHLSList;
@property (nonatomic, strong)  NSArray *   loadedStationsArray;
@property (nonatomic, strong)  NSDictionary* configDictionary;
@property (nonatomic, strong)  NSString*    playingStation;

@property (copy, nonatomic) ControlFiredBlock playFiredBlock;
@property (copy, nonatomic) ControlFiredBlock stopFiredBlock;

@property (assign, nonatomic) EmbeddedPlayerState playerState;

@property (assign, nonatomic) EmbeddedTransportMethod transport;

// Displayed when the player is kEmbeddedStateError state
@property (copy, nonatomic) NSError *error;

- (void)loadCuePoint:(CuePointEvent*)cuePoint;
@end
