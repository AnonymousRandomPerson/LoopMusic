//
//  LooperPerformanceSettingsTableViewController.h
//  LoopMusic
//
//  Created by Johann Gan on 3/18/18.
//  Copyright © 2018 Cheng Hann Gan. All rights reserved.
//

#import "LooperSettingsTableViewController.h"

@interface LooperPerformanceSettingsTableViewController : LooperSettingsTableViewController

@property (strong, nonatomic) IBOutlet UISwitch *useMonoAudioToggler;
@property (strong, nonatomic) IBOutlet UISlider *framerateReductionFactorSlider;
@property (strong, nonatomic) IBOutlet UILabel *framerateReductionFactorVal;

/*!
 * Sets the looper useMonoAudio flag.
 * @param sender The object that called this function.
 */
- (IBAction)setUseMonoAudio:(id)sender;

/*!
 * Updates the UISwitch to match the current looper useMonoAudio flag.
 */
- (void)updateUseMonoAudioToggler;

/*!
 * Sets the framerate reduction factor.
 * @param sender The object that called this function.
 */
- (IBAction)setFramerateReductionFactor:(id)sender;

/*!
 * Updates the UISlider to match the current looper framerate reduction factor.
 */
- (void)updateFramerateReductionFactorSlider;

/*!
 * Sets the framerate reduction limit.
 * @param sender The object that called this function.
 */
- (IBAction)setFramerateReductionLimit:(id)sender;


@end
