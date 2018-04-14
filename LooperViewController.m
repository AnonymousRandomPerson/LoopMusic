//
//  LooperViewController.m
//  LoopMusic
//
//  Created by Johann Gan on 2/4/18.
//  Copyright © 2018 Cheng Hann Gan. All rights reserved.
//


#import "LooperViewController.h"

@interface LooperViewController ()

@end

@implementation LooperViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}



// Loads a pointer to the main screen, because everything happens there for some stupid reason, and it's not worth refactoring at the time of writing this.
- (void)loadPresenter:(LoopMusicViewController *)presenterPtr
{
    self->presenter = presenterPtr;
}

// Clears the borrowed presenter pointer.
- (void)unloadPresenter
{
    presenter = nil;
}



// Helpers for loop setting.

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

- (void)setLoopStart:(NSTimeInterval)loopStart
{
    [presenter setAudioLoopStart:loopStart];
    [self sqliteUpdate:@"loopstart" newTime:[presenter getAudioLoopStart]];
}
- (void)setLoopEnd:(NSTimeInterval)loopEnd
{
    [presenter setAudioLoopEnd:loopEnd];
    [self sqliteUpdate:@"loopend" newTime:[presenter getAudioLoopEnd]];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
