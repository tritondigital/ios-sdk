//
//  TDAuthUtils.m
//  TritonPlayerSDK
//
//  Created by Carlos Pereira on 2015-07-08.
//  Copyright (c) 2015 Triton Digital. All rights reserved.
//

#import "TDAuthUtils.h"

#import <CommonCrypto/CommonHMAC.h>

@implementation TDAuthUtils

+(NSString*)createJWTProtectedHeaderWithKeyId:(NSString*)keyId {
    NSMutableDictionary *header = [NSMutableDictionary dictionary];
    header[@"typ"] = @"JWT";
    header[@"alg"] = @"HS256";
    
    if (keyId) {
        header[@"kid"] = keyId;
    }
    
    return [TDAuthUtils base64JSONFromDictionary:header];
}

+(NSString*)createJWTClaimsSetWithUserId:(NSString*)userId andRegisteredUser:(BOOL)registeredUser andTargetingParameters:(NSDictionary*)targetingParameters {
    NSMutableDictionary *claimsSet = [NSMutableDictionary dictionary];
    claimsSet[@"iss"] = @"TdSdk";
    claimsSet[@"aud"] = @"td";
    
    if (userId) {
        claimsSet[@"sub"] = userId;
    }
    claimsSet[@"iat"] = @( (int64_t)[[NSDate date] timeIntervalSince1970]);
    claimsSet[@"td-reg"] = @(registeredUser);
    
    // Add targeting parameters
    if (targetingParameters) {
        for (NSString *key in targetingParameters.allKeys) {
            claimsSet[[NSString stringWithFormat:@"td-%@", key]] = targetingParameters[key];
        }
    }
    
    return [TDAuthUtils base64JSONFromDictionary:claimsSet];
}

+(NSString*)createJWSSignatureFromHeader:(NSString*)header andClaimsSet:(NSString*)claimsSet andSecretKey:(NSString*)secretKey {
    NSString *signatureToHash = [NSString stringWithFormat:@"%@.%@", header, claimsSet];

    // Hashed string is already base64 encoded
		NSString *hashedString = [TDAuthUtils computeHmac256WithString:signatureToHash andSecretKey:secretKey];
		hashedString = [hashedString stringByReplacingOccurrencesOfString:@"/"
																													 withString:@"_"];
		
		hashedString = [hashedString stringByReplacingOccurrencesOfString:@"+"
																													 withString:@"-"];
		
		hashedString = [hashedString stringByReplacingOccurrencesOfString:@"="
																													 withString:@""];
		
    return hashedString;
}

+(NSString*)createJWTTokenWithSecretKey:(NSString*)secretKey
                         andSecretKeyId:(NSString*)secretKeyId
                      andRegisteredUser:(BOOL)registeredUser
                              andUserId:(NSString*)userId
                 andTargetingParameters:(NSDictionary*)targetingParameters {

    NSString *header = [TDAuthUtils createJWTProtectedHeaderWithKeyId:secretKeyId];
    NSString *claimsSet = [TDAuthUtils createJWTClaimsSetWithUserId:userId andRegisteredUser:registeredUser andTargetingParameters:targetingParameters];
    NSString *signature = [TDAuthUtils createJWSSignatureFromHeader:header andClaimsSet:claimsSet andSecretKey:secretKey];
    
    return [NSString stringWithFormat:@"%@.%@.%@", header, claimsSet, signature];
}

+(NSString*)base64JSONFromDictionary:(NSDictionary*)dictionary {
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:&error];
    
    NSString *encodedString = nil;
    if (!error) {
        encodedString = [jsonData base64EncodedStringWithOptions:0];
				encodedString = [encodedString stringByReplacingOccurrencesOfString:@"/"
																																 withString:@"_"];
				
				encodedString = [encodedString stringByReplacingOccurrencesOfString:@"+"
																																 withString:@"-"];
				
				encodedString = [encodedString stringByReplacingOccurrencesOfString:@"="
																																 withString:@""];
    }
    
    return encodedString;
}

+(NSString*)computeHmac256WithString:(NSString *)string andSecretKey:(NSString*)secretKey {
    NSData *secretData = [secretKey dataUsingEncoding:NSUTF8StringEncoding];
    NSData *paramData = [string dataUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableData* hash = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH ];
    CCHmac(kCCHmacAlgSHA256, secretData.bytes, secretData.length, paramData.bytes, paramData.length, hash.mutableBytes);
    
    return [hash base64EncodedStringWithOptions:0];
}

@end
