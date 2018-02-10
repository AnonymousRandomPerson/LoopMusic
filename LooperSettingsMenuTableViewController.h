//
//  LooperSettingsMenuTableViewController.h
//  LoopMusic
//
//  Created by Johann Gan on 2/9/18.
//  Copyright © 2018 Cheng Hann Gan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LoopFinderAuto.h"
#import "LooperSettingsTableViewController.h"

// NOTE: Currently all the settings reset once the user exits to the mains screen of the app. Possible change: store the settings in a table?

/// The main advanced settings screen for the automatic loop finder.
@interface LooperSettingsMenuTableViewController : UITableViewController
/// The looper to change the settings of.
@property (strong, nonatomic) LoopFinderAuto *finder;


/*!
 * Navigates back to the looping screen.
 * @param sender The object that called this function.
 * @return
 */
- (IBAction)back:(id)sender;


/*!
 * Resets all looping parameters back to their defaults.
 * @param sender The object that called this function.
 * @return
 */
- (IBAction)resetToDefaults:(id)sender;

@end
