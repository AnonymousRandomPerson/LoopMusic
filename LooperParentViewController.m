//
//  LooperParentViewController.m
//  LoopMusic
//
//  Created by Johann Gan on 1/21/18.
//  Copyright © 2018 Cheng Hann Gan. All rights reserved.
//

#import "LooperParentViewController.h"

@implementation LooperParentViewController

@synthesize modePicker, songName, containerView, currentViewController, playSlider;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    childAuto = [self.storyboard instantiateViewControllerWithIdentifier:@"looperAuto"];
    childManual = [self.storyboard instantiateViewControllerWithIdentifier:@"looperManual"];
    childAuto.view.translatesAutoresizingMaskIntoConstraints = NO;
    childManual.view.translatesAutoresizingMaskIntoConstraints = NO;
    
    // Default to automatic mode.
    loopMode = 0;
    self.currentViewController = childAuto;
    [self addChildViewController:self.currentViewController];
    [self addSubview:self.currentViewController.view toView:self.containerView];
    
    // Set defaults for play slider.
    [playSlider useDefaultParameters];
    
    // Load the main screen of the app.
    /// Timer to load the current track name and the main screen of the app.
    [NSTimer scheduledTimerWithTimeInterval:.1
                                     target:self
                                   selector:@selector(loadMainScreen:)
                                   userInfo:nil
                                    repeats:NO];
}

- (void)loadMainScreen:(NSTimer*)loadTimer
{
    presenter = (LoopMusicViewController*)(self.presentingViewController);
    [presenter setOccupied:true];
    songName.text = [presenter getSongName];
    
    // LooperViewController already opens/closes DB with each update
//    [presenter openDB];
    
    // Load the presenter and play slider into the current view controller
    if (!loopMode)
    {
        [childAuto loadPresenter:presenter];
        [childAuto loadPlaySlider:playSlider];
    }
    else
    {
        [childManual loadPresenter:presenter];
        [childManual loadPlaySlider:playSlider];
    }
    
    [childAuto loadFFTSetup:presenter.fftSetup :presenter.nSetup];
    
    // Copy over the settings from the main play slider and start the timer.
    [playSlider copySettingsFromSlider:presenter.playSlider];
    [self activateSliderUpdateTimer];
}

/*!
 * Conditionally activate the play slider's update timer if the audio player is playing.
 */
- (void)activateSliderUpdateTimer
{
    if ([presenter isPlaying])
        [playSlider activateUpdateTimer];
}

- (IBAction)back:(id)sender
{
    // LooperViewController already opens/closes DB with each update
//    [presenter closeDB];
    [childAuto saveFFTSetup:presenter];
    [presenter setOccupied:false];
    [presenter back:sender];
}


- (IBAction)setMode:(id)sender
{
    // 0 = auto, 1 = manual.
    switch (self.modePicker.selectedSegmentIndex)
    {
        case 0:
            [childManual unloadPresenter];
            [childManual unloadPlaySlider];
            [childAuto loadPresenter:presenter];
            [childAuto loadPlaySlider:playSlider];
            [self cycleFromVC:self.currentViewController toVC:childAuto];
            self.currentViewController = childAuto;
            break;
        case 1:
            [childAuto unloadPresenter];
            [childAuto unloadPlaySlider];
            [childManual loadPresenter:presenter];
            [childManual loadPlaySlider:playSlider];
            [self cycleFromVC:self.currentViewController toVC:childManual];
            self.currentViewController = childManual;
            break;
        default:
            NSLog(@"DEFAULT for setMode. If this message is seen, something went wrong.");
            break;
    }
}


// Helpers for view changing.

- (void)addSubview:(UIView *)subView toView:(UIView *)parentView
{
    [parentView addSubview:subView];
    
    // Lock the subView dimensions to the parentView dimensions.
    NSDictionary * views = @{@"subView" : subView};
    NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[subView]|" options:0 metrics:0 views:views];
    [parentView addConstraints:constraints];
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[subView]|" options:0 metrics:0 views:views];
    [parentView addConstraints:constraints];
}

- (void)cycleFromVC:(UIViewController *)oldVC toVC:(UIViewController *)newVC
{
    [oldVC willMoveToParentViewController:nil];
    [self addChildViewController:newVC];
    [self addSubview:newVC.view toView:self.containerView];
    [newVC.view layoutIfNeeded];
    
    [oldVC.view removeFromSuperview];
    [oldVC removeFromParentViewController];
    [newVC didMoveToParentViewController:self];
}


- (IBAction)testTime:(id)sender
{
    [presenter testTime];
    [playSlider setTime:playSlider.getCurrentTime()];
    [self activateSliderUpdateTimer];
}

- (IBAction)playSliderTouchDown:(id)sender
{
    [playSlider stopUpdateTimer];
}
- (IBAction)playSliderTouchUp:(id)sender
{
    if ([presenter isPlaying])
        [playSlider activateUpdateTimer];
}
- (IBAction)playSliderUpdate:(id)sender
{
    [playSlider updateAudioPlayer:[presenter valueForKey:@"audioPlayer"]]; // Update the audio player time. Forcibly access the audioPlayer just for this purpose.
}

@end
