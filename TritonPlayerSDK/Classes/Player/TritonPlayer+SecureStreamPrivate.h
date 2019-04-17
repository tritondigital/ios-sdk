#import "TritonPlayer.h"
#import "SecureStruct.h"

@interface TritonPlayer (SecureStreamPrivate)

- (NSString*)processChallengeWithCode:(NSString*)codeString andChallenge:(NSString*)challengeString;

@end
