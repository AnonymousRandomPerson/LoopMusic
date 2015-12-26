//
//  LoopMusicViewController.m
//  LoopMusic
//
//  Created by Cheng Hann Gan on 12/24/13.
//  Copyright (c) 2013 Cheng Hann Gan. All rights reserved.
//

#import "LoopMusicViewController.h"

double loopTime = 0;
double loopEnd = 0;
NSString *settingsSongString = @"";
double timeShuffle = -1;
double timeShuffle2 = -1;
NSInteger repeatsShuffle = -1;
NSUInteger shuffleSetting = 0;
double fadeSetting = 0;

@interface LoopMusicViewController ()

@end

@implementation LoopMusicViewController

@synthesize searchSong, playSong, randomSong, stopSong, songName, settings, dim;

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [self resignFirstResponder];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setOccupied:false];
    [self openDB];
    // Initialize # of songs
    [self initializeTotalSongs];
    sqlite3_close(trackData);
    // Set up audio player
    playing=true;
    audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback
                        error:nil];
    [audioSession setActive:YES
                      error:nil];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    choose = false;
    songString = @"";
    chooseSongString = false;
    delay = 0;
    timer = [NSTimer scheduledTimerWithTimeInterval:.0001
                                             target:self
                                           selector:@selector(timeDec:)
                                           userInfo:nil
                                            repeats:YES];
    time = [self getTime];
    repeats = 0;
    musicNumber = -1;
    [self playMusic];
    
    NSString *filePath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"Settings.txt"];
    NSString *contentOfFile = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    if (contentOfFile)
    {
        NSArray *splitSettings = [contentOfFile componentsSeparatedByString:@","];
        shuffleSetting = [splitSettings[0] integerValue];
        timeShuffle = [splitSettings[1] doubleValue];
        timeShuffle2 = [self timeVariance];
        repeatsShuffle = [splitSettings[2] integerValue];
        fadeSetting = splitSettings.count > 3 ? [splitSettings[3] doubleValue] : 0;
    }
    else
    {
        // Default values.
        shuffleSetting = 1;
        timeShuffle = 3.5;
        timeShuffle2 = [self timeVariance];
        repeatsShuffle = 3;
        fadeSetting = 2;
        NSString *newSettings = [NSString stringWithFormat:@"%lu,%f,%ld,%f", (unsigned long)shuffleSetting, timeShuffle, (long)repeatsShuffle, fadeSetting];
        [newSettings writeToFile:filePath atomically:true encoding:NSUTF8StringEncoding error:nil];
    }
    initBright = [UIScreen mainScreen].brightness;
    dim.on = false;
}

- (void)timeDec:(NSTimer*)timer
{
    if (playing)
    {
        if (audioPlayer.currentTime>=loopEnd-delay)
        {
            [audioPlayer2 play];
            [audioPlayer stop];
            [audioPlayer prepareToPlay];
            audioPlayer.currentTime=loopTime-delay;
            repeats++;
        }
        if (audioPlayer2.currentTime>=loopEnd-delay)
        {
            [audioPlayer play];
            [audioPlayer2 stop];
            [audioPlayer2 prepareToPlay];
            audioPlayer2.currentTime=loopTime-delay;
            repeats++;
        }
        if (!occupied)
        {
            if (repeatsShuffle > 0 && shuffleSetting == 2)
            {
                if (repeats >= repeatsShuffle)
                {
                    buffer=true;
                }
            }
            if (timeShuffle > 0)
            {
                if (([self getTime] - time) >= timeShuffle2 && shuffleSetting == 1)
                {
                    buffer=true;
                }
            }
            if (buffer)
            {
                if (++fadeTime > fadeSetting * 5000)
                {
                    buffer = false;
                    time = [self getTime];
                    choose = false;
                    [self playMusic];
                    return;
                }
                else if (audioPlayer.volume > 0)
                {
                    audioPlayer.volume -= volumeDec;
                    audioPlayer2.volume -= volumeDec;
                }
            }
        }
        if (!audioPlayer2.playing && !audioPlayer.playing && time > 10000)
        {
            if (audioPlayer.currentTime == 0)
            {
                [audioPlayer2 play];
                audioPlayer.currentTime = loopTime-delay;
                [audioPlayer prepareToPlay];
            }
            else
            {
                [audioPlayer play];
                audioPlayer2.currentTime = loopTime-delay;
                [audioPlayer2 prepareToPlay];
            }
            repeats++;
        }
    }
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)data successfully:(BOOL)flag
{
    if (audioPlayer.playing)
    {
        [audioPlayer2 play];
        [audioPlayer stop];
        audioPlayer.currentTime=loopTime-delay;
        [audioPlayer prepareToPlay];
        repeats++;
    }
    else if (audioPlayer2.playing)
    {
        [audioPlayer play];
        [audioPlayer2 stop];
        audioPlayer2.currentTime=loopTime-delay;
        [audioPlayer2 prepareToPlay];
        repeats++;
    }
    
}

// Change song
-(void)playMusic
{
    if ([self isSongListEmpty])
    {
        return;
    }
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    playing=false;
    valid=false;
    
    [self openDB];
    if (chooseSongString)
    {
        chooseSongString = false;
        musicNumber = -1;
        [self prepareQuery:[NSString stringWithFormat:@"SELECT * FROM Tracks WHERE name=\"%@\"", chooseSongText]];
        if (sqlite3_step(statement) == SQLITE_ROW)
        {
            idField = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 0)];
            nameField = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 1)];
            if (sqlite3_column_text(statement, 4) == nil || [[[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 2)] isEqualToString:(@"")])
            {
                loopTime = 0;
                loopEnd = 0;
                volumeSet = 0.3;
                enabled = 1;
                [self updateDB:[NSString stringWithFormat:@"UPDATE Tracks SET loopstart = %f WHERE name = \"%@\"", loopTime, nameField]];
                [self updateDB:[NSString stringWithFormat:@"UPDATE Tracks SET loopend = 0 WHERE name = \"%@\"", nameField]];
                [self updateDB:[NSString stringWithFormat:@"UPDATE Tracks SET volume = 0.3 WHERE name = \"%@\"", nameField]];
                [self updateDB:[NSString stringWithFormat:@"UPDATE Tracks SET enabled = 1 WHERE name = \"%@\"", nameField]];
            }
            else
            {
                loopTime = sqlite3_column_double(statement, 2);
                loopEnd = sqlite3_column_double(statement, 3);
                volumeSet = sqlite3_column_double(statement, 4);
                enabled = sqlite3_column_int(statement, 5);
                if (sqlite3_column_text(statement, 6) != nil) {
                    url = [NSURL URLWithString:[[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 6)]];
                }
                else
                {
                    url = nil;
                }
            }
            valid = true;
            musicNumber = [idField intValue];
        }
        sqlite3_finalize(statement);
        songName.text = nameField;
        sqlite3_close(trackData);
        if (!valid || url == nil)
        {
            return;
        }
    }
    //If chosen song text is a number
    else
    {
        do
        {
            NSInteger random = -1;
            do
            {
                random = arc4random() % totalSongs;
            } while (musicNumber == random);
            timeShuffle2 = [self timeVariance];
            musicNumber = random;
            [self prepareQuery:[NSString stringWithFormat:@"SELECT * FROM Tracks ORDER BY id LIMIT 1 OFFSET \"%li\"", (long)musicNumber]];
            if (sqlite3_step(statement) == SQLITE_ROW)
            {
                idField = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 0)];
                nameField = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 1)];
                loopTime = sqlite3_column_double(statement, 2);
                loopEnd = sqlite3_column_double(statement, 3);
                volumeSet = sqlite3_column_double(statement, 4);
                enabled = sqlite3_column_int(statement, 5);
                if (sqlite3_column_text(statement, 6) != nil)
                {
                    url = [NSURL URLWithString:[[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 6)]];
                }
                else
                {
                    url = nil;
                }
                musicNumber = [idField intValue];
            }
            else
            {
                enabled = false;
            }
            sqlite3_finalize(statement);
        } while (!enabled);
        songName.text = nameField;
    }
    sqlite3_close(trackData);
    NSLog(@"%@", songName.text);
    [self setAudioPlayer:url];
    [self updateVolumeDec];
    if (!timer)
    {
        timer = [NSTimer scheduledTimerWithTimeInterval:.0001
                                                 target:self
                                               selector:@selector(timeDec:)
                                               userInfo:nil
                                                repeats:YES];
    }
    playing=true;
    [audioPlayer play];
    [audioPlayer2 prepareToPlay];
    repeats = 0;
    fadeTime = 0;
    buffer = false;
    time = [self getTime];
    if (loopEnd == 0.0)
    {
        loopEnd = audioPlayer.duration;
        [self openDB];
        [self updateDB:[NSString stringWithFormat:@"UPDATE Tracks SET loopend = %f WHERE id=\"%li\"", loopEnd, (long)musicNumber]];
    }
}

-(void)setAudioPlayer:(NSURL*)newURL
{
    // Change audio player settings
    NSError *error;
    audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:newURL
                                                         error:&error];
    if (audioPlayer == nil)
    {
        NSLog(@"%@", [error description]);
        return;
    }
    audioPlayer.numberOfLoops = 0;
    audioPlayer2 = [[AVAudioPlayer alloc] initWithContentsOfURL:newURL
                                                          error:&error];
    audioPlayer2.numberOfLoops = 0;
    [audioPlayer stop];
    [audioPlayer2 stop];
    audioPlayer.currentTime=0;
    audioPlayer2.currentTime=loopTime-delay;
    audioPlayer.volume = volumeSet;
    audioPlayer2.volume = volumeSet;
}

-(void)updateVolumeDec
{
    volumeDec = fadeSetting > 0 ? volumeSet / (fadeSetting * 5000) : 0;
}

-(IBAction)randomSong:(id)sender
{
    if ([self isSongListEmpty])
    {
        [self showNoSongMessage];
        return;
    }
    time = [self getTime];
    repeats = 0;
    choose = false;
    playing=false;
    audioPlayer.currentTime=0;
    audioPlayer2.currentTime=0;
    if (audioPlayer.playing)
    {
        [audioPlayer stop];
    }
    if (audioPlayer2.playing)
    {
        [audioPlayer2 stop];
    }
    [self playMusic];
}

-(IBAction)playSong:(id)sender
{
    if ([self isSongListEmpty])
    {
        [self showNoSongMessage];
        return;
    }
    if (!audioPlayer.playing && !audioPlayer2.playing)
    {
        time = [self getTime];
        repeats = 0;
        audioPlayer.currentTime=0;
        audioPlayer2.currentTime=loopTime-delay;
        [audioPlayer play];
        [audioPlayer2 prepareToPlay];
        playing=true;
        if (!timer)
        {
            timer = [NSTimer scheduledTimerWithTimeInterval:.0001
                                                     target:self
                                                   selector:@selector(timeDec:)
                                                   userInfo:nil
                                                    repeats:YES];
        }
    }
}

-(IBAction)stopSong:(id)sender
{
    if ([self isSongListEmpty])
    {
        [self showNoSongMessage];
        return;
    }
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    playing=false;
    if (audioPlayer.playing)
    {
        [audioPlayer stop];
    }
    if (audioPlayer2.playing)
    {
        [audioPlayer2 stop];
    }
}

-(void)chooseSong:(NSString*)newSong
{
    playing=false;
    chooseSongString=true;
    choose=true;
    chooseSongText = newSong;
    [self playMusic];
}

-(IBAction)searchSong:(id)sender
{
    if ([self isSongListEmpty])
    {
        [self showNoSongMessage];
        return;
    }
    [self changeScreen:@"search"];
}

-(IBAction)settings:(id)sender
{
    settingsSongString = songName.text;
    [self changeScreen:@"settings"];
}

-(NSInteger)setLoopTime:(double)newLoopTime
{
    loopTime = newLoopTime;
    NSInteger result = [self updateDBResult:[NSString stringWithFormat:@"UPDATE Tracks SET loopstart = %f WHERE name = \"%@\"", newLoopTime, songName.text]];
    if (audioPlayer.playing)
    {
        audioPlayer2.currentTime = newLoopTime-delay;
        [audioPlayer2 prepareToPlay];
    }
    else if (audioPlayer2.playing)
    {
        audioPlayer.currentTime = newLoopTime-delay;
        [audioPlayer prepareToPlay];
    }
    return result;
}

-(long long)getTime
{
    gettimeofday(&t, nil);
    //returns time in microseconds
    return t.tv_sec * 1000000 + t.tv_usec;
}

-(void)setDelay:(float)newDelay
{
    delay = newDelay;
}

-(IBAction)close:(id)sender
{
}

-(void)setOccupied:(bool)newOccupied
{
    occupied = newOccupied;
}

-(NSString*)getSongName
{
    return songName.text;
}

-(void)setNewSongName:(NSString*)newName
{
    songName.text = newName;
}

-(double)getAudioDuration
{
    return audioPlayer.duration;
}

-(void)testTime
{
    double test = loopEnd-delay-5;
    if (test < 0)
    {
        test = 0;
    }
    [self setCurrentTime:test];
}

-(void)setCurrentTime:(double)newCurrentTime
{
    if (audioPlayer.playing)
    {
        [audioPlayer stop];
        audioPlayer.currentTime = newCurrentTime;
        [audioPlayer play];
    }
    else if (audioPlayer2.playing)
    {
        [audioPlayer2 stop];
        audioPlayer2.currentTime = newCurrentTime;
        [audioPlayer2 play];
    }
}

-(float)getVolume
{
    return volumeSet;
}

-(void)setVolume:(double)newVolume
{
    if (newVolume < 0 || newVolume > 1)
    {
        return;
    }
    audioPlayer.volume = newVolume;
    audioPlayer2.volume = newVolume;
    volumeSet = newVolume;
    [self updateVolumeDec];
    [self openUpdateDB:[NSString stringWithFormat:@"UPDATE Tracks SET volume = %f WHERE name = \"%@\"", newVolume, songName.text]];
}

-(float)findTime
{
    if (audioPlayer.playing)
    {
        return audioPlayer.currentTime;
    }
    else if (audioPlayer2.playing)
    {
        return audioPlayer2.currentTime;
    }
    else
    {
        return 0;
    }
}

-(IBAction)dim:(id)sender
{
    if (dim.on)
    {
        initBright = [UIScreen mainScreen].brightness;
        [UIScreen mainScreen].brightness = 0;
    }
    else
    {
        if (initBright < .011)
        {
            initBright = .3;
        }
        [UIScreen mainScreen].brightness = initBright;
    }
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)event
{
    //if it is a remote control event handle it correctly
    if (event.type == UIEventTypeRemoteControl)
    {
        if (event.subtype == UIEventSubtypeRemoteControlPlay)
        {
            [self playSong:nil];
        }
        else if (event.subtype == UIEventSubtypeRemoteControlPause)
        {
            [self stopSong:nil];
        }
        else if (event.subtype == UIEventSubtypeRemoteControlBeginSeekingBackward)
        {
            [self randomSong:nil];
        }
        else if (event.subtype == UIEventSubtypeRemoteControlBeginSeekingForward)
        {
            [self randomSong:nil];
        }
        
    }
}

-(double)getDelay
{
    return delay;
}

-(bool)getEnabled
{
    return enabled;
}

-(void)setInitBright:(float)newBright
{
    initBright = newBright;
}

-(float)getInitBright
{
    return initBright;
}

-(double)timeVariance
{
    return (((double)((int)(arc4random() % 60 - 30)))/60.0 + timeShuffle) * 60000000.0;
}

- (void)onKeyboardDidHide:(NSNotification *)notification
{
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

//Screen changing helpers

-(IBAction)changeScreen:(NSString*)screen
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main"
                                                         bundle:nil];
    UIViewController *newVC = [storyboard instantiateViewControllerWithIdentifier:screen];
    [self presentViewController:newVC
                       animated:true
                     completion:nil];
}

-(IBAction)back:(id)sender
{
    [self dismissViewControllerAnimated:true completion:nil];
}

//Database helpers

-(void)openDB
{
    NSInteger result = sqlite3_open([[[NSString alloc] initWithString:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent: @"Tracks.db"]] UTF8String], &trackData);
}

-(void)prepareQuery:(NSString*)query
{
    sqlite3_prepare_v2(trackData, [query UTF8String], -1, &statement, NULL);
}

-(void)updateDB:(NSString*)query
{
    sqlite3_stmt *tempStatement;
    sqlite3_prepare_v2(trackData, [query UTF8String], -1, &tempStatement, NULL);
    NSInteger result = sqlite3_step(tempStatement);
    if (result != 101)
    {
        NSLog(@"Database query %@ errored (%ld).", query, (long)result);
    }
    sqlite3_finalize(tempStatement);
}

-(void)openUpdateDB:(NSString*)query
{
    [self openDB];
    [self updateDB:query];
    sqlite3_close(trackData);
}

-(NSInteger)updateDBResult:(NSString*)query
{
    [self openDB];
    [self prepareQuery:query];
    NSInteger returnValue = sqlite3_step(statement);
    sqlite3_finalize(statement);
    sqlite3_close(trackData);
    return returnValue;
}

-(NSInteger)initializeTotalSongs
{
    [self prepareQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM Tracks"]];
    sqlite3_step(statement);
    const char* countText = (const char *) sqlite3_column_text(statement, 0);
    if (countText)
    {
        totalSongs = [[[NSString alloc] initWithUTF8String:countText] integerValue];
        sqlite3_finalize(statement);
    }
    else
    {
        sqlite3_finalize(statement);
        // Table doesn't exist; create it.
        [self updateDB:@"CREATE TABLE Tracks (id integer PRIMARY KEY, name text, loopstart numeric, loopend numeric, volume numeric, enabled integer, url text)"];
        totalSongs = 0;
    }
    return totalSongs;
}

-(void)incrementTotalSongs
{
    totalSongs++;
}

-(void)decrementTotalSongs
{
    totalSongs--;
}

-(NSMutableArray*)getSongList
{
    NSMutableArray *songs;
    NSString *songListName;
    [self openDB];
    totalSongs = [self initializeTotalSongs];
    for (NSInteger i = 0; i<totalSongs; i++)
    {
        [self prepareQuery:[NSString stringWithFormat:@"SELECT name FROM Tracks ORDER BY id LIMIT 1 OFFSET \"%li\"", (long)i]];
        if (sqlite3_step(statement) == SQLITE_ROW)
        {
            songListName = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 0)];
            if (i==0)
            {
                songs = [NSMutableArray arrayWithObjects:songListName,nil];
            }
            else
            {
                [songs addObject:songListName];
            }
        }
        sqlite3_finalize(statement);
    }
    sqlite3_close(trackData);
    [songs sortUsingSelector:@selector(compare:)];
    return songs;
}

-(bool)isSongListEmpty
{
    return !totalSongs;
}

-(void)showErrorMessage:(NSString*)message
{
    if (NSClassFromString(@"UIAlertController"))
    {
        UIAlertController *error = [UIAlertController alertControllerWithTitle:@"Error"
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Okay", @"OK action")
                                                                style:UIAlertActionStyleDefault
                                                              handler:nil];
        [error addAction:defaultAction];
        [self presentViewController:error animated:YES completion:nil];
    }
    else
    {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:@"Okay"
                                              otherButtonTitles: nil];
        [alert show];
    }
}

-(void)showNoSongMessage
{
    [self showErrorMessage:@"You need to add a song first."];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
