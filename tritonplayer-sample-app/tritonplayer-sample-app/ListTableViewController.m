//
//  ListTableViewController.m
//  tritonplayer-sample-app
//
//  Copyright (c) 2015 Triton Digital. All rights reserved.
//

#import "ListTableViewController.h"

@implementation ListTableViewController

-(void)setArrayDataSource:(ArrayDataSource *)arrayDataSource {
    _arrayDataSource = arrayDataSource;
    
    self.tableView.dataSource = _arrayDataSource;
    
    [self.tableView reloadData];
}

@end
