//
//  LooperEstimateSettingsTableViewController.m
//  LoopMusic
//
//  Created by Johann Gan on 2/9/18.
//  Copyright © 2018 Cheng Hann Gan. All rights reserved.
//

#import "LooperEstimateSettingsTableViewController.h"

@interface LooperEstimateSettingsTableViewController ()

@end

@implementation LooperEstimateSettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

/// Returns the parameter names dictionary.
- (NSDictionary*)formParamNamesDict
{
    return @{@1 : @"t1Radius",
             @2 : @"t2Radius",
             @3 : @"tauRadius",
             @4 : @"t1Penalty",
             @5 : @"t2Penalty",
             @6 : @"tauPenalty"
             };
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
