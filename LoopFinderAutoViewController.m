//
//  LoopFinderAutoViewController.m
//  LoopMusic
//
//  Created by Johann Gan on 1/21/18.
//  Copyright © 2018 Cheng Hann Gan. All rights reserved.
//

#import "LoopFinderAutoViewController.h"

@implementation LoopFinderAutoViewController

@synthesize estimateToggler, initialEstimateView, loopDurationView, loopEndpointView;

- (void)viewDidLoad
{
    // Set up subview UI interaction programmatically by their tag within the subview.
    [self setupAllUIObjects];
    
    // Default estimate flags/values
    [self disableEstimates];
    startEst = -1;
    endEst = -1;
}

// Function to set up all the UI objects in subviews
- (void)setupAllUIObjects
{
    [self setupUIObject:initialEstimateView:1:@selector(closeEstimates:):UIControlEventTouchDown];
    [self setupUIObject:initialEstimateView:1:@selector(updateStartEstValueChanged:):UIControlEventEditingDidEnd];
    [self setupUIObject:initialEstimateView:2:@selector(closeEstimates:):UIControlEventTouchDown];
    [self setupUIObject:initialEstimateView:2:@selector(updateEndEstValueChanged:):UIControlEventEditingDidEnd];
    [self setupUIObject:initialEstimateView:3:@selector(decStartEst:):UIControlEventTouchUpInside];
    [self setupUIObject:initialEstimateView:4:@selector(incStartEst:):UIControlEventTouchUpInside];
    [self setupUIObject:initialEstimateView:5:@selector(decEndEst:):UIControlEventTouchUpInside];
    [self setupUIObject:initialEstimateView:6:@selector(incEndEst:):UIControlEventTouchUpInside];
    [self setupUIObject:loopDurationView:1:@selector(prevDuration:):UIControlEventTouchUpInside];
    [self setupUIObject:loopDurationView:2:@selector(nextDuration:):UIControlEventTouchUpInside];
    [self setupUIObject:loopEndpointView:1:@selector(prevEndpoints:):UIControlEventTouchUpInside];
    [self setupUIObject:loopEndpointView:2:@selector(nextEndpoints:):UIControlEventTouchUpInside];
}
// Helper function to set up a UI object in a subview programmatically
- (void)setupUIObject:(UIView *)subview :(NSInteger)tag :(SEL)actionSelector :(UIControlEvents)event
{
    [(UIButton *)[subview viewWithTag:tag] addTarget:self action:actionSelector forControlEvents:event];
}

- (void)updateText:(UIView *)subview :(NSInteger)tag :(NSString *)text
{
    id uiObj = (id)[subview viewWithTag:tag];
    if ([uiObj respondsToSelector:@selector(setText:)])
    {
        [uiObj performSelector:@selector(setText:) withObject:text];
    }
}

- (IBAction)findLoop:(id)sender
{
    loopFinderResults = nil;
    NSLog(@"Loop button pressed!");
}

- (IBAction)toggleEstimates:(id)sender
{
    useEstimates = self.estimateToggler.isOn;
    
    if (useEstimates)
    {
        [self enableEstimates];
    }
    else
    {
        [self disableEstimates];
    }
}
- (void)enableEstimates
{
    initialEstimateView.alpha = 1;
    [initialEstimateView setUserInteractionEnabled:YES];
}
- (void)disableEstimates
{
    initialEstimateView.alpha = 0.25;
    [initialEstimateView setUserInteractionEnabled:NO];
//    [(UITextField *)[initialEstimateView viewWithTag:1] resignFirstResponder];  // Start Time text
//    [(UITextField *)[initialEstimateView viewWithTag:2] resignFirstResponder];  // End Time text
    [self closeEstimates:nil];    // Call closeEstimates outside of an action by just passing nil as the sender.
}
- (void)setStartEstimate:(double)est
{
    // presenter IS NIL RIGHT NOW. Need to figure out how to implement communication with main screen.
    if (est < 0)
    {
        est = 0;
    }
    else if (endEst != -1 && est > endEst)
    {
        est = endEst;
    }
    else if (est > [presenter getAudioDuration])
    {
        est = [presenter getAudioDuration];
    }
    
    startEst = est;
    [self updateText:initialEstimateView :1 :[NSString stringWithFormat:@"%.6f", startEst]];
    NSLog(@"startEst = %f", startEst);
}
- (void)resetStartEstimate
{
    startEst = -1;
    [self updateText:initialEstimateView :1 :@""];
}
- (void)setEndEstimate:(double)est
{
    // presenter IS NIL RIGHT NOW. Need to figure out how to implement communication with main screen.
    if (est < 0)
    {
        est = 0;
    }
    else if (startEst != -1 && est < startEst)
    {
        est = startEst;
    }
    else if (est > [presenter getAudioDuration])
    {
        est = [presenter getAudioDuration];
    }
    
    endEst = est;
    [self updateText:initialEstimateView :2 :[NSString stringWithFormat:@"%.6f", endEst]];
    NSLog(@"endEst = %f", endEst);
}
- (void)resetEndEstimate
{
    endEst = -1;
    [self updateText:initialEstimateView :2 :@""];
}
- (void)incStartEst:(id)sender
{
    NSLog(@"Increment start estimate!");
    [self setStartEstimate:(startEst + 0.001)];
}
- (void)decStartEst:(id)sender
{
    NSLog(@"Decrement start estimate!");
    [self setStartEstimate:(startEst - 0.001)];
}
- (void)incEndEst:(id)sender
{
    NSLog(@"Increment end estimate!");
    if (endEst == -1)
    {
        NSLog(@"Initializing...");
        [self setEndEstimate:[presenter getAudioDuration]];
    }
    else
    {
        [self setEndEstimate:(endEst + 0.001)];
    }
}
- (void)decEndEst:(id)sender
{
    NSLog(@"Decrement end estimate!");
    if (endEst == -1)
    {
        NSLog(@"Initializing...");
        [self setEndEstimate:[presenter getAudioDuration]];
    }
    else
    {
        [self setEndEstimate:(endEst - 0.001)];
    }
}
- (IBAction)updateStartEstValueChanged:(id)sender
{
    NSString *text = ((UITextField *)sender).text;
    NSScanner *scan = [NSScanner scannerWithString:text];
    double doubleVal;
    if ([scan scanDouble:&doubleVal] && [scan isAtEnd])
    {
        NSLog(@"Setting start estimate to %f.", doubleVal);
        [self setStartEstimate:doubleVal];
    }
    else
    {
        // If invalid and not empty, try to fall back on the previous estimate.
        if([text isEqualToString:@""] || startEst == -1)
        {
            NSLog(@"Resetting start estimate.");
            [self resetStartEstimate];
        }
        else
        {
            [self setStartEstimate:startEst];
        }
    }
}
- (IBAction)updateEndEstValueChanged:(id)sender
{
    NSString *text = ((UITextField *)sender).text;
    NSScanner *scan = [NSScanner scannerWithString:text];
    double doubleVal;
    if ([scan scanDouble:&doubleVal] && [scan isAtEnd])
    {
        NSLog(@"Setting end estimate to %f.", doubleVal);
        [self setEndEstimate:doubleVal];
    }
    else
    {
        // If invalid and not empty, try to fall back on the previous estimate.
        if([text isEqualToString:@""] || endEst == -1)
        {
            NSLog(@"Resetting end estimate.");
            [self resetEndEstimate];
        }
        else
        {
            [self setEndEstimate:endEst];
        }
    }
}



- (IBAction)openAdvancedOptions:(id)sender
{
    NSLog(@"Open advanced options!");
}

- (IBAction)revertOriginalLoop:(id)sender
{
    NSLog(@"Original loop!");
}
- (IBAction)nextDuration:(id)sender
{
    NSLog(@"Next duration!");
}
- (IBAction)prevDuration:(id)sender
{
    NSLog(@"Previous duration!");
}
- (IBAction)nextEndpoints:(id)sender
{
    NSLog(@"Next endpoints!");
}
- (IBAction)prevEndpoints:(id)sender
{
    NSLog(@"Previous endpoints!");
}


- (IBAction)closeEstimates:(id)sender
{
    [(UITextField *)[initialEstimateView viewWithTag:1] resignFirstResponder];  // Start Time text
    [(UITextField *)[initialEstimateView viewWithTag:2] resignFirstResponder];  // End Time text
}

@end
