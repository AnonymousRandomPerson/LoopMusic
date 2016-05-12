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
    
    /// Timer to load the current track name and the main screen of the app.
    [NSTimer scheduledTimerWithTimeInterval:.1
                                     target:self
                                   selector:@selector(loadSettings:)
                                   userInfo:nil
                                    repeats:NO];
}

/*!
 * Loads the current track name and the main screen of the app.
 * @param loadTimer The timer that called this function.
 * @return
 */
- (void)loadSettings:(NSTimer*)loadTimer
{
    presenter = (LoopMusicViewController*)(self.presentingViewController);
    audioPlayer = presenter->audioPlayer;
    finderSetTime.text = [NSString stringWithFormat:@"%f", audioPlayer.loopStart];
    finderSetTimeEnd.text = [NSString stringWithFormat:@"%f", audioPlayer.loopEnd];
    finderSongName.text = [presenter getSongName];
}

- (IBAction)setCurrentTime:(id)sender
{
    if ([setCurrentTime.text isEqual:@""]  || [setCurrentTime.text doubleValue] > [presenter getAudioDuration])
    {
        setCurrentTime.text = @"";
        return;
    }
    [presenter setCurrentTime:[setCurrentTime.text doubleValue]];
}

- (IBAction)testTime:(id)sender
{
    [presenter testTime];
}

- (IBAction)finderSetTime:(id)sender
{
    if ([finderSetTime.text doubleValue] >= audioPlayer.loopEnd || [finderSetTime.text doubleValue] < 0 || [finderSetTime.text isEqual:@""])
    {
        finderSetTime.text = [NSString stringWithFormat:@"%f", audioPlayer.loopStart];
        return;
    }
    [presenter setLoopTime:[finderSetTime.text doubleValue]];
    [self sqliteUpdate:@"loopstart" newTime:audioPlayer.loopStart];
}

- (IBAction)finderSetTimeEnd:(id)sender
{
    if ([finderSetTimeEnd.text doubleValue] <= audioPlayer.loopStart || [finderSetTimeEnd.text isEqual:@""])
    {
        finderSetTimeEnd.text = [NSString stringWithFormat:@"%f", audioPlayer.loopEnd];
        return;
    }
    if ([finderSetTimeEnd.text doubleValue] > [presenter getAudioDuration])
    {
        finderSetTimeEnd.text = [NSString stringWithFormat:@"%f", [presenter getAudioDuration]];
    }
    audioPlayer.loopEnd = [finderSetTimeEnd.text doubleValue];
    [self sqliteUpdate:@"loopend" newTime:audioPlayer.loopEnd];
}

- (IBAction)finderAddTime:(id)sender
{
    if (audioPlayer.loopStart >= audioPlayer.loopEnd - 0.001)
    {
        return;
    }
    [self sqliteUpdate:@"loopstart" newTime:audioPlayer.loopStart + 0.001];
    finderSetTime.text = [NSString stringWithFormat:@"%f", audioPlayer.loopStart];
}

- (IBAction)finderAddTimeEnd:(id)sender
{
    if (audioPlayer.loopEnd >= [presenter getAudioDuration])
    {
        return;
    }
    audioPlayer.loopEnd += 0.001;
    [self sqliteUpdate:@"loopend" newTime:audioPlayer.loopEnd];
    finderSetTimeEnd.text = [NSString stringWithFormat:@"%f", audioPlayer.loopEnd];
}

- (IBAction)finderSubtractTime:(id)sender
{
    if (audioPlayer.loopStart <= 0)
    {
        return;
    }
    [self sqliteUpdate:@"loopstart" newTime:audioPlayer.loopStart - 0.001];
    finderSetTime.text = [NSString stringWithFormat:@"%f", audioPlayer.loopStart];
}

- (IBAction)finderSubtractTimeEnd:(id)sender
{
    if (audioPlayer.loopEnd <= audioPlayer.loopStart + 0.001)
    {
        return;
    }
    audioPlayer.loopEnd -= 0.001;
    [self sqliteUpdate:@"loopend" newTime:audioPlayer.loopEnd];
    finderSetTimeEnd.text = [NSString stringWithFormat:@"%f", audioPlayer.loopEnd];
}

/*!
 * Updates the current track's entry in the database.
 * @param field1 The field to update.
 * @param newTime The new value to insert in the field.
 * @return The result code of the database query.
 */
- (NSInteger)sqliteUpdate:(NSString*)field1 newTime:(double)newTime
{
    /// The result code of the database query.
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
        [self showErrorMessage:[NSString stringWithFormat:@"Failed to update database (%li). Restart the app.", (long)result]];
    }
    return result;
}

- (IBAction)setTimeButton:(id)sender
{
    if ([findTimeText.text isEqual: @"Time"])
    {
        return;
    }
    finderSetTime.text = findTimeText.text;
    [self finderSetTime:self];
}

- (IBAction)setEndButton:(id)sender
{
    if ([findTimeText.text isEqual: @"Time"])
    {
        return;
    }
    finderSetTimeEnd.text = findTimeText.text;
    [self finderSetTimeEnd:self];
}

- (IBAction)findTime:(id)sender
{
    findTimeText.text = [NSString stringWithFormat:@"%f", [presenter findTime]];
}

- (IBAction)findLoopTime:(id)sender
{
    NSTimeInterval foundTime = [audioPlayer findLoopTime];
    if (foundTime == -1)
    {
        [self showErrorMessage:@"No suitable loop start times were found."];
    }
    else
    {
        finderSetTime.text = [NSString stringWithFormat:@"%f", foundTime];
        [presenter setLoopTime:foundTime];
        [self sqliteUpdate:@"loopstart" newTime:foundTime];
    }
}

- (IBAction)close:(id)sender
{
    [finderSetTime resignFirstResponder];
    [finderSetTimeEnd resignFirstResponder];
    [setCurrentTime resignFirstResponder];
}

- (IBAction)back:(id)sender
{
    [presenter setOccupied:false];
    [super back:sender];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
