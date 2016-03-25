//
//  LoopFinderViewController.h
//  LoopMusic
//
//  Created by Cheng Hann Gan on 6/16/14.
//  Copyright (c) 2014 Cheng Hann Gan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SettingsViewController.h"

@interface LoopFinderViewController : SettingsViewController
{
    /// Text field to change the playback time of the current track.
    IBOutlet UITextField *setCurrentTime;
    /// Label displaying the name of the current track.
    IBOutlet UILabel *finderSongName;
    /// Text field to change the loop start time of the current track.
    IBOutlet UITextField *finderSetTime;
    /// Text field to change the loop end time of the current track.
    IBOutlet UITextField *finderSetTimeEnd;
    /// Label displaying the most recently found playback time.
    IBOutlet UILabel *findTimeText;
}

/// Text field to change the playback time of the current track.
@property(nonatomic, retain) UITextField *setCurrentTime;
/// Label displaying the name of the current track.
@property(nonatomic, retain) UILabel *finderSongName;
/// Text field to change the loop start time of the current track.
@property(nonatomic, retain) UITextField *finderSetTime;
/// Text field to change the loop end time of the current track.
@property(nonatomic, retain) UITextField *finderSetTimeEnd;

/*!
 * Sets the playback time of the current track.
 * @param sender The object that called this function.
 * @return
 */
- (IBAction)setCurrentTime:(id)sender;
/*!
 * Sets the loop start time of the current track.
 * @param sender The object that called this function.
 * @return
 */
- (IBAction)finderSetTime:(id)sender;
/*!
 * Sets the loop end time of the current track.
 * @param sender The object that called this function.
 * @return
 */
- (IBAction)finderSetTimeEnd:(id)sender;
/*!
 * Sets the loop start time of the current track to the most recently found playback time.
 * @param sender The object that called this function.
 * @return
 */
- (IBAction)setTimeButton:(id)sender;
/*!
 * Sets the loop end time of the current track to the most recently found playback time.
 * @param sender The object that called this function.
 * @return
 */
- (IBAction)setEndButton:(id)sender;

@end
