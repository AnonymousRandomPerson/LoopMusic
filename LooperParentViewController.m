//
//  LooperParentViewController.m
//  LoopMusic
//
//  Created by Johann Gan on 1/21/18.
//  Copyright © 2018 Cheng Hann Gan. All rights reserved.
//

#import "LooperParentViewController.h"

@implementation LooperParentViewController

@synthesize modePicker, songName, containerView, currentViewController;

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
    
    // Load the presenter into the current view controller
    if (!loopMode)
    {
        [childAuto loadPresenter:presenter];
    }
    else
    {
        [childManual loadPresenter:presenter];
    }
}

- (IBAction)back:(id)sender
{
    // LooperViewController already opens/closes DB with each update
//    [presenter closeDB];
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
            [childAuto loadPresenter:presenter];
            [self cycleFromVC:self.currentViewController toVC:childAuto];
            self.currentViewController = childAuto;
            break;
        case 1:
            [childAuto unloadPresenter];
            [childManual loadPresenter:presenter];
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

@end
