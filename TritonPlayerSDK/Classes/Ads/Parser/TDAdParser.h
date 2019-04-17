//
//  TDAdParser.h
//  TritonPlayerSDK
//
//  Created by Carlos Pereira on 2014-12-01.
//  Copyright (c) 2014 Triton Digital. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TritonSDKUtils.h"

@class TDAd;

@interface TDAdParser : NSObject
typedef void(^CallbackBlock)(TDAd *ad, NSError *error);

@property (nonatomic, copy) CallbackBlock callbackBlock;

-(instancetype)init;

-(void)parseFromRequestString:(NSString*)string completionBlock:(void (^)(TDAd* ad, NSError *error)) completionBlock;
-(void)startParserWithData:(NSData*) data;
-(void)downloadDataFromURL:(NSURL *)url withCompletionHandler:(void (^)(NSData *data, NSError *error))completionHandler;

@end
