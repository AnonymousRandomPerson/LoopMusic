//
//  LoopFinderAutoViewController.h
//  LoopMusic
//
//  Created by Johann Gan on 1/21/18.
//  Copyright © 2018 Cheng Hann Gan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LoopMusicViewController.h"

@interface LoopFinderAutoViewController : UIViewController
{
    /// Switch for toggling using initial estimates.
    IBOutlet UISwitch *estimateToggler;
    /// Whether initial estimates are enabled or not.
    bool useEstimates;
    /// Subview of initial estimates.
    IBOutlet UIView *initialEstimateView;
    /// Current initial start time estimate. -1 is a flag for nothing.
    double startEst;
    /// Current initial end time estimate. -1 is a flag for nothing.
    double endEst;
    
    
    /// Subview of loop durations results.
    IBOutlet UIView *loopDurationView;
    /// Subview of loop endpoint results.
    IBOutlet UIView *loopEndpointView;
    
    /// Results from the loop finding algorithm.
    NSDictionary *loopFinderResults;
    
    /// Rank for the current base lag value from the results being displayed.
    NSInteger lagRank;
    /// Rank for the current sample pair corresponding to the current base lag value from the results being displayed.
    NSInteger pairRank;
    
    // TRY CHANGING THIS TO BE A POINTER TO THE PARENT VIEW CONTROLLER, WHICH HANDLES COMMUNICATION WITH THE MAIN SCREEN.
    LoopMusicViewController *presenter;
}

@property(strong, nonatomic) IBOutlet UISwitch *estimateToggler;
@property(strong, nonatomic) IBOutlet UIView *initialEstimateView;
@property(strong, nonatomic) IBOutlet UIView *loopDurationView;
@property(strong, nonatomic) IBOutlet UIView *loopEndpointView;


/*!
 * Finds loops for the current song.
 * @param sender The object that called this function.
 * @return
 */
- (IBAction)findLoop:(id)sender;

/*!
 * Updates the text field of a UI object in a subview.
 * @param subview The subview containing the UI object.
 * @param tag The tag of the UI object within the subview.
 * @param text The text with which to update the UI object.
 * @return
 */
- (void)updateText:(UIView *)subview :(NSInteger)tag :(NSString *)text;

/*!
 * Enables the usage of initial estimates in loop finding.
 * @return
 */
- (void)enableEstimates;
/*!
 * Disables the usage of initial estimates in loop finding.
 * @return
 */
- (void)disableEstimates;

/*!
 * Toggles the usage of initial estimates in loop finding.
 * @param sender The object that called this function.
 * @return
 */
- (IBAction)toggleEstimates:(id)sender;
/*!
 * Sets the initial start estimate if possible.
 * @param est The initial estimate to attempt to set.
 * @return
 */
- (void)setStartEstimate:(double)est;
/*!
 * Resets the initial start estimate to empty (-1).
 * @return
 */
- (void)resetStartEstimate;
/*!
 * Sets the initial end estimate if possible.
 * @param est The initial estimate to attempt to set.
 * @return
 */
- (void)setEndEstimate:(double)est;
/*!
 * Resets the initial end estimate to empty (-1).
 * @return
 */
- (void)resetEndEstimate;
/*!
 * Increments the initial start time estimate by 1 ms if possible.
 * @param sender The object that called this function.
 * @return
 */
- (IBAction)incStartEst:(id)sender;
/*!
 * Decrements the initial start time estimate by 1 ms if possible.
 * @param sender The object that called this function.
 * @return
 */
- (IBAction)decStartEst:(id)sender;
/*!
 * Increments the initial end time estimate by 1 ms of possible.
 * @param sender The object that called this function.
 * @return
 */
- (IBAction)incEndEst:(id)sender;
/*!
 * Decrements the initial end time estimate by 1 ms of possible.
 * @param sender The object that called this function.
 * @return
 */
- (IBAction)decEndEst:(id)sender;

/*!
 * Updates the initial start time estimate using user input.
 * @param sender The object that called this function.
 * @return
 */
- (IBAction)updateStartEstValueChanged:(id)sender;
/*!
 * Updates the initial end time estimate using user input.
 * @param sender The object that called this function.
 * @return
 */
- (IBAction)updateEndEstValueChanged:(id)sender;

// Test loop function

/*!
 * Opens the advanced options menu
 * @param sender The object that called this function.
 * @return
 */
- (IBAction)openAdvancedOptions:(id)sender;

/*!
 * Resets the results display back to the initial loop point.
 * @param sender The object that called this function.
 * @return
 */
- (IBAction)revertOriginalLoop:(id)sender;
/*!
 * Changes to the next best result for loop duration.
 * @param sender The object that called this function.
 * @return
 */
- (IBAction)nextDuration:(id)sender;
/*!
 * Changes to the previous best result for loop duration.
 * @param sender The object that called this function.
 * @return
 */
- (IBAction)prevDuration:(id)sender;
/*!
 * Changes to the next best subresult for loop endpoints under the current loop duration.
 * @param sender The object that called this function.
 * @return
 */
- (IBAction)nextEndpoints:(id)sender;
/*!
 * Changes to the previous best subresult for loop endpoints under the current loop duration.
 * @param sender The object that called this function.
 * @return
 */
- (IBAction)prevEndpoints:(id)sender;

// Parameter setting functions


/*!
 * Cleans up UI elements for initial estimates when the screen is closing.
 * @param sender The object that called this function.
 * @return
 */
- (IBAction)closeEstimates:(id)sender;


@end
