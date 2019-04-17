//
//  TDCuePointHistoryParser.h
//  TritonPlayerSDK
//
//  Created by Carlos Pereira on 2015-04-06.
//  Copyright (c) 2015 Triton Digital. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TDCuePointHistory.h"

@interface TDCuePointHistoryParser : NSObject

-(void)requestHistoryForURL:(NSURL*)url
            completionBlock:(void (^)(NSArray* historyList, NSError *error)) completionBlock;
@end
