//
//  TDCuePointHistoryParser.m
//  TritonPlayerSDK
//
//  Created by Carlos Pereira on 2015-04-06.
//  Copyright (c) 2015 Triton Digital. All rights reserved.
//

#import "TDCuePointHistoryParser.h"
#import "TDCuePointHistory.h"
#import "TritonSDKUtils.h"
#import "CuePointEvent.h"

typedef void(^CallbackBlock)(NSArray* historyList, NSError *error);

@interface TDCuePointHistoryParser ()<NSXMLParserDelegate>

// The block used to pass back parsed data
@property (nonatomic, copy) CallbackBlock callbackBlock;

// List containing all the cue points already parsed
@property (nonatomic, strong) NSMutableArray *parsedItems;

// The current cue point being parsed
@property (nonatomic, strong) NSMutableDictionary *currentCuePointData;
@property (nonatomic, assign) NSTimeInterval currentTimestamp;

@property (nonatomic, strong) NSString *currentPropertyName;

@end

@implementation TDCuePointHistoryParser

-(void)requestHistoryForURL:(NSURL*)url
           completionBlock:(void (^)(NSArray* historyList, NSError *error)) completionBlock {
    self.callbackBlock = completionBlock;
    
    [TritonSDKUtils downloadDataFromURL:url withHeaders:nil withCompletionHandler:^(NSData *data, NSError *error) {
        if (error) {
            completionBlock(nil, error);
            return;
        }
        [self startParserWithData:data];
    }];
}

-(void)startParserWithData:(NSData*) data {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
        parser.delegate = self;
        [parser setShouldProcessNamespaces:NO];
        [parser setShouldReportNamespacePrefixes:NO];
        [parser setShouldResolveExternalEntities:NO];
        
        if ([parser parse]) {
            NSArray *immutableArray = [NSArray arrayWithArray:self.parsedItems];
            self.callbackBlock(immutableArray, nil);
        }
    });
}

#pragma mark - NSXMLParserDelegate

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    if ([elementName isEqualToString:@"nowplaying-info-list"]) {
        self.parsedItems = [[NSMutableArray alloc] init];
    
    } else if ([elementName isEqualToString:@"nowplaying-info"]) {
        self.currentCuePointData = [NSMutableDictionary dictionary];
        self.currentCuePointData[CommonCueTypeKey] = attributeDict[@"type"];
        self.currentTimestamp = [attributeDict[@"timestamp"] integerValue];
        
    } else if ([elementName isEqualToString:@"property"]) {
        self.currentPropertyName = attributeDict[@"name"];
    }
}

-(void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    if ([elementName isEqualToString:@"property"]) {
        self.currentPropertyName = nil;
        
    } else if ([elementName isEqualToString:@"nowplaying-info"]) {
        CuePointEvent *cuePoint = [[CuePointEvent alloc] initWithData:self.currentCuePointData andTimestamp:self.currentTimestamp];
        [self.parsedItems addObject:cuePoint];
    }
}

-(void)parser:(NSXMLParser *)parser foundCDATA:(NSData *)CDATABlock {
    if (self.currentPropertyName) {
        self.currentCuePointData[self.currentPropertyName] = [[NSString alloc] initWithData:CDATABlock encoding:NSUTF8StringEncoding];
    }
}

-(void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {

    self.callbackBlock(nil, parseError);
}
@end
