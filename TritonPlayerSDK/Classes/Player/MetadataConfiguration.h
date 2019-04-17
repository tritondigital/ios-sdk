//
//  SidebandMetadata.h
//  FLVStreamPlayerLib64
//
//  Created by Carlos Pereira on 2014-10-07.
//
//

#import <Foundation/Foundation.h>

@interface MetadataConfiguration : NSObject

@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, strong) NSString *mountSuffix;
@property (nonatomic, strong) NSString *metadataSuffix;

@end
