//
//  SettingsViewController.m
//  LoopMusic
//
//  Created by Cheng Hann Gan on 5/24/14.
//  Copyright (c) 2014 Cheng Hann Gan. All rights reserved.
//

#import "SettingsViewController.h"

@interface SettingsViewController ()

@end

@implementation SettingsViewController

@synthesize back, volumeAdjust, setTime, setTimeEnd, shuffle, shuffleRepeats, shuffleTime, enabledSwitch;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

- (void)viewDidLoad
{
    self.shuffle.selectedSegmentIndex = shuffleSetting;
    
    setTime.text = [NSString stringWithFormat:@"%f", loopTime];
    setTimeEnd.text = [NSString stringWithFormat:@"%f", loopEnd];
    shuffleTime.text = [NSString stringWithFormat:@"%f", timeShuffle];
    shuffleRepeats.text = [NSString stringWithFormat:@"%li", (long)repeatsShuffle];
    shuffle.selectedSegmentIndex = shuffleSetting;
    presenter = (LoopMusicViewController*)self.presentingViewController;
    [presenter setOccupied:true];
    NSTimer *loadTimer = [NSTimer scheduledTimerWithTimeInterval:.1
                                                      target:self
                                                    selector:@selector(loadSettings:)
                                                    userInfo:nil
                                                     repeats:NO];
}

-(void)loadSettings:(NSTimer*)loadTimer
{
    enabledSwitch.on = [presenter getEnabled];
    volumeAdjust.text = [NSString stringWithFormat:@"%f", [presenter getVolume]];
}

-(IBAction)back:(id)sender
{
    [presenter setOccupied:false];
    shuffleSetting = [shuffle selectedSegmentIndex];
    NSString *fileWriteString = [NSString stringWithFormat:@"%lu,%f,%li", (unsigned long)shuffleSetting, timeShuffle, (long)repeatsShuffle];
    NSString *filePath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"Settings.txt"];
    [fileWriteString writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    [super back:sender];
}

-(IBAction)setVolume:(id)sender
{
    if ([volumeAdjust.text doubleValue] < 0 || [volumeAdjust.text doubleValue] > 1)
    {
        volumeAdjust.text = [NSString stringWithFormat:@"%f", [presenter getVolume]];
        return;
    }
    [presenter setVolume:[volumeAdjust.text doubleValue]];
}

-(IBAction)addVolume:(id)sender
{
    if ([volumeAdjust.text doubleValue] >= 1)
    {
        return;
    }
    volumeAdjust.text = [NSString stringWithFormat:@"%f", [volumeAdjust.text doubleValue] + .1];
    [self setVolume:self];
}

-(IBAction)subtractVolume:(id)sender
{
    if ([volumeAdjust.text doubleValue] <= 0)
    {
        return;
    }
    volumeAdjust.text = [NSString stringWithFormat:@"%f", [volumeAdjust.text doubleValue] - .1];
    [self setVolume:self];
}

-(IBAction)setTime:(id)sender
{
    if ([setTime.text doubleValue] >= loopEnd || [setTime.text doubleValue] < 0 || [setTime.text isEqual:@""])
    {
        setTime.text = [NSString stringWithFormat:@"%f", loopTime];
        return;
    }
    [presenter setLoopTime:[setTime.text doubleValue]];
    [self sqliteUpdate:@"loopstart" newTime:loopTime];
}

-(IBAction)setTimeEnd:(id)sender
{
    if ([setTimeEnd.text doubleValue] <= loopTime || [setTimeEnd.text isEqual:@""])
    {
        [self sqliteUpdate:@"loopend" newTime:loopEnd];;
        return;
    }
    if ([setTimeEnd.text doubleValue] > [presenter getAudioDuration])
    {
        setTimeEnd.text = [NSString stringWithFormat:@"%f", [presenter getAudioDuration]];
    }
    loopEnd = [setTimeEnd.text doubleValue];
    [self sqliteUpdate:@"loopend" newTime:loopEnd];
}

-(IBAction)addTime:(id)sender
{
    if (loopTime >= loopEnd-.001)
    {
        return;
    }
    [self sqliteUpdate:@"loopstart" newTime:loopTime+.001];
    setTime.text = [NSString stringWithFormat:@"%f", loopTime];
}

-(IBAction)addTimeEnd:(id)sender
{
    if (loopEnd >= [presenter getAudioDuration])
    {
        return;
    }
    loopEnd += .001;
    [self sqliteUpdate:@"loopend" newTime:loopEnd];
    setTimeEnd.text = [NSString stringWithFormat:@"%f", loopEnd];
}

-(IBAction)subtractTime:(id)sender
{
    if (loopTime <= 0)
    {
        return;
    }
    [self sqliteUpdate:@"loopstart" newTime:loopTime-.001];
    setTime.text = [NSString stringWithFormat:@"%f", loopTime];
}

-(IBAction)subtractTimeEnd:(id)sender
{
    if (loopEnd <= loopTime + .001)
    {
        return;
    }
    loopEnd -= .001;
    [self sqliteUpdate:@"loopend" newTime:loopEnd];
    setTimeEnd.text = [NSString stringWithFormat:@"%f", loopEnd];
}

-(NSInteger)sqliteUpdate:(NSString*)field1 newTime:(double)newTime
{
    [self openDB];
    NSInteger result = 0;
    if ([field1 isEqual: @"loopstart"])
    {
        result = [presenter setLoopTime:newTime];
    }
    else
    {
        NSString *querySQL;
        if ([field1 isEqual: @"enabled"])
        {
            querySQL = [NSString stringWithFormat:@"UPDATE Tracks SET enabled = %i WHERE name = \"%@\"", enabledSwitch.on, settingsSongString];
        }
        else
        {
            querySQL = [NSString stringWithFormat:@"UPDATE Tracks SET %@ = %f WHERE name = \"%@\"", field1, newTime, settingsSongString];
        }
        result = [self updateDBResult:querySQL];
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
    sqlite3_close(trackData);
    return result;
}

-(IBAction)shuffleTime:(id)sender
{
    if ([shuffleTime.text doubleValue] > 0)
    {
        timeShuffle = [shuffleTime.text doubleValue];
    }
    else
    {
        shuffleTime.text = @"Invalid";
    }
}

-(IBAction)shuffleRepeats:(id)sender
{
    if ([shuffleRepeats.text intValue] > 0)
    {
        repeatsShuffle = [shuffleRepeats.text intValue];
    }
    else
    {
        shuffleRepeats.text = @"Invalid";
    }
}

-(IBAction)enabledSwitch:(id)sender
{
    [self sqliteUpdate:@"enabled" newTime:enabledSwitch.on];
}

-(IBAction)close:(id)sender
{
    [shuffleTime resignFirstResponder];
    [shuffleRepeats resignFirstResponder];
    [setTime resignFirstResponder];
    [setTimeEnd resignFirstResponder];
    [volumeAdjust resignFirstResponder];
}

-(IBAction)shuffleChange:(id)sender
{
    shuffleSetting = [shuffle selectedSegmentIndex];
}

-(void)returned
{
    setTime.text = [NSString stringWithFormat:@"%f", loopTime];
    setTimeEnd.text = [NSString stringWithFormat:@"%f", loopEnd];
}

-(IBAction)loopFinder:(id)sender
{
    [self changeScreen:@"loopFinder"];
}

-(IBAction)addSong:(id)sender
{
    MPMediaPickerController *picker = [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeAnyAudio];
    
    [picker setDelegate: self];
    [picker setAllowsPickingMultipleItems: YES];
    picker.prompt = @"Add songs";
    
    [self presentViewController:picker
                       animated:true
                     completion:nil];
}

- (void)mediaPicker:(MPMediaPickerController *) mediaPicker didPickMediaItems:(MPMediaItemCollection *)collection
{
    [self openDB];
    for (MPMediaItem *item in collection.items)
    {
        NSString *itemName = [item valueForProperty:MPMediaItemPropertyTitle];
        NSURL *itemURL = [item valueForProperty:MPMediaItemPropertyAssetURL];
        [self prepareQuery:[NSString stringWithFormat:@"SELECT url FROM Tracks WHERE name=\"%@\"", itemName]];
        if (sqlite3_step(statement) == SQLITE_ROW)
        {
            NSString *urlString = @"";
            if (sqlite3_column_text(statement, 0) != nil)
            {
                NSString *urlString = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 0)];
            }
            if ([urlString isEqualToString:@""])
            {
                [self updateDB:[NSString stringWithFormat:@"UPDATE Tracks SET url = \"%@\" WHERE name = \"%@\"", itemURL.absoluteString, itemName]];
            }
        }
        else
        {
            [self updateDB:[NSString stringWithFormat:@"INSERT INTO Tracks (name, loopstart, loopend, volume, enabled, url) VALUES (\"%@\", 0, 0, 0.3, 1, \"%@\")", itemName, itemURL.absoluteString]];
            [presenter incrementTotalSongs];
        }
        sqlite3_finalize(statement);
    }
    sqlite3_close(trackData);
    [self dismissViewControllerAnimated:true
                             completion:nil];
}

- (void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker
{
    [self dismissViewControllerAnimated:true
                             completion:nil];
}

-(IBAction)deleteSong:(id)sender
{
    [self changeScreen:@"delete"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
