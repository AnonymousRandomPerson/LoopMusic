//
//  LooperViewController.h
//  LoopMusic
//
//  Created by Johann Gan on 2/4/18.
//  Copyright © 2018 Cheng Hann Gan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UILoopSlider.h"
#import "LoopMusicViewController.h"

/// Base class for the LooperAutoViewConroller and LooperManualViewController.
@interface LooperViewController : UIViewController
{
    /// The main screen of the app.
    LoopMusicViewController *presenter;
    
    /// The slider of the parent view
    UILoopSlider *playSlider;
}


// Helpers for communication with the parent view controller.
/*!
 * Reads in the main screen and sets up relevant info.
 * @param presenterPtr The pointer to the main screen.
 */
- (void)loadPresenter:(LoopMusicViewController *)presenterPtr;
/*!
 * Reads in the play slider.
 * @param sliderPtr The pointer to the play slider.
 */
- (void)loadPlaySlider:(UILoopSlider *)sliderPtr;

/*!
 * Empties the borrowed pointer to the main screen.
 */
- (void)unloadPresenter;
/*!
 * Empties the borrowed pointer to the play slider.
 */
- (void)unloadPlaySlider;


// Helpers for loop setting.
/*!
 * Sets the loop start point.
 * @param loopStart The new loop start point.
 */
- (void)setLoopStart:(NSTimeInterval)loopStart;
/*!
 * Sets the loop end point.
 * @param loopEnd The new loop end point.
 */
- (void)setLoopEnd:(NSTimeInterval)loopEnd;
/*!
 * Sets the playback time of the current track.
 * @param time The time to set playback to.
 */
- (void)setCurrentTime:(NSTimeInterval)time;



@end
