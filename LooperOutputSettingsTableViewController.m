//
//  LooperOutputSettingsTableViewController.m
//  LoopMusic
//
//  Created by Johann Gan on 2/9/18.
//  Copyright © 2018 Cheng Hann Gan. All rights reserved.
//

#import "LooperOutputSettingsTableViewController.h"

@interface LooperOutputSettingsTableViewController ()

@end

@implementation LooperOutputSettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

/// Returns the parameter names dictionary.
- (NSDictionary*)formParamNamesDict
{
    return @{@1 : @"nBestDurations",
             @2 : @"nBestPairs"
             };
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
