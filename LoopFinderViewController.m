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
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    stringTemp = [[NSBundle mainBundle] pathForResource:@"Tracks" ofType:@"db"];
    dbPath = [stringTemp UTF8String];
    sqlite3_open(dbPath, &trackData);
    database = nil;
    dirPaths = NSSearchPathForDirectoriesInDomains
    (NSDocumentDirectory, NSUserDomainMask, YES);
    docsDir = dirPaths[0];
    databasePath = [[NSString alloc] initWithString:[docsDir stringByAppendingPathComponent: @"Tracks.db"]];
    dbPath2 = [databasePath UTF8String];
    
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
    finderSongName.text = [(LoopMusicViewController*)(self.presentingViewController).presentingViewController getSongName];
}

-(IBAction)setCurrentTime:(id)sender
{
    if ([setCurrentTime.text isEqual:@""]  || [setCurrentTime.text doubleValue] > [(LoopMusicViewController*)(self.presentingViewController).presentingViewController getAudioDuration])
    {
        setCurrentTime.text = @"";
        return;
    }
    [(LoopMusicViewController*)(self.presentingViewController).presentingViewController setCurrentTime:[setCurrentTime.text doubleValue]];
}

-(IBAction)finderSetTime:(id)sender
{
    if ([finderSetTime.text doubleValue] >= loopEnd || [finderSetTime.text doubleValue] < 0 || [finderSetTime.text isEqual:@""])
    {
        finderSetTime.text = [NSString stringWithFormat:@"%f", loopTime];
        return;
    }
    [(LoopMusicViewController*)(self.presentingViewController).presentingViewController setLoopTime:[finderSetTime.text doubleValue]];
    [self sqliteUpdate:@"loopstart" newTime:loopTime];
}

-(IBAction)finderSetTimeEnd:(id)sender
{
    if ([finderSetTimeEnd.text doubleValue] <= loopTime || [finderSetTimeEnd.text isEqual:@""])
    {
        finderSetTimeEnd.text = [NSString stringWithFormat:@"%f", loopEnd];
        return;
    }
    if ([finderSetTimeEnd.text doubleValue] > [(LoopMusicViewController*)(self.presentingViewController).presentingViewController getAudioDuration])
    {
        finderSetTimeEnd.text = [NSString stringWithFormat:@"%f", [(LoopMusicViewController*)(self.presentingViewController).presentingViewController getAudioDuration]];
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
    if (loopEnd >= [(LoopMusicViewController*)(self.presentingViewController).presentingViewController getAudioDuration])
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

-(int)sqliteUpdate:(NSString*)field1 newTime:(double)newTime
{
    int result = 0;
    if ([field1 isEqual: @"loopstart"])
    {
        result = [(LoopMusicViewController*)(self.presentingViewController).presentingViewController setLoopTime:newTime];
    }
    else
    {
    dbPath2 = [databasePath UTF8String];
    sqlite3_open(dbPath2, &trackData);
    NSString *querySQL = [NSString stringWithFormat:@"UPDATE Tracks SET %@ = %f WHERE name = \"%@\"", field1, newTime, settingsSongString];
    const char *query_stmt = [querySQL UTF8String];
    sqlite3_prepare_v2(trackData, query_stmt, -1, &statement, NULL);
    result = sqlite3_step(statement);
    sqlite3_finalize(statement);
    sqlite3_close(trackData);
    NSLog(@"%@, (%i)", querySQL, result);
    }
    if (result != 101)
    {
        UIAlertController *error = [UIAlertController alertControllerWithTitle:@"Error"
                                                    message:[NSString stringWithFormat:@"Failed to update database (%i)", result]
                                             preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Damn", @"OK action")
                                                      style:UIAlertActionStyleDefault
                                                    handler:nil];
        [error addAction:defaultAction];
        [self presentViewController:error animated:YES completion:nil];
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
    findTimeText.text = [NSString stringWithFormat:@"%f", [(LoopMusicViewController*)(self.presentingViewController).presentingViewController findTime] + [(LoopMusicViewController*)(self.presentingViewController) getDelay]];
}

-(IBAction)testTime:(id)sender
{
    [(LoopMusicViewController*)(self.presentingViewController).presentingViewController testTime];
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
    [self dismissViewControllerAnimated:true completion:nil];
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
