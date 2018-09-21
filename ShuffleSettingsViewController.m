//
//  ShuffleSettingsViewController.m
//  LoopMusic
//
//  Created by Cheng Hann Gan on 9/19/18.
//  Copyright © 2018 Cheng Hann Gan. All rights reserved.
//

#import "ShuffleSettingsViewController.h"
#import "SettingsStore.h"

@interface ShuffleSettingsViewController ()

@end

@implementation ShuffleSettingsViewController

@synthesize shuffleSegment, mainShuffleLabel, mainShuffleSetting, varianceLabel, varianceSetting, minShuffleLabel, minShuffleSetting, maxShuffleLabel, maxShuffleSetting;

- (void)viewDidLoad
{
    shuffleSegment.selectedSegmentIndex = SettingsStore.instance.shuffleSetting;
    [self changeShuffleDisplay];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(closeKeyboards)];
    [self.view addGestureRecognizer:tap];
}

- (void)viewWillAppear:(BOOL)animated
{
    presenter = (LoopMusicViewController*)self.presentingViewController.presentingViewController;
}

- (IBAction)back:(id)sender
{
    [self saveSettings];
    [super back:sender];
}

/*!
 * Changes the layout and values of the screen according to the current shuffle setting.
 */
- (void)changeShuffleDisplay
{
    [self closeKeyboards];
    
    switch (shuffleSegment.selectedSegmentIndex)
    {
        case NONE:
            [self setSettingsHidden:true];
            break;
        case TIME:
            [self setSettingsHidden:false];
            [mainShuffleLabel setText:@"Time:"];
            [varianceLabel setText:@"Time Variance:"];
            [minShuffleLabel setText:@"Min Repeats:"];
            [maxShuffleLabel setText:@"Max Repeats:"];
            
            [mainShuffleSetting setText:[self getDoubleDisplayString:SettingsStore.instance.timeShuffle]];
            [varianceSetting setText:[self getDoubleDisplayString:SettingsStore.instance.timeShuffleVariance]];
            [minShuffleSetting setText:[self getDoubleDisplayString:SettingsStore.instance.minRepeatsShuffle]];
            [maxShuffleSetting setText:[self getDoubleDisplayString:SettingsStore.instance.maxRepeatsShuffle]];
            break;
        case REPEATS:
            [self setSettingsHidden:false];
            [mainShuffleLabel setText:@"Repeats:"];
            [varianceLabel setText:@"Repeats Variance:"];
            [minShuffleLabel setText:@"Min Time:"];
            [maxShuffleLabel setText:@"Max Time:"];
            
            [mainShuffleSetting setText:[self getDoubleDisplayString:SettingsStore.instance.repeatsShuffle]];
            [varianceSetting setText:[self getDoubleDisplayString:SettingsStore.instance.repeatsShuffleVariance]];
            [minShuffleSetting setText:[self getDoubleDisplayString:SettingsStore.instance.minTimeShuffle]];
            [maxShuffleSetting setText:[self getDoubleDisplayString:SettingsStore.instance.maxTimeShuffle]];
            break;
    }
    
    [mainShuffleSetting setPlaceholder:[self getSubstringMinusOne:mainShuffleLabel.text]];
    [minShuffleSetting setPlaceholder:[self getSubstringMinusOne:minShuffleLabel.text]];
    [maxShuffleSetting setPlaceholder:[self getSubstringMinusOne:maxShuffleLabel.text]];
    
    shuffleMode = shuffleSegment.selectedSegmentIndex;
}

/*!
 * Gets a substring of a string that excludes the last character.
 * @param string The string to get a substring of.
 * @return A substring of the given string that omits the last character.
 */
- (NSString*)getSubstringMinusOne:(NSString*)string
{
    return [string substringToIndex:string.length - 1];
}

/*!
 * Sets whether the settings fields and labels are hidden.
 * @param hidden Whether the settings are hidden.
 */
- (void)setSettingsHidden:(bool)hidden
{
    [mainShuffleLabel setHidden:hidden];
    [mainShuffleSetting setHidden:hidden];
    [varianceLabel setHidden:hidden];
    [varianceSetting setHidden:hidden];
    [minShuffleLabel setHidden:hidden];
    [minShuffleSetting setHidden:hidden];
    [maxShuffleLabel setHidden:hidden];
    [maxShuffleSetting setHidden:hidden];
}

/*!
 * Converts a double to a string, or blank if the number is 0.
 */
- (NSString*)getDoubleDisplayString:(double)number
{
    return number > 0 ? [NSString stringWithFormat:@"%@", @(number)] : @"";
}

- (IBAction)setMainShuffle:(id)sender
{
    switch (shuffleMode)
    {
        case TIME:
            SettingsStore.instance.timeShuffle = [mainShuffleSetting.text doubleValue];
            break;
        case REPEATS:
            SettingsStore.instance.repeatsShuffle = [mainShuffleSetting.text integerValue];
            break;
    }
}

- (IBAction)setVarianceShuffle:(id)sender
{
    switch (shuffleMode)
    {
        case TIME:
            SettingsStore.instance.timeShuffleVariance = [varianceSetting.text doubleValue];
            break;
        case REPEATS:
            SettingsStore.instance.repeatsShuffleVariance = [varianceSetting.text doubleValue];
            break;
    }
}

- (IBAction)setMinShuffle:(id)sender
{
    switch (shuffleMode)
    {
        case TIME:
            SettingsStore.instance.minRepeatsShuffle = [minShuffleSetting.text doubleValue];
            if (SettingsStore.instance.maxRepeatsShuffle > 0 && SettingsStore.instance.minRepeatsShuffle > SettingsStore.instance.maxRepeatsShuffle)
            {
                SettingsStore.instance.minRepeatsShuffle = SettingsStore.instance.maxRepeatsShuffle;
                [minShuffleSetting setText:[self getDoubleDisplayString:SettingsStore.instance.minRepeatsShuffle]];
            }
            break;
        case REPEATS:
            SettingsStore.instance.minTimeShuffle = [minShuffleSetting.text doubleValue];
            if (SettingsStore.instance.maxTimeShuffle > 0 && SettingsStore.instance.minTimeShuffle > SettingsStore.instance.maxTimeShuffle)
            {
                SettingsStore.instance.minTimeShuffle = SettingsStore.instance.maxTimeShuffle;
                [minShuffleSetting setText:[self getDoubleDisplayString:SettingsStore.instance.minTimeShuffle]];
            }
            break;
    }
}

- (IBAction)setMaxShuffle:(id)sender
{
    switch (shuffleMode)
    {
        case TIME:
            SettingsStore.instance.maxRepeatsShuffle = [maxShuffleSetting.text doubleValue];
            if (SettingsStore.instance.minRepeatsShuffle > 0 && SettingsStore.instance.minRepeatsShuffle > SettingsStore.instance.maxRepeatsShuffle)
            {
                SettingsStore.instance.maxRepeatsShuffle = SettingsStore.instance.minRepeatsShuffle;
                [maxShuffleSetting setText:[self getDoubleDisplayString:SettingsStore.instance.maxRepeatsShuffle]];
            }
            break;
        case REPEATS:
            SettingsStore.instance.maxTimeShuffle = [maxShuffleSetting.text doubleValue];
            if (SettingsStore.instance.minTimeShuffle > 0 && SettingsStore.instance.minTimeShuffle > SettingsStore.instance.maxTimeShuffle)
            {
                SettingsStore.instance.maxTimeShuffle = SettingsStore.instance.minTimeShuffle;
                [maxShuffleSetting setText:[self getDoubleDisplayString:SettingsStore.instance.maxTimeShuffle]];
            }
            break;
    }
}

- (IBAction)shuffleChange:(id)sender
{
    SettingsStore.instance.shuffleSetting = [shuffleSegment selectedSegmentIndex];
    [self changeShuffleDisplay];
}

/*!
 * Closes any open keyboards.
 */
- (void)closeKeyboards
{
    [mainShuffleSetting resignFirstResponder];
    [varianceSetting resignFirstResponder];
    [minShuffleSetting resignFirstResponder];
    [maxShuffleSetting resignFirstResponder];
}

@end
