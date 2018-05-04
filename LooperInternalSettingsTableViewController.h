//
//  LooperInternalSettingsTableViewController.h
//  LoopMusic
//
//  Created by Johann Gan on 2/9/18.
//  Copyright © 2018 Cheng Hann Gan. All rights reserved.
//

#import "LooperSettingsTableViewController.h"

@interface LooperInternalSettingsTableViewController : LooperSettingsTableViewController
@property (strong, nonatomic) IBOutlet UISwitch *fadeDetectionToggler;

/*!
 * Sets the looper fade detection flag.
 * @param sender The object that called this function.
 */
- (IBAction)setFadeDetection:(id)sender;

/*!
 * Updates the UISwitch to match the current looper fade detection flag.
 */
- (void)updateFadeDetectionToggler;

@end
