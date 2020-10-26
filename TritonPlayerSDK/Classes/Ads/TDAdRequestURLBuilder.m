//
//  TDAdRequestURLBuilder.m
//  TritonPlayerSDK
//
//  Created by Carlos Pereira on 2014-11-26.
//  Copyright (c) 2014 Triton Digital. All rights reserved.
//

#import "TritonPlayer.h"
#import "TDAdRequestURLBuilder.h"
#import "TritonPlayerUtils.h"
#import "TDLocationManager.h"

#define kDictionaryInitialCapacity 15

#define kAdGuideVersion @"1.5.1"

NSString *const kRequestAdType = @"type";
NSString *const kRequestAdFormat = @"fmt";

NSString *const kTargetingStationId = @"stid";
NSString *const kTargetingStationName = @"stn";

NSString *const kTargetingLatitude = @"lat";
NSString *const kTargetingLongitude = @"long";
NSString *const kTargetingPostalCode = @"postalcode";
NSString *const kTargetingCountry = @"country";

NSString *const kTargetingAge = @"age";
NSString *const kTargetingDateOfBirth = @"dob";
NSString *const kTargetingYearOfBirth = @"yob";
NSString *const kTargetingGender = @"gender";

NSString *const kTargetingBundleId = @"bundle-id";
NSString *const kTargetingStoreId = @"store-id";
NSString *const kTargettngStoreUrl = @"store-url";

NSString *const kTargetingCustomSegmendId = @"csegid";

NSString *const kConstraintAssetType = @"at";

NSString *const kCapabilityBanners = @"banners";

@interface TDAdRequestURLBuilder ()

@property (nonatomic, copy) NSString *hostURL;
@property (nonatomic, strong) NSMutableDictionary *requestParameters;
@property (nonatomic, copy) NSArray *Tags;

@end

@implementation TDAdRequestURLBuilder

+(instancetype)builderWithHostURL:(NSString *)url {
    return [[TDAdRequestURLBuilder alloc] initWithHostURL:url];
}

-(instancetype)initWithHostURL:(NSString *)url {
    self = [super init];
    
    if (self) {
        self.hostURL = url;
        [self resetParameters];
    }
    return self;
}

-(void)resetParameters {
    self.extraParameters = nil;
    
    self.requestParameters = [NSMutableDictionary dictionaryWithCapacity:kDictionaryInitialCapacity];
    self.requestParameters[kRequestAdFormat] = @"vast";
    self.requestParameters[kRequestAdType] = @"preroll";
    
    self.autoLocationTrackingEnabled = NO;
}

-(void)setHostURL:(NSString *)hostURL {
    NSURL *url = [NSURL URLWithString:hostURL];
    NSString *scheme = url.scheme;
    NSString *path = url.path;
    
    if (!scheme) {
        NSString *updatedUrl = [NSString stringWithFormat:@"%@%@", @"https://", hostURL];
        url = [NSURL URLWithString:updatedUrl];
    }
    
    if (![scheme  isEqual: @"https"]) {
        scheme = @"https";
    }
    
    if (![path isEqual: @"/ondemand/ars"]) {
        path = @"/ondemand/ars";
    }
    
    _hostURL = [NSString stringWithFormat:@"%@://%@%@", scheme, url.host, path];
}

-(void)setAdType:(TDAdType)adType {
    if (adType == kTDAdTypePreroll) {
        [self.requestParameters setObject:@"preroll" forKey:kRequestAdType];
        
    } else if (adType == kTDAdTypeMidroll) {
        [self.requestParameters setObject:@"midroll" forKey:kRequestAdType];
    }
}

-(TDAdType)adType {
    NSString *val = [self.requestParameters objectForKey:kRequestAdType];
    return val ? ([val isEqualToString:@"preroll"] ? kTDAdTypePreroll : kTDAdTypeMidroll) : kTDAdTypePreroll;

}

-(void)setStationId:(NSInteger)stationId {
    self.requestParameters[kTargetingStationId] = @(stationId);
}

-(NSInteger)stationId {
    return [self.requestParameters[kTargetingStationId] integerValue];
}

-(void)setStationName:(NSString *)stationName {
    if (stationName) {
        self.requestParameters[kTargetingStationName] = stationName;
    }
}

-(NSString *)stationName {
    return self.requestParameters[kTargetingStationName];
}

#pragma mark - Geographical targeting

-(void)setLocationWithLatitude:(float)latitude andLongitude:(float)longitude {
    self.latitude = latitude;
    self.longitude = longitude;
}

-(void)setLatitude:(float)latitude {
    if (latitude >= -90.0f && latitude <= 90.0f) {
        self.requestParameters[kTargetingLatitude] = @(latitude);
    }
}

-(float)latitude {
    NSNumber *val = self.requestParameters[kTargetingLatitude];
    return val ? [val floatValue] : MAXFLOAT;
}

-(void)setLongitude:(float)longitude {
    if (longitude >= -180.0f && longitude <= 180.0f) {
        self.requestParameters[kTargetingLongitude] = @(longitude);
    }
}

-(float)longitude {
    NSNumber *val = self.requestParameters[kTargetingLongitude];
    return val ? [val floatValue] : MAXFLOAT;
}

-(void)setPostalCode:(NSString *)postalCode {
    if (postalCode) {
        self.requestParameters[kTargetingPostalCode] = postalCode;
    }
}

-(void)setTTags:(NSArray*)tags {
    self.Tags = [tags copy];
}

-(NSArray *)TTags {
    return self.Tags;
}

-(NSString *)postalCode {
    return self.requestParameters[kTargetingPostalCode];
}

-(void)setCountry:(NSString *)country {
    if (country && country.length == 2) {
        self.requestParameters[kTargetingCountry] = country;
    }
}

-(NSString *)country {
    return self.requestParameters[kTargetingCountry];
}

-(void)setAutoLocationTrackingEnabled:(BOOL)autoLocationTrackingEnabled {
    if (autoLocationTrackingEnabled) {
        [[TDLocationManager sharedManager] startLocation];
    
    } else {
        [[TDLocationManager sharedManager] stopLocation];
    }
    
    _autoLocationTrackingEnabled = autoLocationTrackingEnabled;
}

#pragma mark - Demographic targeting

-(void)setAge:(NSInteger)age {
    if (age >= 1 && age <= 125) {
        [self.requestParameters setObject:@(age) forKey:kTargetingAge];
    }
}

-(NSInteger)age {
    return [[self.requestParameters objectForKey:kTargetingAge] integerValue];
}

-(void)setDateOfBirth:(NSDate *)dateOfBirth {
    if (dateOfBirth) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd"];
        [self.requestParameters setObject:[dateFormatter stringFromDate:dateOfBirth] forKey:kTargetingDateOfBirth];
    }
}

-(void)setDateOfBirthFromString:(NSString *)dateOfBirth {
    //YYYY-MM-DD
    if (dateOfBirth.length == 10 && [dateOfBirth characterAtIndex:4] == '-' && [dateOfBirth characterAtIndex:7] == '-') {
        [self.requestParameters setObject:dateOfBirth forKey:kTargetingDateOfBirth];
    }
}

-(NSString *)dateOfBirth {
    return [self.requestParameters objectForKey:kTargetingDateOfBirth];
}

-(void)setYearOfBirth:(NSInteger)yearOfBirth {
    if (yearOfBirth >= 1900 && yearOfBirth <= 2005) {
        [self.requestParameters setObject:@(yearOfBirth) forKey:kTargetingYearOfBirth];
    }
}

-(NSInteger)yearOfBirth {
    return [[self.requestParameters objectForKey:kTargetingYearOfBirth] integerValue];
}

-(void)setGender:(TDGender)gender {
    if (gender == kTDGenderFemale) {
        [self.requestParameters setObject:@"f" forKey:kTargetingGender];
    
    } else if (gender == kTDGenderMale) {
        [self.requestParameters setObject:@"m" forKey:kTargetingGender];
    }
}

-(TDGender)gender {
    NSString *val = [self.requestParameters objectForKey:kTargetingGender];
    return val ? ([val isEqualToString:@"m"] ? kTDGenderMale : kTDGenderFemale) : kTDGenderNotDefined;
}

#pragma mark - Application targeting

-(void)setBundleId:(NSString *)bundleId {
    if (bundleId) {
        self.requestParameters[kTargetingBundleId] = bundleId;
    }
}

-(NSString *)bundleId {
    return self.requestParameters[kTargetingBundleId];
}

-(void)setStoreId:(NSString *)storeId {
    if (storeId) {
        self.requestParameters[kTargetingStoreId] = storeId;
    }
}

-(NSString *)storeId {
    return self.requestParameters[kTargetingStoreId];
}

-(void)setStoreUrl:(NSString *)storeUrl {
    if (storeUrl) {
        self.requestParameters[kTargettngStoreUrl] = storeUrl;
    }
}

-(NSString *)storeUrl {
    return self.requestParameters[kTargettngStoreUrl];
}

#pragma mark - Banner capabilities

-(void)setBanners:(NSString *)banners {
    if (banners) {
        self.requestParameters[kCapabilityBanners] = banners;
    }
}

-(NSString *)banners {
    return self.requestParameters[kCapabilityBanners];
}

-(void)setCustomSegmentId:(NSInteger)customSegmentId {
    if (customSegmentId >= 1 && customSegmentId <= 1000000) {
        [self.requestParameters setObject:@(customSegmentId) forKey:kTargetingCustomSegmendId];
    }
}

-(NSInteger)customSegmentId {
    return [[self.requestParameters objectForKey:kTargetingCustomSegmendId] integerValue];
}

-(TDAssetType)assetType {
    NSString *val = self.requestParameters[kConstraintAssetType];
    return val ? ([val isEqualToString:@"audio"] ? kTDAssetTypeAudio : ([val isEqualToString:@"video"] ? kTDAssetTypeVideo : kTDAssetTypeAudioVideo)) : kTDAssetTypeNotDefined;
}

-(void)setAssetType:(TDAssetType)assetType {
    if (assetType == kTDAssetTypeAudio) {
        self.requestParameters[kConstraintAssetType] = @"audio";
        
    } else if (assetType == kTDAssetTypeVideo) {
        self.requestParameters[kConstraintAssetType] = @"video";
    } else if (assetType == kTDAssetTypeAudioVideo) {
        self.requestParameters[kConstraintAssetType] = @"audio,video";
    }
}

-(NSString *)generateAdRequestURL {
    
    // Fail when there's no mandatory fields
    if (self.hostURL == nil) {
        NSLog(@"TDAdRequestURLBuilder error: The host URL must be set.");
        return nil;
    }
    
    if (self.stationId == 0 && self.stationName == nil) {
        NSLog(@"TDAdRequestURLBuilder error: Either station name or id must be set.");
        return nil;
    }

    NSURLComponents *components = [NSURLComponents componentsWithString:self.hostURL];
    
    @autoreleasepool {
        
        if (self.autoLocationTrackingEnabled) {
            CLLocation *location = [TDLocationManager sharedManager].targetingLocation;
            
            if (location) {
                [self setLocationWithLatitude:location.coordinate.latitude andLongitude:location.coordinate.longitude];
            }
        }
        
        NSMutableArray *query = [NSMutableArray array];
        NSMutableDictionary *params = [self.requestParameters mutableCopy];
        
        // Merge with extra parameters, overriding the conflicting keys
        [params addEntriesFromDictionary:self.extraParameters];
        
        for (NSString *key in params.allKeys) {
            [query addObject:[NSString stringWithFormat:@"%@=%@", key, params[key]]];
        }
        
        // Add tdsdk to query
        [query addObject:[NSString stringWithFormat:@"tdsdk=iOS-%@-opensource",TritonSDKVersion]];
        
        // Add listener id in the query parameter
        [query addObject:[NSString stringWithFormat:@"lsid=%@", [TritonPlayerUtils getListenerId]]];

        // Add Ad Guide Version
        [query addObject:[NSString stringWithFormat:@"version=%@", kAdGuideVersion]];
        
        // Add banners value by default if missing
        if (!self.banners) {
            [query addObject:@"banners=none"];
        }

        //Add TTags
        if(self.Tags != nil && [self.Tags count] > 0)
        {
            NSString* allTagsConcat = [self.Tags componentsJoinedByString:@","];
            [query addObject:[NSString stringWithFormat:@"ttag=%@",allTagsConcat]];
        }
        
        components.query = [query componentsJoinedByString:@"&"];
        
    }
    
    return [components.URL absoluteString];
}
-(void)reset {
    [self resetParameters];
}

@end
