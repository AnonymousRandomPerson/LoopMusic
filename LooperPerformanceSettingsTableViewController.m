//
//  LooperPerformanceSettingsTableViewController.m
//  LoopMusic
//
//  Created by Johann Gan on 3/18/18.
//  Copyright © 2018 Cheng Hann Gan. All rights reserved.
//

#import "LooperPerformanceSettingsTableViewController.h"

@interface LooperPerformanceSettingsTableViewController ()

@end

@implementation LooperPerformanceSettingsTableViewController

@synthesize useMonoAudioToggler, framerateReductionFactorSlider, framerateReductionFactorVal;

- (void)viewDidLoad
{
    [super viewDidLoad];
    framerateReductionFactorSlider.maximumValue = self.finder.framerateReductionLimit;
}


/// Returns the parameter names dictionary.
- (NSDictionary*)formParamNamesDict
{
    return @{};
}


- (void)refreshParameterDisplays
{
    [super refreshParameterDisplays];
    [self updateUseMonoAudioToggler];
    [self updateFramerateReductionFactorSlider];
}


- (IBAction)setUseMonoAudio:(id)sender
{
    self.finder.useMonoAudio = [useMonoAudioToggler isOn];
}

- (void)updateUseMonoAudioToggler
{
    [useMonoAudioToggler setOn:self.finder.useMonoAudio];
}


- (IBAction)setFramerateReductionFactor:(id)sender
{
    NSInteger sliderValue = lroundf(framerateReductionFactorSlider.value);
    [framerateReductionFactorSlider setValue:sliderValue animated:YES];
    [framerateReductionFactorVal setText:[@(sliderValue) stringValue]];
    self.finder.framerateReductionFactor = sliderValue;
}

- (void)updateFramerateReductionFactorSlider
{
    [framerateReductionFactorVal setText:[@(self.finder.framerateReductionFactor) stringValue]];
    [framerateReductionFactorSlider setValue:self.finder.framerateReductionFactor];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
