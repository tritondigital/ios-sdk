//
//  Server.h
//  iPhone V2
//
//  Created by Thierry Bucco on 08-11-03.
//  Copyright 2008 StreamTheWorld. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface Server : NSObject
{
	NSString *ip;
	NSString *url;
	NSString *port;
	
	NSMutableArray *urls; // ip + port
    NSMutableArray *ports;
	UInt8 usedUrlIndex;
}

@property (nonatomic, strong) NSString *ip;
@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSString *port;
@property (nonatomic, strong) NSMutableArray *urls;
@property (nonatomic, strong) NSMutableArray *ports;

- (id)init;
- (void)addPort:(NSString *)thePort;
- (void)addUrl:(NSString *)theUrl;
- (BOOL)getNextAvailableUrl;

@end