//
//  SettingsViewController.h
//  LoopMusic
//
//  Created by Cheng Hann Gan on 5/24/14.
//  Copyright (c) 2014 Cheng Hann Gan. All rights reserved.
//

#import "LoopMusicViewController.h"

@interface SettingsViewController : LoopMusicViewController <MPMediaPickerControllerDelegate>
{
    /// Button to return to the main screen.
    IBOutlet UIButton *back;
    /// Text field to change the relative volume of the current track.
    IBOutlet UITextField *volumeAdjust;
    /// Text field to change the time taken for a track to fade out.
    IBOutlet UITextField *fadeText;
    /// The main screen of the app.
    LoopMusicViewController *presenter;
    
    /// Whether a track is being added to the app.
    bool addingSong;
    /// Index for deciding which alert message to display.
    NSInteger alertIndex;
}

/// Button to return to the main screen.
@property(nonatomic, retain) UIButton *back;
/// Text field to change the relative volume of the current track.
@property(nonatomic, retain) UITextField *volumeAdjust;
/// Text field to change the time taken for a track to fade out.
@property(nonatomic, retain) UITextField *fadeText;

/*!
 * Navigates back to the main screen and saves the settings.
 * @param sender The object that called this function.
 */
- (IBAction)back:(id)sender;
/*!
 * Sets the relative volume of the current track.
 * @param sender The object that called this function.
 */
- (IBAction)setVolume:(id)sender;
/*!
 * Sets the time taken for a track to fade out.
 * @param sender The object that called this function.
 */
- (IBAction)setFade:(id)sender;
/*!
 * Cleans up UI elements when the screen is closing.
 * @param sender The object that called this function.
 */
- (IBAction)close:(id)sender;
/*!
 * Navigates to the playlist choosing screen.
 * @param sender The object that called this function.
 */
- (IBAction)choosePlaylist:(id)sender;
/*!
 * Navigates to the playlist modification screen.
 * @param sender The object that called this function.
 */
- (IBAction)modifyPlaylist:(id)sender;
/*!
 * Displays a prompt to enter a name for a new playlist.
 * @param sender The object that called this function.
 */
- (IBAction)newPlaylist:(id)sender;
/*!
 * Displays a prompt to enter a new name for the current playlist.
 * @param sender The object that called this function.
 */
- (IBAction)renamePlaylist:(id)sender;
/*!
 * Navigates to the playlist deletion screen.
 * @param sender The object that called this function.
 */
- (IBAction)deletePlaylist:(id)sender;
/*!
 * Navigates to the shuffle setings screen.
 * @param sender The object that called this function.
 */
- (IBAction)openShuffleSettings:(id)sender;

@end
