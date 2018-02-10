//
//  LooperAutoViewController.h
//  LoopMusic
//
//  Created by Johann Gan on 1/21/18.
//  Copyright © 2018 Cheng Hann Gan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LooperViewController.h"
#import "LoopFinderAuto.h"
#import "LooperSettingsMenuTableViewController.h"

enum initialEstimateViewTags
{
    startEstimateTextField = 1,
    endEstimateTextField = 2,
    startEstimateDecrementButton = 3,
    startEstimateIncrementButton = 4,
    endEstimateDecrementButton = 5,
    endEstimateIncrementButton = 6,
    startEstimateLabel = 7,
    endEstimateLabel = 8
};

enum loopDurationViewTags
{
    previousDurationButton = 1,
    nextDurationButton = 2,
    durationRankLabel = 3,
    durationConfidenceLabel = 4,
    durationLabel = 5
};

enum loopEndpointsViewTags
{
    previousEndpointsButton = 1,
    nextEndpointsButton = 2,
    endpointsRankLabel = 3,
    startEndpointLabel = 4,
    endEndpointLabel = 5
};

@interface LooperAutoViewController : LooperViewController
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
    
    /// Original loop point information. Contains keys "duration", "startFrame", and "endFrame". All quantities are in frames.
    NSDictionary *originalLoopInfo;
    /// Results from the loop finding algorithm. See LoopFinderAuto::findLoop() documentation for details on format.
    NSDictionary *loopFinderResults;
    /// Ranks of the current duration value being displayed. -1 means display the original loop info.
    NSInteger currentDurationRank;
    /// Ranks of the current pair to display for each duration value in loopFinderResults
    NSMutableArray *currentPairRanks;
}

@property(strong, nonatomic) IBOutlet UISwitch *estimateToggler;
@property(strong, nonatomic) IBOutlet UIView *initialEstimateView;
@property(strong, nonatomic) IBOutlet UIView *loopDurationView;
@property(strong, nonatomic) IBOutlet UIView *loopEndpointView;
/// The loop finder.
@property(strong, nonatomic) LoopFinderAuto *finder;


/*!
 * Finds loops for the current song.
 * @param sender The object that called this function.
 * @return
 */
- (IBAction)findLoop:(id)sender;

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
//- (IBAction)openAdvancedOptions:(id)sender;

/*!
 * Resets the results display back to the initial loop point.
 * @param sender The object that called this function.
 * @return
 */
- (IBAction)revertOriginalLoop:(id)sender;
/*!
 * Changes to the previous best result for loop duration.
 * @param sender The object that called this function.
 * @return
 */
- (IBAction)prevDuration:(id)sender;
/*!
 * Changes to the next best result for loop duration.
 * @param sender The object that called this function.
 * @return
 */
- (IBAction)nextDuration:(id)sender;
/*!
 * Changes to the previous best subresult for loop endpoints under the current loop duration.
 * @param sender The object that called this function.
 * @return
 */
- (IBAction)prevEndpoints:(id)sender;
/*!
 * Changes to the next best subresult for loop endpoints under the current loop duration.
 * @param sender The object that called this function.
 * @return
 */
- (IBAction)nextEndpoints:(id)sender;


/*!
 * Cleans up UI elements for initial estimates when the screen is closing.
 * @param sender The object that called this function.
 * @return
 */
- (IBAction)closeEstimates:(id)sender;


@end
