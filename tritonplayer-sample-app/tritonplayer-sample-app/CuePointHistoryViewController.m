//
//  CuePointHistoryViewController.m
//  tritonplayer-sample-app
//
//  Copyright (c) 2015 Triton Digital. All rights reserved.
//

#import "CuePointHistoryViewController.h"

#import <TritonPlayerSDK/TritonPlayerSDK.h>
#import "ArrayDataSource.h"
#import "ListTableViewController.h"

@interface CuePointHistoryViewController ()

@property (weak, nonatomic) IBOutlet UITextField *labelMount;
@property (weak, nonatomic) IBOutlet UITextField *labelMaximumItems;
@property (weak, nonatomic) IBOutlet UISwitch *switchAd;
@property (weak, nonatomic) IBOutlet UISwitch *switchSpeech;
@property (weak, nonatomic) IBOutlet UISwitch *switchTrack;

@property (strong, nonatomic) TDCuePointHistory *cuePointHistory;

@property (strong, nonatomic) ListTableViewController *listViewController;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@end

@implementation CuePointHistoryViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
    self.navigationItem.leftItemsSupplementBackButton = YES;
    
    self.listViewController = self.childViewControllers.firstObject;
    
    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.timeZone = [NSTimeZone localTimeZone];
    [self.dateFormatter setDateStyle:NSDateFormatterShortStyle];
    [self.dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    
    self.cuePointHistory = [[TDCuePointHistory alloc] init];
    
    [self resetParameters];
}

-(void)resetParameters {
    // Config default values
    self.labelMount.text = @"BASIC_CONFIGAAC.preprod";
    self.labelMaximumItems.text = @"20";
    
    self.switchAd.on = NO;
    self.switchSpeech.on = NO;
    self.switchTrack.on = YES;
}

- (IBAction)requestPressed:(id)sender {
    NSString *mount = self.labelMount.text;
    NSInteger maxItems = [self.labelMaximumItems.text integerValue];

    // Create and populate a filter array depending of the UISwitch values
    NSMutableArray *filter = [NSMutableArray array];

    if (self.switchAd.on) {
        [filter addObject:EventTypeAd];
    }
    
    if (self.switchSpeech.on) {
        [filter addObject:EventTypeSpeech];
    }
    
    if (self.switchTrack.on) {
        [filter addObject:EventTypeTrack];
    }
    
    // Request the history list from the server. The result will be a NSArray of CuePointEvent objects.
    [self.cuePointHistory requestHistoryForMount:mount withMaximumItems:maxItems eventTypeFilter:filter completionHandler:^(NSArray *historyItems, NSError *error) {

        if (error) {
            NSLog(@"Error requesting history: %ld-%@", (long)error.code, error.localizedDescription);
        }
        
        void (^configurationBlock)(UITableViewCell*, CuePointEvent*) = ^(UITableViewCell *cell, CuePointEvent *cuePoint) {
            
            NSMutableString *detailText = [NSMutableString string];
            
            [detailText appendFormat:@"[%@] ", cuePoint.data[CommonCueTypeKey] ];
            
            if (cuePoint.data[TrackArtistNameKey]) {
                [detailText appendString:cuePoint.data[TrackArtistNameKey]];
                [detailText appendString:@" - "];
            }
            
            [detailText appendString:cuePoint.data[CommonCueTitleKey]];
            
            cell.textLabel.text = detailText;
            cell.detailTextLabel.text = [self.dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:cuePoint.timestamp]];
        };
        
        // Create data source and send to ListViewController for display
        ArrayDataSource *dataSource = [[ArrayDataSource alloc] initWithItems:historyItems andCellIdentifier:@"ListViewCell" andConfigurationBlock:configurationBlock];
        self.listViewController.arrayDataSource = dataSource;
        
    }];
}

- (IBAction)resetPressed:(id)sender {
    [self resetParameters];
}

@end
