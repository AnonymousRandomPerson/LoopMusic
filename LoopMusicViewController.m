//
//  LoopMusicViewController.m
//  LoopMusic
//
//  Created by Cheng Hann Gan on 12/24/13.
//  Copyright (c) 2013 Cheng Hann Gan. All rights reserved.
//

#import "LoopMusicViewController.h"

/// The name of the current track.
NSString *settingsSongString = @"";
/// The base amount of time to play a track before shuffling.
double timeShuffle = -1;
/// The actual amount of time to play a track before shuffling.
double timeShuffle2 = -1;
/// The number of times to repeat a track before shuffling.
NSInteger repeatsShuffle = -1;
/// The setting for how to shuffle tracks.
NSUInteger shuffleSetting = 0;
/// The amount of time to fade out a track before shuffling.
double fadeSetting = 0;
/// The index of the currently selected playlist.
NSInteger playlistIndex = 0;

/// The amount of time that time shuffle can vary by.
static const int TIMEVARIANCE = 30;
/// The time before the loop point that testing time will move the playback timer to.
static const double TESTTIMEOFFSET = 5;

@interface LoopMusicViewController ()

@end

@implementation LoopMusicViewController

@synthesize searchSong, playSong, randomSong, stopSong, songName, settings;

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
    
    // Check if the playlist table has been created.
    [self updateDB:@"CREATE TABLE IF NOT EXISTS Playlists (id integer PRIMARY KEY, name text, tracks text)"];
    [self prepareQuery:@"SELECT id from Playlists where name = \"All tracks\""];
    if (sqlite3_step(statement) != SQLITE_ROW)
    {
        [self updateDB:@"INSERT INTO Playlists VALUES (0, \"All tracks\", \"\")"];
    }
    sqlite3_finalize(statement);
    
    sqlite3_close(trackData);
    // Set up audio player.
    audioPlayer = [[AudioPlayer alloc] init];
    
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    choose = false;
    songString = @"";
    chooseSongString = false;
    time = [self getTime];
    [self activateShuffleTimer];
    repeats = 0;
    musicNumber = -1;
    
    /// The file path of the settings file.
    NSString *filePath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"Settings.txt"];
    /// The contents of the settings file.
    NSString *contentOfFile = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    if (contentOfFile)
    {
        /// The contents of the settings file, split into individual settings.
        NSArray *splitSettings = [contentOfFile componentsSeparatedByString:@","];
        shuffleSetting = [splitSettings[0] integerValue];
        timeShuffle = [splitSettings[1] doubleValue];
        timeShuffle2 = [self timeVariance];
        repeatsShuffle = [splitSettings[2] integerValue];
        fadeSetting = splitSettings.count > 3 ? [splitSettings[3] doubleValue] : 0;
        playlistIndex = splitSettings.count > 4 ? [splitSettings[4] integerValue] : 0;
    }
    else
    {
        // Default values.
        shuffleSetting = 1;
        timeShuffle = 3.5;
        timeShuffle2 = [self timeVariance];
        repeatsShuffle = 3;
        fadeSetting = 2;
        playlistIndex = 0;
        /// The text to write to the new settings file.
        NSString *newSettings = [NSString stringWithFormat:@"%lu,%f,%li,%f,%li", (unsigned long)shuffleSetting, timeShuffle, (long)repeatsShuffle, fadeSetting, (long)playlistIndex];
        [newSettings writeToFile:filePath atomically:true encoding:NSUTF8StringEncoding error:nil];
    }
    if (playlistIndex)
    {
        [self updatePlaylistSongs];
        [self updatePlaylistName];
    }
    
    [self playMusic];
}

/*!
 * Activates the shuffle loop timer.
 * @return
 */
- (void)activateShuffleTimer
{
    [self stopShuffleTimer];
    shuffleTimer = [NSTimer scheduledTimerWithTimeInterval:2
                                                    target:self
                                                  selector:@selector(checkShuffle:)
                                                  userInfo:nil
                                                   repeats:YES];
}

/*!
 * Activates the fade out timer.
 * @return
 */
- (void)activateFadeTimer
{
    [self stopFadeTimer];
    fadeTimer = [NSTimer scheduledTimerWithTimeInterval:0.01
                                                target:self
                                               selector:@selector(fadeOut:)
                                               userInfo:nil
                                                repeats:YES];
}

/*!
 * Stops the shuffle loop timer.
 * @return
 */
- (void)stopShuffleTimer
{
    if (shuffleTimer)
    {
        [shuffleTimer invalidate];
        shuffleTimer = nil;
    }
}

/*!
 * Stops the fade out timer.
 * @return
 */
- (void)stopFadeTimer
{
    if (fadeTimer)
    {
        [fadeTimer invalidate];
        fadeTimer = nil;
    }
}

/*!
 * Checks if the audio track should be shuffled.
 * @param timer The timer that invoked this function.
 * @return
 */
- (void)checkShuffle:(NSTimer *)timer
{
    if (audioPlayer.playing)
    {
        if (!occupied)
        {
            bool willSwitch = false;
            if (shuffleSetting == 2 && repeatsShuffle > 0 && repeats >= repeatsShuffle)
            {
                willSwitch = true;
            }
            else if (shuffleSetting == 1 && timeShuffle > 0 && ([self getTime] - time) >= timeShuffle2)
            {
                willSwitch = true;
            }
            if (willSwitch)
            {
                if (fadeSetting <= 0)
                {
                    [self shuffleTrack];
                }
                else if (!fadeTimer)
                {
                    [self activateFadeTimer];
                }
            }
        }
    }
}

/*!
 * Gradually fades out a track.
 * @param The timer that invoked this function.
 * @return
 */
- (void)fadeOut:(NSTimer *)timer
{
    if (++fadeTime > fadeSetting * 100)
    {
        [self shuffleTrack];
        [self stopFadeTimer];
    }
    else if (audioPlayer.volume > 0)
    {
        audioPlayer.volume -= volumeDec;
    }
}

/*!
 * Shuffles the currently playing track.
 * @return
 */
- (void)shuffleTrack
{
    time = [self getTime];
    choose = false;
    [self playMusic];
}

- (void)playMusic
{
    if ([self isSongListEmpty])
    {
        return;
    }
    if (!playlistIndex || !totalPlaylistSongs)
    {
        totalPlaylistSongs = totalSongs;
    }
    valid = false;
    audioPlayer.loading = true;
    
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
                audioPlayer.loopStart = 0;
                audioPlayer.loopEnd = 0;
                volumeSet = 0.3;
                enabled = 1;
                [self updateDB:[NSString stringWithFormat:@"UPDATE Tracks SET loopstart = %f WHERE name = \"%@\"", audioPlayer.loopStart, nameField]];
                [self updateDB:[NSString stringWithFormat:@"UPDATE Tracks SET loopend = 0 WHERE name = \"%@\"", nameField]];
                [self updateDB:[NSString stringWithFormat:@"UPDATE Tracks SET volume = 0.3 WHERE name = \"%@\"", nameField]];
                [self updateDB:[NSString stringWithFormat:@"UPDATE Tracks SET enabled = 1 WHERE name = \"%@\"", nameField]];
            }
            else
            {
                audioPlayer.loopStart = sqlite3_column_double(statement, 2);
                audioPlayer.loopEnd = sqlite3_column_double(statement, 3);
                volumeSet = sqlite3_column_double(statement, 4);
                enabled = sqlite3_column_int(statement, 5);
                if (sqlite3_column_text(statement, 6)) {
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
    // If chosen song text is a number.
    else
    {
        do
        {
            /// Random number to choose a new track with.
            NSInteger random = -1;
            do
            {
                random = arc4random() % totalPlaylistSongs;
                if (playlistIndex)
                {
                    NSArray *splitSongs = [self getSongIndices];
                    if (splitSongs && splitSongs.count > random)
                    {
                        random = [[splitSongs objectAtIndex:random] integerValue];
                    }
                }
            } while (musicNumber == random && totalPlaylistSongs != 1);
            musicNumber = random;
            timeShuffle2 = [self timeVariance];
            if (playlistIndex)
            {
                [self prepareQuery:[NSString stringWithFormat:@"SELECT * FROM Tracks WHERE id = %li", (long)musicNumber]];
            }
            else
            {
                [self prepareQuery:[NSString stringWithFormat:@"SELECT * FROM Tracks ORDER BY id LIMIT 1 OFFSET \"%li\"", (long)musicNumber]];
            }
            if (sqlite3_step(statement) == SQLITE_ROW)
            {
                idField = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 0)];
                nameField = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 1)];
                audioPlayer.loopStart = sqlite3_column_double(statement, 2);
                audioPlayer.loopEnd = sqlite3_column_double(statement, 3);
                volumeSet = sqlite3_column_double(statement, 4);
                enabled = sqlite3_column_int(statement, 5);
                if (sqlite3_column_text(statement, 6))
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
    [self setAudioPlayer:url];
    [self updateVolumeDec];
    repeats = 0;
    fadeTime = 0;
    time = [self getTime];
    if (audioPlayer.loopEnd == 0.0)
    {
        audioPlayer.loopEnd = audioPlayer.duration;
        [self openDB];
        [self updateDB:[NSString stringWithFormat:@"UPDATE Tracks SET loopend = %f WHERE id=\"%li\"", audioPlayer.loopEnd, (long)musicNumber]];
    }
    [audioPlayer play];
    [self activateShuffleTimer];
}

- (void)setAudioPlayer:(NSURL*)newURL
{
    // Change audio player settings.
    /// Data about errors that occur when initializing the audio players.
    NSError *error;
    [audioPlayer initAudioPlayer:newURL
                                :error];
    if (error)
    {
        NSLog(@"%@", [error description]);
        return;
    }
    audioPlayer.volume = volumeSet;
}

- (void)updateVolumeDec
{
    volumeDec = fadeSetting > 0 ? volumeSet / (fadeSetting * 100) : 0;
}

- (IBAction)randomSong:(id)sender
{
    if ([self isSongListEmpty])
    {
        [self showNoSongMessage];
        return;
    }
    time = [self getTime];
    repeats = 0;
    choose = false;
    [self playMusic];
}

- (IBAction)playSong:(id)sender
{
    if ([self isSongListEmpty])
    {
        [self showNoSongMessage];
        return;
    }
    if (!audioPlayer.playing)
    {
        time = [self getTime];
        repeats = 0;
        audioPlayer.currentTime = 0;
        [audioPlayer play];
        [self activateShuffleTimer];
    }
}

- (IBAction)stopSong:(id)sender
{
    if ([self isSongListEmpty])
    {
        [self showNoSongMessage];
        return;
    }
    [self stopPlayer];
}

/*!
 * Stops the audio player.
 * @return
 */
- (void)stopPlayer
{
    [audioPlayer stop];
    [self stopShuffleTimer];
    [self stopFadeTimer];
}

- (void)chooseSong:(NSString *)newSong
{
    chooseSongString = true;
    choose = true;
    chooseSongText = newSong;
    [self playMusic];
}

- (IBAction)searchSong:(id)sender
{
    if ([self isSongListEmpty])
    {
        [self showNoSongMessage];
        return;
    }
    [self changeScreen:@"search"];
}

- (IBAction)settings:(id)sender
{
    settingsSongString = songName.text;
    [self changeScreen:@"settings"];
}

- (IBAction)loopFinder:(id)sender
{
    if ([self isSongListEmpty])
    {
        [self showNoSongMessage];
    }
    else
    {
        [self changeScreen:@"loopFinder"];
    }
}

- (NSInteger)setLoopTime:(double)newLoopTime
{
    audioPlayer.loopStart = newLoopTime;
    /// The result code of the database update query for setting the loop time.
    NSInteger result = [self updateDBResult:[NSString stringWithFormat:@"UPDATE Tracks SET loopstart = %f WHERE name = \"%@\"", newLoopTime, songName.text]];
    return result;
}

/*!
 * Gets the current system time in microseconds.
 * @return The current system time in microseconds.
 */
- (long long)getTime
{
    /// Used to get the current system time.
    struct timeval t;
    gettimeofday(&t, nil);
    return t.tv_sec * 1000000 + t.tv_usec;
}

- (void)setOccupied:(bool)newOccupied
{
    occupied = newOccupied;
    if (occupied)
    {
        audioPlayer.volume = volumeSet;
    }
}

- (NSString *)getSongName
{
    return songName.text;
}

- (void)setNewSongName:(NSString *)newName
{
    songName.text = newName;
}

- (double)getAudioDuration
{
    return audioPlayer.duration;
}

- (void)testTime
{
    double test = audioPlayer.loopEnd - TESTTIMEOFFSET;
    if (test < 0)
    {
        test = 0;
    }
    [self setCurrentTime:test];
}

- (void)setCurrentTime:(double)newCurrentTime
{
    audioPlayer.currentTime = newCurrentTime;
}

- (float)getVolume
{
    return volumeSet;
}

- (void)setVolume:(double)newVolume
{
    if (newVolume < 0 || newVolume > 1)
    {
        return;
    }
    audioPlayer.volume = newVolume;
    volumeSet = newVolume;
    [self updateVolumeDec];
    [self openUpdateDB:[NSString stringWithFormat:@"UPDATE Tracks SET volume = %f WHERE name = \"%@\"", newVolume, songName.text]];
}

- (float)findTime
{
    if (audioPlayer.playing)
    {
        return audioPlayer.currentTime;
    }
    else
    {
        return 0;
    }
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)event
{
    // If it is a remote control event, handle it correctly.
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

- (double)timeVariance
{
    return (((double)((int)(arc4random() % 60 - TIMEVARIANCE))) / 60.0 + timeShuffle) * 60000000.0;
}

// Screen changing helpers.

- (IBAction)changeScreen:(NSString *)screen
{
    /// The storyboard for the app.
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main"
                                                         bundle:nil];
    /// The view controller to change to.
    UIViewController *newVC = [storyboard instantiateViewControllerWithIdentifier:screen];
    [self presentViewController:newVC
                       animated:true
                     completion:nil];
}

- (IBAction)back:(id)sender
{
    [self dismissViewControllerAnimated:true completion:nil];
}

// Database helpers

- (void)openDB
{
    sqlite3_open([[[NSString alloc] initWithString:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent: @"Tracks.db"]] UTF8String], &trackData);
}

- (void)prepareQuery:(NSString *)query
{
    sqlite3_prepare_v2(trackData, [query UTF8String], -1, &statement, NULL);
}

- (void)updateDB:(NSString *)query
{
    /// The statement to execute the query with.
    sqlite3_stmt *tempStatement;
    sqlite3_prepare_v2(trackData, [query UTF8String], -1, &tempStatement, NULL);
    /// The result code for the query.
    NSInteger result = sqlite3_step(tempStatement);
    if (result != 101)
    {
        NSLog(@"Database query %@ errored (%ld).", query, (long)result);
    }
    sqlite3_finalize(tempStatement);
}

- (NSInteger)getIntegerDB:(NSString *)query
{
    /// The statement to execute the query with.
    sqlite3_stmt *tempStatement;
    sqlite3_prepare_v2(trackData, [query UTF8String], -1, &tempStatement, NULL);
    /// The integer obtained from the query.
    NSInteger returnValue = -1;
    if (sqlite3_step(tempStatement) == SQLITE_ROW)
    {
        returnValue = sqlite3_column_int(tempStatement, 0);
    }
    sqlite3_finalize(tempStatement);
    return returnValue;
}

/*!
 * Gets a string from a database query.
 * @param query The query to get a string from.
 * @return The string obtained from the query.
 */
- (NSString *)getStringDB:(NSString *)query
{
    /// The statement to execute the query with.
    sqlite3_stmt *tempStatement;
    sqlite3_prepare_v2(trackData, [query UTF8String], -1, &tempStatement, NULL);
    /// The string obtained from the query.
    NSString *returnValue = @"";
    if (sqlite3_step(tempStatement) == SQLITE_ROW)
    {
        returnValue = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(tempStatement, 0)];
    }
    sqlite3_finalize(tempStatement);
    return returnValue;
}

- (void)openUpdateDB:(NSString *)query
{
    [self openDB];
    [self updateDB:query];
    sqlite3_close(trackData);
}

- (NSInteger)updateDBResult:(NSString *)query
{
    [self openDB];
    [self prepareQuery:query];
    NSInteger returnValue = sqlite3_step(statement);
    sqlite3_finalize(statement);
    sqlite3_close(trackData);
    return returnValue;
}

- (NSInteger)initializeTotalSongs
{
    [self prepareQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM Tracks"]];
    sqlite3_step(statement);
    /// The number of tracks in the database.
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
    totalPlaylistSongs = totalSongs;
    return totalSongs;
}

- (void)incrementTotalSongs
{
    totalSongs++;
    if (!playlistIndex)
    {
        totalPlaylistSongs = totalSongs;
    }
}

- (void)decrementTotalSongs
{
    totalSongs--;
    if (!playlistIndex)
    {
        totalPlaylistSongs = totalSongs;
    }
}

- (void)incrementPlaylistSongs
{
    totalPlaylistSongs++;
}

- (void)decrementPlaylistSongs
{
    totalPlaylistSongs--;
}

- (void)updatePlaylistSongs
{
    [self openDB];
    /// All tracks in the playlist.
    NSArray *songList = [self getSongIndices];
    totalPlaylistSongs = songList ? songList.count : 0;
    sqlite3_close(trackData);
}

- (NSString *)getPlaylistName
{
    if ([playlistName.text isEqualToString:@"All tracks"])
    {
        return @"All tracks";
    }
    else
    {
        return playlistName.text;
    }
}

- (void)updatePlaylistName
{
    if (playlistIndex)
    {
        [self openDB];
        /// The name of the current playlist.
        NSString * newName = [self getStringDB:[NSString stringWithFormat:@"SELECT name FROM Playlists where id = %ld", (long)playlistIndex]];
        [self updatePlaylistName:newName];
        sqlite3_close(trackData);
        if ([newName isEqualToString:@""])
        {
            playlistIndex = 0;
            [self updatePlaylistSongs];
        }
    }
    else
    {
        [self updatePlaylistName:@""];
    }
}

- (void)updatePlaylistName:(NSString *)name
{
    if (name && ![name isEqualToString:@"All tracks"])
    {
        playlistName.text = name;
    }
    else
    {
        playlistName.text = @"";
    }
}

- (NSArray*)getSongIndices
{
    /// The IDs of all tracks in the current playlist.
    NSArray *splitSongs = nil;
    [self prepareQuery:[NSString stringWithFormat:@"SELECT tracks FROM Playlists WHERE id = %ld", (long)playlistIndex]];
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        /// The database string containing the current playlist's track IDs.
        NSString *trackString = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 0)];
        splitSongs = [trackString componentsSeparatedByString:@","];
    }
    sqlite3_finalize(statement);
    if (splitSongs.count == 1 && [[splitSongs objectAtIndex:0] isEqualToString:@""])
    {
        return nil;
    }
    return splitSongs;
}

- (NSMutableArray*)getSongList
{
    if (!playlistIndex)
    {
        return [self getTotalSongList];
    }
    else
    {
        /// The names of all tracks in the current playlist.
        NSMutableArray *songs;
        /// The name of the track in the current iteration.
        NSString *songListName;
        [self openDB];
        /// The IDs of all tracks in the current playlist.
        NSArray* splitSongs = [self getSongIndices];
        if (!splitSongs)
        {
            sqlite3_close(trackData);
            return [NSMutableArray arrayWithCapacity:0];
        }
        for (NSInteger i = 0; i < splitSongs.count; i++)
        {
            /// The ID of the track in the current iteration.
            NSString *trackIndex = [splitSongs objectAtIndex:i];
            [self prepareQuery:[NSString stringWithFormat:@"SELECT name FROM Tracks WHERE id = \"%@\"", trackIndex]];
            if (sqlite3_step(statement) == SQLITE_ROW)
            {
                songListName = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 0)];
                if (!songs)
                {
                    songs = [NSMutableArray arrayWithObjects:songListName, nil];
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
}

/*!
 * Gets the names of all entries in a table.
 * @param table The name of the table to get entries from.
 * @return An array containing the names of all entries in a table.
 */
- (NSMutableArray*)getNameList:(NSString *)table
{
    /// The names of all entries in a table.
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:8];
    /// The name of the item in the current iteration.
    NSString *itemListName;
    [self openDB];
    [self prepareQuery:[NSString stringWithFormat:@"SELECT name FROM %@ ORDER BY name", table]];
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        itemListName = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 0)];
        [items addObject:itemListName];
    }
    sqlite3_finalize(statement);
    sqlite3_close(trackData);
    return items;
}

- (NSMutableArray*)getTotalSongList
{
    return [self getNameList:@"Tracks"];
}

- (bool)isSongListEmpty
{
    return !totalSongs;
}

- (NSMutableArray*)getPlaylistList
{
    return [self getNameList:@"Playlists"];
}

- (void)showErrorMessage:(NSString *)message
{
    if (NSClassFromString(@"UIAlertController"))
    {
        /// The error dialogue being displayed.
        UIAlertController *error = [UIAlertController alertControllerWithTitle:@"Error"
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        /// The "Okay" button on the error dialogue.
        UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Okay", @"OK action")
                                                                style:UIAlertActionStyleDefault
                                                              handler:nil];
        [error addAction:defaultAction];
        [self presentViewController:error animated:YES completion:nil];
    }
    else
    {
        /// The error dialogue being displayed.
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:@"Okay"
                                              otherButtonTitles: nil];
        [alert show];
    }
}

- (void)showNoSongMessage
{
    [self showErrorMessage:@"You need to add a track first."];
}

- (void)showTwoButtonMessage:(NSString *)title :(NSString *)message :(NSString *)okay
{
    /// The message dialogue box to display.
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:okay, nil];
    alert.alertViewStyle = UIAlertViewStyleDefault;
    [alert show];
}

- (void)showTwoButtonMessageInput:(NSString *)title :(NSString *)message :(NSString *)okay :(NSString *)initText
{
    /// The message dialogue box to display.
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:okay, nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    if (initText)
    {
        [alert textFieldAtIndex:0].text = initText;
    }
    [alert show];
}

- (void)didReceiveMemoryWarning
{
    NSLog(@"Low on memory!");
    [super didReceiveMemoryWarning];
}

@end
