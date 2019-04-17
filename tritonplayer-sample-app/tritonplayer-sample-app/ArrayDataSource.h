//
//  ArrayDataSource.h
//  tritonplayer-sample-app
//
//  Copyright (c) 2015 Triton Digital. All rights reserved.
//
//

#import <Foundation/Foundation.h>

typedef void (^CollectionConfigurationBlock)(id cell, id item);

@interface ArrayDataSource : NSObject <UITableViewDataSource>

- (instancetype)initWithItems:(NSArray*) items
            andCellIdentifier:(NSString*) cellIdentifier
        andConfigurationBlock:(CollectionConfigurationBlock)configurationBlock;

- (id)itemAtIndexPath:(NSIndexPath*)indexPath;

@property (nonatomic, strong) NSArray *items;
@property (readonly, copy) NSString *cellIdentifier;

@end
