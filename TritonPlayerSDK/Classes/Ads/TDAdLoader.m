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
#import "TDAd.h"
#import "TritonSDKUtils.h"

NSString *const TDErrorDomain = @"com.tritondigital.TritonMobileSDK";
NSInteger noRequest = 0;
NSMutableArray *mediaImpressionUrls = nil;

@implementation TDAdLoader

-(void)loadAdWithStringRequest:(NSString *)request
      completionHandler:(void (^)(TDAd *, NSError *))completionHandler {
    [self loadAdWithStringRequest:request andDmpSegments:nil completionHandler:completionHandler];
}

-(void)loadAdWithStringRequest:(NSString *)request andDmpSegments:(NSDictionary *)dmpSegments
      completionHandler:(void (^)(TDAd *, NSError *))completionHandler {
    
    if (request) {
        TDAdParser *parser = [[TDAdParser alloc] init];
        
        if(dmpSegments){
            NSError *error;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dmpSegments options:0 error:&error];
            parser.dmpSegmentsJson = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
        
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
            
            if(ad.errorUrl && !ad.mediaURL && !ad.vastAdTagUri && !ad.companionBanners){
                completionHandler(nil, [TDAdUtils errorWithCode:TDErrorCodeNoInventory andDescription:@"No ad to display"]);
                [TritonSDKUtils getRequestFromURL:ad.errorUrl];
                return;
            }
            
             if(mediaImpressionUrls == nil) {
                 mediaImpressionUrls = [[NSMutableArray alloc] init];
             }
            
            if(ad.mediaImpressionURLs != nil) {
                [mediaImpressionUrls addObjectsFromArray:ad.mediaImpressionURLs];
            }
            
            if(![self isVastWrapper:ad completionHandler:completionHandler])
            {
            // Successfully loaded ad
                ad.mediaImpressionURLs = mediaImpressionUrls;
            completionHandler(ad, nil);
                noRequest = 0;
                mediaImpressionUrls = nil;
            }
            
           
        }];
    } else {
        completionHandler(nil, [TDAdUtils errorWithCode:TDErrorCodeInvalidAdURL andDescription:@"The ad request URL is invalid."]);
    }
    
}

-(void)loadAdWithBuilder:(TDAdRequestURLBuilder *)builder
       completionHandler:(void (^)(TDAd *, NSError *))completionHandler {
    if(builder.dmpSegments && builder.dmpSegments.count > 0){
        [self loadAdWithStringRequest:[builder generateAdRequestURL] andDmpSegments:builder.dmpSegments completionHandler:completionHandler];
    }else{
    [self loadAdWithStringRequest:[builder generateAdRequestURL] completionHandler:completionHandler];
    }
    
}

-(BOOL)isVastWrapper:(TDAd *)ad
completionHandler:(void (^)(TDAd *, NSError *))completionHandler {
    noRequest++;
    
    if(ad.vastAdTagUri != nil && noRequest <= 5) {
        [self loadAdWithStringRequest:ad.vastAdTagUri.absoluteString completionHandler:completionHandler];
        return true;
    }
    return false;    
}

@end
