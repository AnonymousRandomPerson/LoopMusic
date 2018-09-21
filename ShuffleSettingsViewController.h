//
//  ShuffleSettingsViewController.h
//  LoopMusic
//
//  Created by Cheng Hann Gan on 9/19/18.
//  Copyright © 2018 Cheng Hann Gan. All rights reserved.
//

#ifndef ShuffleSettingsViewController_h
#define ShuffleSettingsViewController_h

#import "LoopMusicViewController.h"

@interface ShuffleSettingsViewController : LoopMusicViewController
{
    /// Text field to change the primary setting for shuffling tracks.
    IBOutlet UITextField *mainShuffleSetting;
    /// Text field to change the time variance setting for shuffling tracks.
    IBOutlet UITextField *varianceSetting;
    /// Text field to change the minimum secondary setting for shuffling tracks.
    IBOutlet UITextField *minShuffleSetting;
    /// Text field to change the maximum secondary setting for shuffling tracks.
    IBOutlet UITextField *maxShuffleSetting;
    /// Label for the primary shuffle setting text field.
    IBOutlet UILabel *mainShuffleLabel;
    /// Label for the shuffle variance text field.
    IBOutlet UILabel *varianceLabel;
    /// Label for the minimum secondary shuffle setting text field.
    IBOutlet UILabel *minShuffleLabel;
    /// Label for the maximum secondary shuffle setting text field.
    IBOutlet UILabel *maxShuffleLabel;
    /// Buttons to choose how to shuffle tracks.
    IBOutlet UISegmentedControl *shuffleSegment;
    /// The main screen of the app.
    LoopMusicViewController *presenter;
    /// The currently active mode of shuffling. Used to save the previous shuffle mode's settings when changing modes.
    NSInteger shuffleMode;
}

/// Text field to change the primary setting for shuffling tracks.
@property(nonatomic, retain) UITextField *mainShuffleSetting;
/// Text field to change the time variance setting for shuffling tracks.
@property(nonatomic, retain) UITextField *varianceSetting;
/// Text field to change the minimum secondary setting for shuffling tracks.
@property(nonatomic, retain) UITextField *minShuffleSetting;
/// Text field to change the maximum secondary setting for shuffling tracks.
@property(nonatomic, retain) UITextField *maxShuffleSetting;
/// Label for the primary shuffle setting text field.
@property(nonatomic, retain) UILabel *mainShuffleLabel;
/// Label for the shuffle variance text field.
@property(nonatomic, retain) UILabel *varianceLabel;
/// Label for the minimum secondary shuffle setting text field.
@property(nonatomic, retain) UILabel *minShuffleLabel;
/// Label for the maximum secondary shuffle setting text field.
@property(nonatomic, retain) UILabel *maxShuffleLabel;
/// Buttons to choose how to shuffle tracks.
@property(nonatomic, retain) UISegmentedControl *shuffleSegment;

/*!
 * Navigates back to the main screen and saves the settings.
 * @param sender The object that called this function.
 */
- (IBAction)back:(id)sender;
/*!
 * Sets the primary setting for shuffling tracks.
 * @param sender The object that called this function.
 */
- (IBAction)setMainShuffle:(id)sender;
/*!
 * Sets the time variance for shuffling tracks.
 * @param sender The object that called this function.
 */
- (IBAction)setVarianceShuffle:(id)sender;
/*!
 * Sets the minimum secondary setting for shuffling tracks.
 * @param sender The object that called this function.
 */
- (IBAction)setMinShuffle:(id)sender;
/*!
 * Sets the maximum secondary setting for shuffling tracks.
 * @param sender The object that called this function.
 */
- (IBAction)setMaxShuffle:(id)sender;
/*!
 * Changes how to shuffle tracks.
 * @param sender The object that called this function.
 */
- (IBAction)shuffleChange:(id)sender;

@end

#endif /* ShuffleSettingsViewController_h */
