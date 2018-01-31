//
//  LoopFinderViewController.h
//  LoopMusic
//
//  Created by Cheng Hann Gan on 6/16/14.
//  Copyright (c) 2014 Cheng Hann Gan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SettingsViewController.h"

@interface LoopFinderViewController : LoopMusicViewController
{
    /// Text field to change the playback time of the current track.
    IBOutlet UITextField *setCurrentTime;
    /// Text field to change the loop start time of the current track.
    IBOutlet UITextField *finderSetTime;
    /// Text field to change the loop end time of the current track.
    IBOutlet UITextField *finderSetTimeEnd;
    /// Label displaying the most recently found playback time.
    IBOutlet UILabel *findTimeText;
    
    /// Name of the current track being looped.
    NSString *finderSongName;
    
    /// The main screen of the app.
    LoopMusicViewController *presenter;
    
    /// Loop start points that have been found.
    NSMutableArray *foundPoints;
    /// The index of the found point being looked at.
    NSUInteger pointIndex;
    /// The sorting descriptor for the point array.
    NSArray *pointSorter;
}

/// Text field to change the playback time of the current track.
@property(nonatomic, retain) UITextField *setCurrentTime;
/// Text field to change the loop start time of the current track.
@property(nonatomic, retain) UITextField *finderSetTime;
/// Text field to change the loop end time of the current track.
@property(nonatomic, retain) UITextField *finderSetTimeEnd;
/// Name of the current track being looped.
@property(strong, nonatomic) NSString *finderSongName;


// Helpers for communication with the parent view controller.
/*!
 * Reads in the main screen and sets up relevant info.
 * @param presenterPtr The pointer to the main screen.
 * @return
 */
- (void)loadPresenter:(LoopMusicViewController *)presenterPtr;
/*!
 * Empties the borrowed pointer to the main screen.
 * @return
 */
- (void)unloadPresenter;


/*!
 * Sets the playback time of the current track.
 * @param sender The object that called this function.
 * @return
 */
- (IBAction)setCurrentTime:(id)sender;
/*!
 * Sets the playback time to five seconds before the loop time.
 * @param sender The object that called this function.
 * @return
 */
- (IBAction)testTime:(id)sender;
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
 * Moves the loop start time of the current track ahead by 0.001 if possible.
 * @param sender The object that called this function.
 * @return
 */
- (IBAction)finderAddTime:(id)sender;
/*!
 * Moves the loop end time of the current track ahead by 0.001 if possible.
 * @param sender The object that called this function.
 * @return
 */
- (IBAction)finderAddTimeEnd:(id)sender;
/*!
 * Moves the loop start time of the current track back by 0.001 if possible.
 * @param sender The object that called this function.
 * @return
 */
- (IBAction)finderSubtractTime:(id)sender;
/*!
 * Moves the loop end time of the current track back by 0.001 if possible.
 * @param sender The object that called this function.
 * @return
 */
- (IBAction)finderSubtractTimeEnd:(id)sender;
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
/*!
 * Gets the playback time of the current track.
 * @param sender The object that called this function.
 * @return The playback time of the current track.
 */
- (IBAction)findTime:(id)sender;
/*!
 * Finds a suitable start time to loop to.
 * @param sender The object that called this function.
 * @return
 */
- (IBAction)findLoopTime:(id)sender;
/*!
 * Cleans up UI elements when the screen is closing.
 * @param sender The object that called this function.
 * @return
 */
- (IBAction)close:(id)sender;

@end
