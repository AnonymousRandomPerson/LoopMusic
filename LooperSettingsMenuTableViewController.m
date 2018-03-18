//
//  LooperSettingsMenuTableViewController.m
//  LoopMusic
//
//  Created by Johann Gan on 2/9/18.
//  Copyright © 2018 Cheng Hann Gan. All rights reserved.
//

#import "LooperSettingsMenuTableViewController.h"

@interface LooperSettingsMenuTableViewController ()

@end

@implementation LooperSettingsMenuTableViewController

@synthesize finder;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self turnOffTouchDelays];
}

/// Turn off content touch delay in all the cells
- (void)turnOffTouchDelays
{
    for (UIView *currentView in self.tableView.subviews)
    {
        if([currentView isKindOfClass:[UIScrollView class]])
        {
            ((UIScrollView *)currentView).delaysContentTouches = NO;
            break;
        }
    }
}


- (IBAction)back:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (IBAction)resetToDefaults:(id)sender
{
    [finder useDefaultParams];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"NavigateToInitialEstimateSettings"] ||
        [segue.identifier isEqualToString:@"NavigateToInternalSettings"] ||
        [segue.identifier isEqualToString:@"NavigateToPerformanceSettings"] ||
        [segue.identifier isEqualToString:@"NavigateToOutputSettings"])
    {
        // Pass the loop finder object to the settings controller for settings modification.
        LooperSettingsTableViewController *newVC = segue.destinationViewController;
        newVC.finder = finder;
    }
}

@end
