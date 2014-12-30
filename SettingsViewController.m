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
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    //open database
    self.shuffle.selectedSegmentIndex = shuffleSetting;
    stringTemp = [[NSBundle mainBundle] pathForResource:@"Tracks" ofType:@"db"];
    dbPath = [stringTemp UTF8String];
    sqlite3_open(dbPath, &trackData);
    database = nil;
    dirPaths = NSSearchPathForDirectoriesInDomains
    (NSDocumentDirectory, NSUserDomainMask, YES);
    docsDir = dirPaths[0];
    databasePath = [[NSString alloc] initWithString:[docsDir stringByAppendingPathComponent: @"Tracks.db"]];
    dbPath2 = [databasePath UTF8String];
    
    setTime.text = [NSString stringWithFormat:@"%f", loopTime];
    setTimeEnd.text = [NSString stringWithFormat:@"%f", loopEnd];
    shuffleTime.text = [NSString stringWithFormat:@"%f", timeShuffle];
    shuffleRepeats.text = [NSString stringWithFormat:@"%li", (long)repeatsShuffle];
    shuffle.selectedSegmentIndex = shuffleSetting;
    NSTimer *loadTimer = [NSTimer scheduledTimerWithTimeInterval:.1
                                                      target:self
                                                    selector:@selector(loadSettings:)
                                                    userInfo:nil
                                                     repeats:NO];
}

-(void)loadSettings:(NSTimer*)loadTimer
{
    enabledSwitch.on = [(LoopMusicViewController*)self.presentingViewController getEnabled];
    volumeAdjust.text = [NSString stringWithFormat:@"%f", [(LoopMusicViewController*)self.presentingViewController getVolume]];
    [(LoopMusicViewController*)self.presentingViewController setOccupied:true];
}

-(IBAction)back:(id)sender
{
    [(LoopMusicViewController*)self.presentingViewController setOccupied:false];
    shuffleSetting = [shuffle selectedSegmentIndex];
    NSString *fileWriteString = [NSString stringWithFormat:@"%lu,%f,%li", (unsigned long)shuffleSetting, timeShuffle, (long)repeatsShuffle];
    NSString *filePath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"Settings.txt"];
    [fileWriteString writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    [self dismissViewControllerAnimated:true completion:nil];
}

-(IBAction)setVolume:(id)sender
{
    if ([volumeAdjust.text doubleValue] < 0 || [volumeAdjust.text doubleValue] > 1)
    {
        volumeAdjust.text = [NSString stringWithFormat:@"%f", [(LoopMusicViewController*)self.presentingViewController getVolume]];
        return;
    }
    [(LoopMusicViewController*)self.presentingViewController setVolume:[volumeAdjust.text doubleValue]];
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
    [(LoopMusicViewController*)self.presentingViewController setLoopTime:[setTime.text doubleValue]];
    [self sqliteUpdate:@"loopstart" newTime:loopTime];
}

-(IBAction)setTimeEnd:(id)sender
{
    if ([setTimeEnd.text doubleValue] <= loopTime || [setTimeEnd.text isEqual:@""])
    {
        [self sqliteUpdate:@"loopend" newTime:loopEnd];;
        return;
    }
    if ([setTimeEnd.text doubleValue] > [(LoopMusicViewController*)self.presentingViewController getAudioDuration])
    {
        setTimeEnd.text = [NSString stringWithFormat:@"%f", [(LoopMusicViewController*)self.presentingViewController getAudioDuration]];
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
    if (loopEnd >= [(LoopMusicViewController*)self.presentingViewController getAudioDuration])
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

-(int)sqliteUpdate:(NSString*)field1 newTime:(double)newTime
{
    int result = 0;
    if ([field1 isEqual: @"loopstart"])
    {
        result = [(LoopMusicViewController*)self.presentingViewController setLoopTime:newTime];
    }
    else
    {
        dbPath2 = [databasePath UTF8String];
        sqlite3_open(dbPath2, &trackData);
        NSString *querySQL;
        if ([field1 isEqual: @"enabled"])
        {
            querySQL = [NSString stringWithFormat:@"UPDATE Tracks SET enabled = %i WHERE name = \"%@\"", enabledSwitch.on, settingsSongString];
        }
        else
        {
            querySQL = [NSString stringWithFormat:@"UPDATE Tracks SET %@ = %f WHERE name = \"%@\"", field1, newTime, settingsSongString];
        }
        const char *query_stmt = [querySQL UTF8String];
        sqlite3_prepare_v2(trackData, query_stmt, -1, &statement, NULL);
        result = sqlite3_step(statement);
        sqlite3_finalize(statement);
        sqlite3_close(trackData);
        NSLog(@"%@, (%i)", querySQL, result);
    }
    if (result != 101)
    {
        if (NSClassFromString(@"UIAlertController"))
        {
            UIAlertController *error = [UIAlertController alertControllerWithTitle:@"Error"
                                                                           message:[NSString stringWithFormat:@"Failed to update database (%i). Restart the app.", result]
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Damn", @"OK action")
                                                                    style:UIAlertActionStyleDefault
                                                                  handler:nil];
            [error addAction:defaultAction];
            [self presentViewController:error animated:YES completion:nil];
        } else {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                             message:[NSString stringWithFormat:@"Failed to update database (%i). Restart the app.", result]
                                                            delegate:self
                                                   cancelButtonTitle:@"Damn"
                                                   otherButtonTitles: nil];
            [alert show];
        }
    }
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

-(IBAction)loopFinder:(id)sender
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main"
                                                         bundle:nil];
    UIViewController *loopFinderVC = [storyboard instantiateViewControllerWithIdentifier:@"loopFinder"];
    [self presentViewController:loopFinderVC
                       animated:true
                     completion:nil];
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
    /*switch ([shuffle selectedSegmentIndex])
    {
        case 0: timeShuffle = -1;
            repeatsShuffle = -1;
            break;
        case 1: repeatsShuffle = -1;
            timeShuffle = [shuffleTime.text doubleValue];
            break;
        case 2: timeShuffle = -1;
            repeatsShuffle = [shuffleRepeats.text intValue];
            break;
    }*/
}

-(void)returned
{
    setTime.text = [NSString stringWithFormat:@"%f", loopTime];
    setTimeEnd.text = [NSString stringWithFormat:@"%f", loopEnd];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
