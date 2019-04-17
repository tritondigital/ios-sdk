//
//  TDAdUtils.h
//  TritonPlayerSDK
//
//  Created by Carlos Pereira on 2015-01-21.
//  Copyright (c) 2015 Triton Digital. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TDAdUtils : NSObject

+(void)trackUrlAsync:(NSURL *)url;

+(NSError*) errorWithCode:(NSInteger)code
           andDescription:(NSString*)description
         andFailureReason:(NSString*)reason
    andRecoverySuggestion:(NSString*)recovery
       andUnderlyingError:(NSError*)error;

+(NSError*) errorWithCode:(NSInteger)code
           andDescription:(NSString*)description;

+(NSError*) errorWithCode:(NSInteger)code
           andDescription:(NSString*)description
       andUnderlyingError:(NSError*)error;
@end
