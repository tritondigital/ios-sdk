//
//  MainMenuViewController.m
//  tritonplayer-sample-app
//
//  Copyright (c) 2015 Triton Digital. All rights reserved.
//

#import "MainMenuViewController.h"
#import <TritonPlayerSDK/TritonPlayerSDK.h>

@implementation MainMenuViewController

-(void)viewDidLoad {
    self.clearsSelectionOnViewWillAppear = NO;
}

-(void)viewWillAppear:(BOOL)animated {
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    self.navigationItem.title = [NSString stringWithFormat:@"Triton iOS SDK sample - SDK %@", TritonSDKVersion];
}

@end
