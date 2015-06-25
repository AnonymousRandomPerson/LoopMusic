//
//  LoopFinderViewController.m
//  LoopMusic
//
//  Created by Cheng Hann Gan on 6/16/14.
//  Copyright (c) 2014 Cheng Hann Gan. All rights reserved.
//

#import "LoopFinderViewController.h"

@interface LoopFinderViewController ()

@end

@implementation LoopFinderViewController

@synthesize setCurrentTime, finderSongName, finderSetTime, finderSetTimeEnd;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

- (void)viewDidLoad
{
    [self openDB];
    sqlite3_open(dbPath, &trackData);
    
    finderSetTime.text = [NSString stringWithFormat:@"%f", loopTime];
    finderSetTimeEnd.text = [NSString stringWithFormat:@"%f", loopEnd];
    NSTimer *loadTimer = [NSTimer scheduledTimerWithTimeInterval:.1
                                                          target:self
                                                        selector:@selector(loadSettings:)
                                                        userInfo:nil
                                                         repeats:NO];
}

-(void)loadSettings:(NSTimer*)loadTimer
{
    presenter = (LoopMusicViewController*)(self.presentingViewController).presentingViewController;
    finderSongName.text = [presenter getSongName];
}

-(IBAction)setCurrentTime:(id)sender
{
    if ([setCurrentTime.text isEqual:@""]  || [setCurrentTime.text doubleValue] > [presenter getAudioDuration])
    {
        setCurrentTime.text = @"";
        return;
    }
    [presenter setCurrentTime:[setCurrentTime.text doubleValue]];
}

-(IBAction)testTime:(id)sender
{
    [presenter testTime];
}

-(IBAction)finderSetTime:(id)sender
{
    if ([finderSetTime.text doubleValue] >= loopEnd || [finderSetTime.text doubleValue] < 0 || [finderSetTime.text isEqual:@""])
    {
        finderSetTime.text = [NSString stringWithFormat:@"%f", loopTime];
        return;
    }
    [presenter setLoopTime:[finderSetTime.text doubleValue]];
    [self sqliteUpdate:@"loopstart" newTime:loopTime];
}

-(IBAction)finderSetTimeEnd:(id)sender
{
    if ([finderSetTimeEnd.text doubleValue] <= loopTime || [finderSetTimeEnd.text isEqual:@""])
    {
        finderSetTimeEnd.text = [NSString stringWithFormat:@"%f", loopEnd];
        return;
    }
    if ([finderSetTimeEnd.text doubleValue] > [presenter getAudioDuration])
    {
        finderSetTimeEnd.text = [NSString stringWithFormat:@"%f", [presenter getAudioDuration]];
    }
    loopEnd = [finderSetTimeEnd.text doubleValue];
    [self sqliteUpdate:@"loopend" newTime:loopEnd];
}

-(IBAction)finderAddTime:(id)sender
{
    if (loopTime >= loopEnd-.001)
    {
        return;
    }
    [self sqliteUpdate:@"loopstart" newTime:loopTime+.001];
    finderSetTime.text = [NSString stringWithFormat:@"%f", loopTime];
}

-(IBAction)finderAddTimeEnd:(id)sender
{
    if (loopEnd >= [presenter getAudioDuration])
    {
        return;
    }
    loopEnd += .001;
    [self sqliteUpdate:@"loopend" newTime:loopEnd];
    finderSetTimeEnd.text = [NSString stringWithFormat:@"%f", loopEnd];
}

-(IBAction)finderSubtractTime:(id)sender
{
    if (loopTime <= 0)
    {
        return;
    }
    [self sqliteUpdate:@"loopstart" newTime:loopTime-.001];
    finderSetTime.text = [NSString stringWithFormat:@"%f", loopTime];
}

-(IBAction)finderSubtractTimeEnd:(id)sender
{
    if (loopEnd <= loopTime + .001)
    {
        return;
    }
    loopEnd -= .001;
    [self sqliteUpdate:@"loopend" newTime:loopEnd];
    finderSetTimeEnd.text = [NSString stringWithFormat:@"%f", loopEnd];
}

-(NSInteger)sqliteUpdate:(NSString*)field1 newTime:(double)newTime
{
    NSInteger result = 0;
    if ([field1 isEqual: @"loopstart"])
    {
        result = [presenter setLoopTime:newTime];
    }
    else
    {
        result = [self updateDBResult:[NSString stringWithFormat:@"UPDATE Tracks SET %@ = %f WHERE name = \"%@\"", field1, newTime, settingsSongString]];
    }
    if (result != 101)
    {
        if (NSClassFromString(@"UIAlertController"))
        {
            UIAlertController *error = [UIAlertController alertControllerWithTitle:@"Error"
                                                                           message:[NSString stringWithFormat:@"Failed to update database (%li). Restart the app.", (long)result]
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Damn", @"OK action")
                                                                    style:UIAlertActionStyleDefault
                                                                  handler:nil];
            [error addAction:defaultAction];
            [self presentViewController:error animated:YES completion:nil];
        }
        else
        {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:[NSString stringWithFormat:@"Failed to update database (%li). Restart the app.", (long)result]
                                                           delegate:self
                                                  cancelButtonTitle:@"Damn"
                                                  otherButtonTitles: nil];
            [alert show];
        }
    }
    return result;
}

-(IBAction)setTimeButton:(id)sender
{
    if ([findTimeText.text isEqual: @"Time"])
    {
        return;
    }
    finderSetTime.text = findTimeText.text;
    [self finderSetTime:self];
}

-(IBAction)setEndButton:(id)sender
{
    if ([findTimeText.text isEqual: @"Time"])
    {
        return;
    }
    finderSetTimeEnd.text = findTimeText.text;
    [self finderSetTimeEnd:self];
}

-(IBAction)findTime:(id)sender
{
    findTimeText.text = [NSString stringWithFormat:@"%f", [presenter findTime] + [presenter getDelay]];
}

-(IBAction)close:(id)sender
{
    [finderSetTime resignFirstResponder];
    [finderSetTimeEnd resignFirstResponder];
    [setCurrentTime resignFirstResponder];
}

-(IBAction)back:(id)sender
{
    [(SettingsViewController*)self.presentingViewController returned];
    [super back:sender];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
