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

@synthesize back, volumeAdjust, setTime, setTimeEnd, shuffle, shuffleRepeats, shuffleTime, enabledSwitch, fadeText;

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
    fadeText.text = [NSString stringWithFormat:@"%f", fadeSetting];
    NSTimer *loadTimer = [NSTimer scheduledTimerWithTimeInterval:.1
                                                      target:self
                                                    selector:@selector(loadSettings:)
                                                    userInfo:nil
                                                     repeats:NO];
}

-(void)loadSettings:(NSTimer*)loadTimer
{
    presenter = (LoopMusicViewController*)self.presentingViewController;
    enabledSwitch.on = [presenter getEnabled];
    volumeAdjust.text = [NSString stringWithFormat:@"%f", [presenter getVolume]];
    [presenter setOccupied:true];
}

-(IBAction)back:(id)sender
{
    [presenter setOccupied:false];
    shuffleSetting = [shuffle selectedSegmentIndex];
    NSString *fileWriteString = [NSString stringWithFormat:@"%lu,%f,%li,%f,%li", (unsigned long)shuffleSetting, timeShuffle, (long)repeatsShuffle, fadeSetting, (long)playlistIndex];
    NSString *filePath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"Settings.txt"];
    [fileWriteString writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    [super back:sender];
}

-(IBAction)setVolume:(id)sender
{
    if ([presenter isSongListEmpty])
    {
        [self showNoSongMessage];
        return;
    }
    if ([volumeAdjust.text doubleValue] < 0 || [volumeAdjust.text doubleValue] > 1)
    {
        volumeAdjust.text = [NSString stringWithFormat:@"%f", [presenter getVolume]];
        return;
    }
    [presenter setVolume:[volumeAdjust.text doubleValue]];
}

-(IBAction)addVolume:(id)sender
{
    if ([presenter isSongListEmpty])
    {
        [self showNoSongMessage];
        return;
    }
    if ([volumeAdjust.text doubleValue] >= 1)
    {
        return;
    }
    volumeAdjust.text = [NSString stringWithFormat:@"%f", [volumeAdjust.text doubleValue] + .1];
    [self setVolume:self];
}

-(IBAction)subtractVolume:(id)sender
{
    if ([presenter isSongListEmpty])
    {
        [self showNoSongMessage];
        return;
    }
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
    if (loopTime >= loopEnd - .001)
    {
        return;
    }
    [self sqliteUpdate:@"loopstart" newTime:loopTime + .001];
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
        [self showErrorMessage:[NSString stringWithFormat:@"Failed to update database (%li). Restart the app.", (long)result]];
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


-(IBAction)setFade:(id)sender
{
    if ([fadeText.text doubleValue] >= 0)
    {
        fadeSetting = [fadeText.text doubleValue];
        [presenter updateVolumeDec];
    }
    else
    {
        fadeText.text = @"Invalid";
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
    [fadeText resignFirstResponder];
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
    if ([presenter isSongListEmpty])
    {
        [self showNoSongMessage];
    }
    else
    {
        [self changeScreen:@"loopFinder"];
    }
}

-(IBAction)addSong:(id)sender
{
    addingSong = true;
    MPMediaPickerController *picker = [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeAnyAudio];
    
    [picker setDelegate: self];
    [picker setAllowsPickingMultipleItems: YES];
    picker.prompt = @"Add songs";
    
    [self presentViewController:picker
                       animated:true
                     completion:nil];
}

-(IBAction)renameSong:(id)sender
{
    if ([presenter isSongListEmpty])
    {
        [self showNoSongMessage];
        return;
    }
    alertIndex = 0;
    [self showTwoButtonMessageInput:@"Rename Track" :@"Enter a new name for the track." :@"Rename" :[presenter getSongName]];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0)
    {
        return;
    }
    NSString* newName = [[alertView textFieldAtIndex:0] text];
    if ([newName isEqualToString:@""])
    {
        [self showErrorMessage:@"The playlist name cannot be blank."];
        return;
    }
    if (alertIndex == 0)
    {
        if (![newName isEqualToString:[presenter getSongName]])
        {
            [self openDB];
            [self prepareQuery:[NSString stringWithFormat:@"SELECT name FROM Tracks WHERE name=\"%@\"", [presenter getSongName]]];
            if (sqlite3_step(statement) == SQLITE_ROW)
            {
                [self updateDB:[NSString stringWithFormat:@"UPDATE Tracks SET name = \"%@\" WHERE name = \"%@\"", newName, [presenter getSongName]]];
                [presenter setNewSongName:newName];
            }
            sqlite3_finalize(statement);
            sqlite3_close(trackData);
        }
    }
    else if (alertIndex == 1)
    {
        // Rename playlist.
        if (playlistIndex && ![newName isEqualToString:[presenter getPlaylistName]])
        {
            [self openDB];
            [self prepareQuery:[NSString stringWithFormat:@"SELECT id FROM Playlists WHERE name=\"%@\"", newName]];
            if (sqlite3_step(statement) == SQLITE_ROW && sqlite3_column_int(statement, 0) != playlistIndex)
            {
                [self showErrorMessage:@"Name is already used."];
            }
            else
            {
                [self updateDB:[NSString stringWithFormat:@"UPDATE Playlists SET name = \"%@\" WHERE id = \"%ld\"", newName, (long)playlistIndex]];
            }
            sqlite3_finalize(statement);
            sqlite3_close(trackData);
            [presenter updatePlaylistName:newName];
        }
    }
    else if (alertIndex == 2)
    {
        // Add playlist.
        [self openDB];
        [self prepareQuery:[NSString stringWithFormat:@"SELECT id FROM Playlists WHERE name=\"%@\"", newName]];
        if (sqlite3_step(statement) == SQLITE_ROW)
        {
            NSLog(@"%d", sqlite3_column_int(statement, 0));
            [self showErrorMessage:@"Name is already used."];
        }
        else
        {
            [self updateDB:[NSString stringWithFormat:@"INSERT INTO Playlists (name, tracks) values (\"%@\", \"\")", newName]];
            sqlite3_finalize(statement);
            [self prepareQuery:[NSString stringWithFormat:@"SELECT id FROM Playlists WHERE name=\"%@\"", newName]];
            if (sqlite3_step(statement) == SQLITE_ROW)
            {
                playlistIndex = sqlite3_column_int(statement, 0);
            }
        }
        sqlite3_finalize(statement);
        sqlite3_close(trackData);
        [presenter updatePlaylistSongs];
        [presenter updatePlaylistName];
    }
}

-(IBAction)replaceSong:(id)sender
{
    if ([presenter isSongListEmpty])
    {
        [self showNoSongMessage];
        return;
    }
    addingSong = false;
    MPMediaPickerController *picker = [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeAnyAudio];
    
    [picker setDelegate: self];
    [picker setAllowsPickingMultipleItems: NO];
    picker.prompt = @"Replace song";
    
    [self presentViewController:picker
                       animated:true
                     completion:nil];
}

- (void)mediaPicker:(MPMediaPickerController *) mediaPicker didPickMediaItems:(MPMediaItemCollection *)collection
{
    [self dismissViewControllerAnimated:true
                             completion:nil];
    [self openDB];
    if (addingSong)
    {
        for (MPMediaItem *item in collection.items)
        {
            NSString *itemName = [item valueForProperty:MPMediaItemPropertyTitle];
            NSURL *itemURL = [item valueForProperty:MPMediaItemPropertyAssetURL];
            [self prepareQuery:[NSString stringWithFormat:@"SELECT url FROM Tracks WHERE name=\"%@\"", itemName]];
            if (sqlite3_step(statement) == SQLITE_ROW)
            {
                [self updateDB:[NSString stringWithFormat:@"UPDATE Tracks SET url = \"%@\" WHERE name = \"%@\"", itemURL.absoluteString, itemName]];
            }
            else
            {
                sqlite3_finalize(statement);
                [self prepareQuery:[NSString stringWithFormat:@"SELECT name FROM Tracks WHERE url=\"%@\"", itemURL]];
                if (sqlite3_step(statement) != SQLITE_ROW)
                {
                    [self updateDB:[NSString stringWithFormat:@"INSERT INTO Tracks (name, loopstart, loopend, volume, enabled, url) VALUES (\"%@\", 0, 0, 0.3, 1, \"%@\")", itemName, itemURL.absoluteString]];
                    [presenter incrementTotalSongs];
                }
            }
            sqlite3_finalize(statement);
        }
    }
    else
    {
        for (MPMediaItem *item in collection.items)
        {
            NSString *itemName = [item valueForProperty:MPMediaItemPropertyTitle];
            NSURL *itemURL = [item valueForProperty:MPMediaItemPropertyAssetURL];
            [self prepareQuery:[NSString stringWithFormat:@"SELECT url FROM Tracks WHERE name=\"%@\"", itemName]];
            if (sqlite3_step(statement) == SQLITE_ROW && ![itemName isEqualToString:[presenter getSongName]])
            {
                [self showErrorMessage:@"Name is already used."];
            }
            else
            {
                sqlite3_finalize(statement);
                [self prepareQuery:[NSString stringWithFormat:@"SELECT url FROM Tracks WHERE name=\"%@\"", [presenter getSongName]]];
                if (sqlite3_step(statement) == SQLITE_ROW)
                {
                    [self updateDB:[NSString stringWithFormat:@"UPDATE Tracks SET url = \"%@\", name = \"%@\" WHERE name = \"%@\"", itemURL.absoluteString, itemName, [presenter getSongName]]];
                    [presenter setAudioPlayer:itemURL];
                    [presenter setNewSongName:itemName];
                }
            }
            sqlite3_finalize(statement);
        }
    }
    sqlite3_close(trackData);
}

- (void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker
{
    [self dismissViewControllerAnimated:true
                             completion:nil];
}

-(IBAction)deleteSong:(id)sender
{
    if ([presenter isSongListEmpty])
    {
        [self showNoSongMessage];
    }
    else
    {
        [self changeScreen:@"delete"];
    }
}


-(IBAction)choosePlaylist:(id)sender
{
    [self changeScreen:@"choosePlaylist"];
}

-(IBAction)modifyPlaylist:(id)sender
{
    if (!playlistIndex)
    {
        [self showErrorMessage:@"The \"All tracks\" playlist can't be modified."];
    }
    else if ([presenter isSongListEmpty])
    {
        [self showNoSongMessage];
    }
    else
    {
        [self changeScreen:@"modifyPlaylist"];
    }
}

-(IBAction)newPlaylist:(id)sender
{
    alertIndex = 2;
    [self showTwoButtonMessageInput:@"New Playlist" :@"Enter the name of the playlist." :@"Add" :nil];
}

-(IBAction)renamePlaylist:(id)sender
{
    if (playlistIndex)
    {
        alertIndex = 1;
        [self showTwoButtonMessageInput:@"Rename Playlist" :@"Enter a new name for the playlist." :@"Rename" :[presenter getPlaylistName]];
    }
    else
    {
        [self showErrorMessage:@"The \"All tracks\" playlist can't be modified."];
    }
}

-(IBAction)deletePlaylist:(id)sender
{
    [self changeScreen:@"deletePlaylist"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
