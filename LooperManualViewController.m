//
//  LooperManualViewController.m
//  LoopMusic
//
//  Created by Cheng Hann Gan on 6/16/14.
//  Copyright (c) 2014 Cheng Hann Gan. All rights reserved.
//

#import "LooperManualViewController.h"

static const NSTimeInterval LOOPPOINTINCREMENT = 0.001;

@interface LooperManualViewController ()

@end

@implementation LooperManualViewController

@synthesize setCurrentTime, finderSetTime, finderSetTimeEnd;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

- (void)viewDidLoad
{
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:true];
    pointSorter = @[descriptor];
    
//    [self openDB];
//    sqlite3_open(dbPath, &trackData);
    
    /// Timer to load the current track name and the main screen of the app.
//    [NSTimer scheduledTimerWithTimeInterval:.1
//                                     target:self
//                                   selector:@selector(loadSettings:)
//                                   userInfo:nil
//                                    repeats:NO];
}

/*!
 * Loads the current track name and the main screen of the app.
 * @param loadTimer The timer that called this function.
 * @return
 */
//- (void)loadSettings:(NSTimer*)loadTimer
//{
//    presenter = (LoopMusicViewController*)(self.presentingViewController);
//    audioPlayer = presenter->audioPlayer;
//    [presenter setOccupied:true];
//    finderSetTime.text = [NSString stringWithFormat:@"%f", audioPlayer.loopStart];
//    finderSetTimeEnd.text = [NSString stringWithFormat:@"%f", audioPlayer.loopEnd];
//    finderSongName.text = [presenter getSongName];
//}


- (void)loadPresenter:(LoopMusicViewController *)presenterPtr
{
    [super loadPresenter:presenterPtr];
    finderSetTime.text = [NSString stringWithFormat:@"%f", [presenter getAudioLoopStart]];
    finderSetTimeEnd.text = [NSString stringWithFormat:@"%f", [presenter getAudioLoopEnd]];
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

- (IBAction)finderSetTime:(id)sender
{
    if ([finderSetTime.text doubleValue] >= [presenter getAudioLoopEnd] || [finderSetTime.text doubleValue] < 0 || [finderSetTime.text isEqual:@""])
    {
        finderSetTime.text = [NSString stringWithFormat:@"%f", [presenter getAudioLoopStart]];
        return;
    }
    [self setLoopStart:[finderSetTime.text doubleValue]];
}

- (IBAction)finderSetTimeEnd:(id)sender
{
    /// The time that the loop end will be set to.
    NSTimeInterval newTime = [finderSetTimeEnd.text doubleValue];
    if (newTime <= [presenter getAudioLoopStart] || [finderSetTimeEnd.text isEqual:@""])
    {
        finderSetTimeEnd.text = [NSString stringWithFormat:@"%f", [presenter getAudioLoopEnd]];
        return;
    }
    /// The duration of the current track.
    NSTimeInterval duration = [presenter getAudioDuration];
    if (newTime > duration)
    {
        newTime = duration;
    }
    [self setLoopEnd:newTime];
    // [presenter setAudioLoopEnd:[finderSetTimeEnd.text doubleValue]];
    [self sqliteUpdate:@"loopend" newTime:[presenter getAudioLoopEnd]];
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
            newTime = [presenter getAudioLoopStart];
        }
    }
    else
    {
        newTime = [presenter getAudioLoopStart] + LOOPPOINTINCREMENT;
    }
    if (newTime >= [presenter getAudioLoopEnd])
    {
        return;
    }
    [self setLoopStart:newTime];
}

- (IBAction)finderAddTimeEnd:(id)sender
{
    if ([presenter getAudioLoopEnd] >= [presenter getAudioDuration])
    {
        return;
    }
    [self setLoopEnd:[presenter getAudioLoopEnd] + LOOPPOINTINCREMENT];
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
            newTime = [presenter getAudioLoopStart];
        }
    }
    else
    {
        newTime = [presenter getAudioLoopStart] - LOOPPOINTINCREMENT;
    }
    if (newTime < 0)
    {
        newTime = 0;
    }
    [self setLoopStart:newTime];
}

- (IBAction)finderSubtractTimeEnd:(id)sender
{
    if ([presenter getAudioLoopEnd] <= [presenter getAudioLoopStart] + LOOPPOINTINCREMENT)
    {
        return;
    }
    [self setLoopEnd:[presenter getAudioLoopEnd] - LOOPPOINTINCREMENT];
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
    result = [presenter updateDBResult:[NSString stringWithFormat:@"UPDATE Tracks SET %@ = %f WHERE name = \"%@\"", field1, newTime, [presenter getSongName]]];
    if (result != 101)
    {
        [presenter showErrorMessage:[NSString stringWithFormat:@"Failed to update database (%li). Restart the app.", (long)result]];
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
    foundPoints = [presenter audioFindLoopTime];
    if ([foundPoints count] == 0)
    {
        [presenter showErrorMessage:@"No suitable loop start times were found."];
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

/*!
 * Sets the loop start point.
 * @param loopStart The new loop start point.
 * @return
 */
- (void)setLoopStart:(NSTimeInterval)loopStart
{
    [super setLoopStart:loopStart];
    finderSetTime.text = [NSString stringWithFormat:@"%f", [presenter getAudioLoopStart]];
}

/*!
 * Sets the loop end point.
 * @param loopEnd The new loop end point.
 * @return
 */
- (void)setLoopEnd:(NSTimeInterval)loopEnd
{
    [super setLoopEnd:loopEnd];
    finderSetTimeEnd.text = [NSString stringWithFormat:@"%f", [presenter getAudioLoopEnd]];
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
