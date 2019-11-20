//
//  TDAdLoader.m
//  TritonPlayerSDK
//
//  Created by Carlos Pereira on 2015-02-18.
//  Copyright (c) 2015 Triton Digital. All rights reserved.
//

#import "TDAdLoader.h"
#import "TDAdParser.h"
#import "TDAdRequestURLBuilder.h"
#import "TDAdUtils.h"

NSString *const TDErrorDomain = @"com.tritondigital.TritonMobileSDK";

@implementation TDAdLoader

-(void)loadAdWithStringRequest:(NSString *)request
      completionHandler:(void (^)(TDAd *, NSError *))completionHandler {
    
    if (request) {
        TDAdParser *parser = [[TDAdParser alloc] init];
        [parser parseFromRequestString:request completionBlock:^(TDAd *ad, NSError *error) {
            
            if (error) {
                NSError *userError;
                
                // Network error
                if ([error.domain isEqualToString:NSURLErrorDomain]) {
                    userError = [TDAdUtils errorWithCode:TDErrorCodeInvalidRequest andDescription:@"The request failed due to a network error." andUnderlyingError:error];
                    
                } else {
                    // Parser error
                    userError = [TDAdUtils errorWithCode:TDErrorCodeResponseParsingFailed andDescription:@"Unable to parse the response." andUnderlyingError:error];
                }
                
                completionHandler(nil, userError);
                return;
            }
            
            if (!ad) {
                completionHandler(nil, [TDAdUtils errorWithCode:TDErrorCodeNoInventory andDescription:@"No ad to display"]);
                return;
            }
            
            // Successfully loaded ad
            completionHandler(ad, nil);
        }];
    } else {
        completionHandler(nil, [TDAdUtils errorWithCode:TDErrorCodeInvalidAdURL andDescription:@"The ad request URL is invalid."]);
    }
}

-(void)loadAdWithBuilder:(TDAdRequestURLBuilder *)builder
       completionHandler:(void (^)(TDAd *, NSError *))completionHandler {
    [self loadAdWithStringRequest:[builder generateAdRequestURL] completionHandler:completionHandler];
}

@end
