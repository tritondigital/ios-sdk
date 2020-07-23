//
//  TritonSDKUtils.m
//  TritonPlayerSDK
//
//  Created by Carlos Pereira on 2015-04-06.
//  Copyright (c) 2015 Triton Digital. All rights reserved.
//

#import "TritonSDKUtils.h"

#define kXMLDownloadRequestTimeout 30.0f
#define kXMLDownloadResourceTimeout 60.0f

@implementation TritonSDKUtils

#pragma mark - Data downloading

+(void)downloadDataFromURL:(NSURL *)url withCompletionHandler:(void (^)(NSData *data, NSError *error))completionHandler {
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.timeoutIntervalForRequest = kXMLDownloadRequestTimeout;
    configuration.timeoutIntervalForResource = kXMLDownloadResourceTimeout;
    
    // Enable this for testing. Otherwise it won't download the VAST/DAAST file again
    configuration.HTTPCookieStorage = nil;
    configuration.URLCache = nil;
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    
     // Create a data task object to perform the data downloading.
    NSURLSessionDataTask *task = [session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (error != nil) {
            // If any error occurs, call the completion handler with the error.
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                completionHandler(nil, error);
            }];
        }
        else{
            // If no error occurs, check the HTTP status code.
            if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSInteger HTTPStatusCode = [(NSHTTPURLResponse *)response statusCode];
            NSError *networkError = nil;
            
            // If it's other than 200, then show it on the console.
            if (HTTPStatusCode != 200) {
                networkError = [NSError errorWithDomain:NSURLErrorDomain code:HTTPStatusCode userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"The server returned an invalid response.", nil) }];
            }
            
            // Call the completion handler with the returned data on the main thread.
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                completionHandler(data, networkError);
            }];
            } else{
                 [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                       completionHandler(data, nil);
                   }];            }
        }
    }];
    
    // Resume the task.
    [task resume];
}

@end
