//
//  CuePointEventProtected.h
//  FLVStreamPlayerLib64
//
//  Created by Carlos Pereira on 2014-04-21.
//
//

#ifndef FLVStreamPlayerLib64_CuePointEventProtected_h
#define FLVStreamPlayerLib64_CuePointEventProtected_h

// Used when creating a CuePoint manually
extern NSString *const CommonCueDataKey;

@interface CuePointEvent (Protected)

@property (nonatomic, assign) BOOL executionCanceled;

- (instancetype) initWithDictionary:(NSDictionary *) dictionary;
- (void)startTimer;
- (void)setCuePointEventController:(CuePointEventController *)cuePointEventController;
- (void)hasBeenExecuted;
@end

#endif
