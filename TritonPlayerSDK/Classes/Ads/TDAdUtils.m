//
//  TDAdUtils.m
//  TritonPlayerSDK
//
//  Created by Carlos Pereira on 2015-01-21.
//  Copyright (c) 2015 Triton Digital. All rights reserved.
//

#import "TDAdUtils.h"
#import "TDAdLoader.h"

@implementation TDAdUtils

+ (void)trackUrlAsync:(NSURL *) url {
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:url] queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        // Do nothing for the moment. It's just a get on the server to track the urls
    }];
}

+(NSError*) errorWithCode:(NSInteger) code
           andDescription:(NSString*) description
         andFailureReason:(NSString*) reason
    andRecoverySuggestion:(NSString*) recovery
       andUnderlyingError:(NSError*)   error {
    
    NSDictionary *userInfo = @{
                               NSLocalizedDescriptionKey : NSLocalizedString(description, nil),
                               NSLocalizedFailureReasonErrorKey : NSLocalizedString(reason, nil),
                               NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(recovery, nil),
                               NSUnderlyingErrorKey : error
                               };
    return [NSError errorWithDomain:TDErrorDomain code:code userInfo:userInfo];
}

+(NSError*) errorWithCode:(NSInteger) code
           andDescription:(NSString*) description {
    
    return [NSError errorWithDomain:TDErrorDomain code:code userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(description, nil) }];
}

+(NSError*) errorWithCode:(NSInteger) code
           andDescription:(NSString*) description
       andUnderlyingError:(NSError*) error {
    
    NSDictionary *userInfo = @{
                               NSLocalizedDescriptionKey : NSLocalizedString(description, nil),
                               NSUnderlyingErrorKey : error
                               };
    return [NSError errorWithDomain:TDErrorDomain code:code userInfo:userInfo];
}

@end
