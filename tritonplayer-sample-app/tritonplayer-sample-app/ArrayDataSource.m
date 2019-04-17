//
//  ArrayDataSource.m
//  tritonplayer-sample-app
//
//  Copyright (c) 2015 Triton Digital. All rights reserved.
//
//

#import "ArrayDataSource.h"

@interface ArrayDataSource ()

@property (nonatomic, copy) NSString *cellIdentifier;
@property (nonatomic, copy) CollectionConfigurationBlock configureCellBlock;

@end

@implementation ArrayDataSource

-(instancetype)initWithItems:(NSArray *)items andCellIdentifier:(NSString *)cellIdentifier andConfigurationBlock:(CollectionConfigurationBlock)configurationBlock {
    self = [super init];
    if (self) {
        self.items = items;
        self.cellIdentifier = cellIdentifier;
        self.configureCellBlock = configurationBlock;
        
    }
    return self;
}

-(id)itemAtIndexPath:(NSIndexPath *)indexPath {
    return self.items[indexPath.row];
}

#pragma mark - UITableViewDataSource

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.items.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    id item = [self itemAtIndexPath:indexPath];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:self.cellIdentifier forIndexPath:indexPath];
    self.configureCellBlock(cell, item);
    
    return cell;
}

@end
