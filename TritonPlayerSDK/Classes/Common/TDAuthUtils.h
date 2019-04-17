//
//  TDAuthUtils.h
//  TritonPlayerSDK
//
//  Created by Carlos Pereira on 2015-07-08.
//  Copyright (c) 2015 Triton Digital. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TDAuthUtils : NSObject

+(NSString*)createJWTTokenWithSecretKey:(NSString*)secretKey
                         andSecretKeyId:(NSString*)secretKeyId
                      andRegisteredUser:(BOOL)registeredUser
                              andUserId:(NSString*)userId
                 andTargetingParameters:(NSDictionary*)targetingParameters;

@end
