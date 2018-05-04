//
//  LooperInternalSettingsTableViewController.m
//  LoopMusic
//
//  Created by Johann Gan on 2/9/18.
//  Copyright © 2018 Cheng Hann Gan. All rights reserved.
//

#import "LooperInternalSettingsTableViewController.h"

@interface LooperInternalSettingsTableViewController ()

@end

@implementation LooperInternalSettingsTableViewController

@synthesize fadeDetectionToggler;

- (void)viewDidLoad {
    [super viewDidLoad];
}

/// Returns the parameter names dictionary.
- (NSDictionary*)formParamNamesDict
{
    return @{@1 : @"minLoopLength",
             @2 : @"minTimeDiff",
             @3 : @"leftIgnore",
             @4 : @"rightIgnore",
             @5 : @"sampleDiffTol",
             @6 : @"fftLength",
             @7 : @"overlapPercent"
             };
}


- (void)refreshParameterDisplays
{
    [super refreshParameterDisplays];
    [self updateFadeDetectionToggler];
}


- (IBAction)setFadeDetection:(id)sender
{
    self.finder.useFadeDetection = [fadeDetectionToggler isOn];
}

- (void)updateFadeDetectionToggler
{
    [fadeDetectionToggler setOn:self.finder.useFadeDetection];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
