//
//  LooperParentViewController.h
//  LoopMusic
//
//  Created by Johann Gan on 1/21/18.
//  Copyright © 2018 Cheng Hann Gan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LoopMusicViewController.h"
#import "LooperAutoViewController.h"
#import "LooperManualViewController.h"

/// Parent view controller for automatic and manual loop-finder GUIs.
@interface LooperParentViewController : UIViewController
{
    /// Segmented control for picking the loop mode.
    IBOutlet UISegmentedControl *modePicker;
    /// Label displaying the name of the current track.
    IBOutlet UILabel *songName;
    
    /// Child for automatic loop-finding mode.
    LooperAutoViewController *childAuto;
    /// Child for manual loop-finding mode.
    LooperManualViewController *childManual;
    
    /// The main screen of the app. To be passed along to child view controllers.
    LoopMusicViewController *presenter;
    
    /// Current loop mode (auto = 0, manual = 1).
    NSInteger loopMode;
}

/// Segmented control for picking the loop mode.
@property(strong, nonatomic) IBOutlet UISegmentedControl *modePicker;
/// Label displaying the name of the current track.
@property(nonatomic, retain) UILabel *songName;
/// View of the container to hold child view controllers.
@property(weak, nonatomic) IBOutlet UIView *containerView;
/// Current child view controller being displayed.
@property(weak, nonatomic) UIViewController *currentViewController;


/*!
 * Sets the current loop-finding mode.
 * @param sender The object that called this function.
 * @return
 */
- (IBAction)setMode:(id)sender;

// Helpers for view changing.

/*!
 * Navigates to the main screen.
 * @param sender The object that called this function.
 * @return
 */
- (IBAction)back:(id)sender;

/*!
 * Adds a child view as a subview to a parent view.
 * @param subView The subview to be added.
 * @param parentView The parent view to be added to.
 * @return
 */
- (void)addSubview:(UIView *)subView toView:(UIView *)parentView;
/*!
 * Switches from one child view controller to another.
 * @param oldVC The old view controller.
 * @param newVC The new view controller.
 * @return
 */
- (void)cycleFromVC:(UIViewController *)oldVC toVC:(UIViewController *)newVC;


@end
