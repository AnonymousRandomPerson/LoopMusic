//
//  LoopFinderViewController.m
//  LoopMusic
//
//  Created by Cheng Hann Gan on 6/16/14.
//  Copyright (c) 2014 Cheng Hann Gan. All rights reserved.
//

#import "LoopFinderViewController.h"

static const NSTimeInterval LOOPPOINTINCREMENT = 0.001;

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
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:true];
    pointSorter = @[descriptor];
    
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
    [presenter setOccupied:true];
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
    [self setLoopStart:[finderSetTime.text doubleValue]];
}

- (IBAction)finderSetTimeEnd:(id)sender
{
    /// The time that the loop end will be set to.
    NSTimeInterval newTime = [finderSetTimeEnd.text doubleValue];
    if (newTime <= audioPlayer.loopStart || [finderSetTimeEnd.text isEqual:@""])
    {
        finderSetTimeEnd.text = [NSString stringWithFormat:@"%f", audioPlayer.loopEnd];
        return;
    }
    /// The duration of the current track.
    NSTimeInterval duration = [presenter getAudioDuration];
    if (newTime > duration)
    {
        newTime = duration;
    }
    [self setLoopEnd:newTime];
    audioPlayer.loopEnd = [finderSetTimeEnd.text doubleValue];
    [self sqliteUpdate:@"loopend" newTime:audioPlayer.loopEnd];
}

- (IBAction)finderAddTime:(id)sender
{
    NSTimeInterval newTime;
    if (foundPoints)
    {
        if (pointIndex < [foundPoints count] - 1)
        {
            pointIndex++;
            newTime = [self getCurrentPoint];
        }
        else
        {
            newTime = audioPlayer.loopStart;
        }
    }
    else
    {
        newTime = audioPlayer.loopStart + LOOPPOINTINCREMENT;
    }
    if (newTime >= audioPlayer.loopEnd)
    {
        return;
    }
    [self setLoopStart:newTime];
}

- (IBAction)finderAddTimeEnd:(id)sender
{
    if (audioPlayer.loopEnd >= [presenter getAudioDuration])
    {
        return;
    }
    [self setLoopEnd:audioPlayer.loopEnd + LOOPPOINTINCREMENT];
}

- (IBAction)finderSubtractTime:(id)sender
{
    /// The time that the loop start will be set to.
    NSTimeInterval newTime;
    if (foundPoints)
    {
        if (pointIndex > 0)
        {
            pointIndex--;
            newTime = [self getCurrentPoint];
        }
        else
        {
            newTime = audioPlayer.loopStart;
        }
    }
    else
    {
        newTime = audioPlayer.loopStart - LOOPPOINTINCREMENT;
    }
    if (newTime < 0)
    {
        newTime = 0;
    }
    [self setLoopStart:newTime];
}

- (IBAction)finderSubtractTimeEnd:(id)sender
{
    if (audioPlayer.loopEnd <= audioPlayer.loopStart + LOOPPOINTINCREMENT)
    {
        return;
    }
    [self setLoopEnd:audioPlayer.loopEnd - LOOPPOINTINCREMENT];
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
    foundPoints = [audioPlayer findLoopTime];
    if ([foundPoints count] == 0)
    {
        [self showErrorMessage:@"No suitable loop start times were found."];
        foundPoints = nil;
    }
    else
    {
        /// The number closest to the current loop start point.
        NSNumber *closestNumber = (NSNumber *)foundPoints[0];
        /// The point closest to the current loop start point.
        NSTimeInterval closestPoint = [closestNumber doubleValue];
        [self setLoopStart:closestPoint];
        
        [foundPoints sortUsingDescriptors:pointSorter];
        pointIndex = [foundPoints indexOfObject:closestNumber];
        if (pointIndex == NSNotFound)
        {
            pointIndex = [foundPoints count] >> 1;
        }
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
    sqlite3_close(trackData);
    [presenter setOccupied:false];
    [super back:sender];
}

/*!
 * Sets the loop start point.
 * @param loopStart The new loop start point.
 * @return
 */
- (void)setLoopStart:(NSTimeInterval)loopStart
{
    audioPlayer.loopStart = loopStart;
    [self sqliteUpdate:@"loopstart" newTime:audioPlayer.loopStart];
    finderSetTime.text = [NSString stringWithFormat:@"%f", audioPlayer.loopStart];
}

/*!
 * Sets the loop end point.
 * @param loopEnd The new loop end point.
 * @return
 */
- (void)setLoopEnd:(NSTimeInterval)loopEnd
{
    audioPlayer.loopEnd = loopEnd;
    finderSetTimeEnd.text = [NSString stringWithFormat:@"%f", audioPlayer.loopEnd];
    [self sqliteUpdate:@"loopend" newTime:audioPlayer.loopEnd];
    foundPoints = nil;
}

/*!
 * Gets the currently selected loop start point.
 * @return The currently selected loop start point.
 */
- (NSTimeInterval)getCurrentPoint
{
    return [((NSNumber *)foundPoints[pointIndex]) doubleValue];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
