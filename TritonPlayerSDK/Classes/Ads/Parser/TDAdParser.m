//
//  TDAdarser.m
//  TritonPlayerSDK
//
//  Created by Carlos Pereira on 2014-12-01.
//  Copyright (c) 2014 Triton Digital. All rights reserved.
//

#import "TDAdParser.h"
#import "TDAd.h"
#import "TDBannerView.h"
#import "TDCompanionBanner.h"
#import "TDAdUtils.h"
#import "TritonSDKUtils.h"

typedef NS_ENUM(NSInteger, CreativeType) {
    kCreativeTypeUnknown,
    kCreativeTypeCompanion,
    kCreativeTypeLinear
};



@interface TDAdParser ()<NSXMLParserDelegate>

@property (nonatomic, strong) TDAd *parsedAd;

@property (nonatomic, strong) NSString *currentElement;
@property (nonatomic, strong) NSMutableString *stringBuffer;
@property (nonatomic, assign) CreativeType currentCreativeType;

@property (nonatomic, strong) NSMutableArray *clickTrackingUrls;
@property (nonatomic, strong) NSMutableArray *mediaImpressionUrls;

@property (nonatomic, strong) NSMutableArray *companionBanners;
@property (nonatomic, strong) TDCompanionBanner *currentBanner;


@property (nonatomic, strong) NSString *adFormat;
@end

@implementation TDAdParser

-(instancetype)init {
    self = [super init];
    if (self) {
        self.stringBuffer = [[NSMutableString alloc] init];
    }
    return self;
}

-(void)parseFromRequestString:(NSString*)string completionBlock:(void (^)(TDAd* ad, NSError *error)) completionBlock {
    if (string) {
        
        // Store callback block so other methods can call it
        self.callbackBlock = completionBlock;

        NSURL *url = [NSURL URLWithString:string];
        if (url) {
            if ([url.scheme isEqual:@"https"] || [url.scheme isEqual:@"file"]) {
            // if url, donwload it and send to parser
                [self downloadDataFromURL:url withCompletionHandler:^(NSData *data, NSError *error) {
                
                    if (error) {
                        completionBlock(nil, error);
                        return;
                    }
                
                    [self startParserWithData:data];
                }];
            } else {
                self.callbackBlock(nil, [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"The url is invalid or is not secured.", nil) }]);
                return;
            }
        } else {
            // If inline, create data and send to parser
            NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
            
            [self startParserWithData:data];
        }
        
    }
}

-(void)startParserWithData:(NSData*) data {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSData *kdata;
        NSString *news = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        news = [news stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        kdata = [news dataUsingEncoding:NSUTF8StringEncoding];
        
        NSXMLParser *parser = [[NSXMLParser alloc] initWithData:kdata];
        parser.delegate = self;
        [parser setShouldProcessNamespaces:NO];
        [parser setShouldReportNamespacePrefixes:NO];
        [parser setShouldResolveExternalEntities:NO];
        
        if ([parser parse]) {
            self.callbackBlock(self.parsedAd, nil);
            
        }
        else
        {
            NSLog(@"Failed Vast Data: %@", [[NSString alloc] initWithData:kdata encoding:NSUTF8StringEncoding]);
            self.callbackBlock(nil, [TDAdUtils errorWithCode:105 andDescription:@"Failed to parse response"]);
        }
    });
}


-(void)downloadDataFromURL:(NSURL *)url withCompletionHandler:(void (^)(NSData *data, NSError *error))completionHandler{
		
		[TritonSDKUtils downloadDataFromURL:url withCompletionHandler:completionHandler ];
		
}

#pragma mark - NSXMLParserDelegate

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    
    if(([elementName caseInsensitiveCompare:@"Vast"]== NSOrderedSame) || ([elementName caseInsensitiveCompare:@"Daast"]== NSOrderedSame) )
    {
        self.adFormat = elementName;
    }
    
    if ([elementName isEqualToString:@"Ad"]) {
        self.parsedAd = [[TDAd alloc] init];
    
    } else if ([elementName isEqualToString:@"Error"]) {
        self.parsedAd = [[TDAd alloc] init];
    } else if ([elementName isEqualToString:@"CompanionAds"]) {
        self.companionBanners = [NSMutableArray array];
        
    } else if ([elementName isEqualToString:@"Companion"]) {
        self.currentCreativeType = kCreativeTypeCompanion;
        
        self.currentBanner = [[TDCompanionBanner alloc] init];
        self.currentBanner.width = [[attributeDict objectForKey:@"width"] integerValue];
        self.currentBanner.height = [[attributeDict objectForKey:@"height"] integerValue];
        
    } else if ([elementName isEqualToString:@"Linear"]) {
        self.currentCreativeType = kCreativeTypeLinear;
    
    } else if ([elementName isEqualToString:@"MediaFile"] && self.parsedAd.mediaURL == nil) {
        NSString *type = attributeDict[@"type"];
        
        if ([type hasPrefix:@"video"]) {
            int width = [attributeDict[@"width"] intValue];
            int height = [attributeDict[@"height"] intValue];
            self.parsedAd.videoWidth = width;
            self.parsedAd.videoHeight = height;
            
        }
        
        self.parsedAd.mediaMIMEType = type;
    
    } else if ([elementName isEqualToString:@"ClickTracking"]) {
        if (!self.clickTrackingUrls) {
            self.clickTrackingUrls = [[NSMutableArray alloc] init];
        }
    } else if ([elementName isEqualToString:@"Impression"]) {
        if (!self.mediaImpressionUrls) {
            self.mediaImpressionUrls = [[NSMutableArray alloc] init];
        }
    }
    
    self.currentElement = elementName;
}

-(void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    
    // Add the current companion banner to the banners list
    if ([elementName isEqualToString:@"Companion"]) {
        
        if (self.currentBanner.contentURL || self.currentBanner.contentHTML ) {
            [self.companionBanners addObject:self.currentBanner];
        }
        self.currentBanner = nil;
        
        self.currentCreativeType = kCreativeTypeUnknown;
        
    } else if ([elementName isEqualToString:@"IFrameResource"]) {
        
        // If the IFrameResource is from a companion banner set the url
        if (self.currentCreativeType == kCreativeTypeCompanion) {
            NSURL *url = [NSURL URLWithString:[self.stringBuffer stringByReplacingOccurrencesOfString:@"fmt=iframe" withString:@"fmt=htmlpage"]];
            self.currentBanner.contentURL = url;
        }
    } else if ([elementName isEqualToString:@"HTMLResource"]) {
        
        // If the HTMLResource is from a companion banner set the html
        if (self.currentCreativeType == kCreativeTypeCompanion) {
            self.currentBanner.contentHTML = [self.stringBuffer copy];
        }
    } else if ([elementName isEqualToString:@"MediaFile"] && self.parsedAd.mediaURL == nil) {
        if ([self.stringBuffer rangeOfString:@"https"].location == NSNotFound) {
            [self.stringBuffer stringByReplacingOccurrencesOfString:@"http" withString:@"https"];
       }
        self.parsedAd.mediaURL = [NSURL URLWithString:self.stringBuffer];
    
    } else if ([elementName isEqualToString:@"ClickThrough"]) {
        self.parsedAd.videoClickThroughURL = [NSURL URLWithString:self.stringBuffer];
        
    } else if ([elementName isEqualToString:@"Impression"]) {
        [self.mediaImpressionUrls addObject:[NSURL URLWithString:[self.stringBuffer stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]]];
    
    } else if ([elementName isEqualToString:@"ClickTracking"]) {
        [self.clickTrackingUrls addObject:[NSURL URLWithString:self.stringBuffer]];
    
    } else if ([elementName isEqualToString:@"VideoClicks"] || [elementName isEqualToString:@"AudioInteractions"]) {
        self.parsedAd.clickTrackingURLs = self.clickTrackingUrls;
    
    } else if ([elementName isEqualToString:@"CompanionAds"]) {
        self.parsedAd.companionBanners = self.companionBanners;
        self.companionBanners = nil;
    }
    else if ([elementName isEqualToString:@"VASTAdTagURI"]) {
        self.parsedAd.vastAdTagUri = [NSURL URLWithString:self.stringBuffer];
    } else if ([elementName isEqualToString:@"Error"]){
        [self.stringBuffer replaceOccurrencesOfString:@"[TD_DURATION]" withString:@"0" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [self.stringBuffer length])];
        [self.stringBuffer replaceOccurrencesOfString:@"[ERRORCODE]" withString:@"202" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [self.stringBuffer length])];
        
        self.parsedAd.errorUrl = [NSURL URLWithString:self.stringBuffer];
    }
    
    [self.stringBuffer setString:@""];
}

-(void)parser:(NSXMLParser *)parser foundCDATA:(NSData *)CDATABlock {
    
    if ([self.currentElement isEqualToString:@"IFrameResource"] ||
        [self.currentElement isEqualToString:@"HTMLResource"] ||
        [self.currentElement isEqualToString:@"MediaFile"] ||
        [self.currentElement isEqualToString:@"ClickThrough"] ||
        [self.currentElement isEqualToString:@"Impression"] ||
        [self.currentElement isEqualToString:@"ClickTracking"] ||
        [self.currentElement isEqualToString:@"VASTAdTagURI"] ||
        [self.currentElement isEqualToString:@"Error"]) {

        
        NSString *cdataString = [[NSString alloc] initWithData:CDATABlock encoding:NSUTF8StringEncoding];
        [self.stringBuffer appendString:[cdataString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
    }
}

-(void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    
    if ([self.currentElement isEqualToString:@"IFrameResource"] ||
        [self.currentElement isEqualToString:@"HTMLResource"] ||
        [self.currentElement isEqualToString:@"MediaFile"] ||
        [self.currentElement isEqualToString:@"ClickThrough"] ||
        [self.currentElement isEqualToString:@"Impression"] ||
        [self.currentElement isEqualToString:@"ClickTracking"] ||
        [self.currentElement isEqualToString:@"VASTAdTagURI"]) {
        
        [self.stringBuffer appendString:[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
    }
}

-(void)parserDidEndDocument:(NSXMLParser *)parser {
    self.parsedAd.mediaImpressionURLs = self.mediaImpressionUrls;
    self.parsedAd.format  =self.adFormat;
}

-(void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    // If it was canceled by the delegate, it means we already found the information we need.
    if (parseError.code == NSXMLParserDelegateAbortedParseError) {
        self.callbackBlock(self.parsedAd, nil);
    
    } else {
        NSLog(@"Parser : %ld %ld", (long)parser.lineNumber, (long)parser.columnNumber);
        self.callbackBlock(nil, parseError);
    
    }
}



@end
