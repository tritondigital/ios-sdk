//
//  TritonSDKUtils.h
//  TritonPlayerSDK
//
//  Created by Carlos Pereira on 2015-04-06.
//  Copyright (c) 2015 Triton Digital. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TritonSDKUtils : NSObject

+(void)downloadDataFromURL:(NSURL *)url withCompletionHandler:(void (^)(NSData *data, NSError *error))completionHandler;

+(NSString *)getRequestFromURL:(NSURL *)url;
@end
