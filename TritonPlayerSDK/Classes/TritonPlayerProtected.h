//
//  TritonPlayerProtected.h
//  FLVStreamPlayerLib64
//
//  Created by Carlos Pereira on 2014-03-19.
//
//

#ifndef FLVStreamPlayerLib64_StreamControllerProtected_h
#define FLVStreamPlayerLib64_StreamControllerProtected_h

@interface TritonPlayer(Protected)
- (void)setStreamHeader:(NSData *)headerData;
- (void)sendTagToDispatcher:(FLVTag *)inTag;
- (void)isExecutingNotificationReceived:(BOOL)value;
@end

#endif
