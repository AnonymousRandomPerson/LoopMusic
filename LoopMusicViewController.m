//
//  LoopMusicViewController.m
//  LoopMusic
//
//  Created by Cheng Hann Gan on 12/24/13.
//  Copyright (c) 2013 Cheng Hann Gan. All rights reserved.
//

#import "LoopMusicViewController.h"
#import "SettingsStore.h"

/// The name of the current track.
NSString *settingsSongString = @"";

/// The time before the loop point that testing time will move the playback timer to.
static const double TEST_TIME_OFFSET = 5;

@interface LoopMusicViewController ()

@end

@implementation LoopMusicViewController

@synthesize searchSong, playSong, randomSong, stopSong, songName, settings, fftSetup, nSetup, playSlider;

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
//    [self updateDB:@"DROP TABLE IF EXISTS Playlists"];    // For updating from old version
    [self updateDB:@"CREATE TABLE IF NOT EXISTS PlaylistNames (id integer PRIMARY KEY, name text)"];
    [self updateDB:@"CREATE TABLE IF NOT EXISTS Playlists (rowkey integer PRIMARY KEY, id integer, track integer)"];
    
    [self prepareQuery:@"SELECT id from PlaylistNames where name = \"All tracks\""];
    if (sqlite3_step(statement) != SQLITE_ROW)
    {
        [self updateDB:@"INSERT INTO PlaylistNames VALUES (0, \"All tracks\")"];
    }
    sqlite3_finalize(statement);
    
    sqlite3_close(trackData);
    // Set up audio player.
    audioPlayer = [[AudioPlayer alloc] init];
    
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    choose = false;
    songString = @"";
    chooseSongString = false;
    musicNumber = -1;

    volumeSlider.value = SettingsStore.instance.masterVolume;
    [self setGlobalVolume:nil];
    if (SettingsStore.instance.playlistIndex)
    {
        [self updatePlaylistSongs];
        [self updatePlaylistName];
    }
    
    // Set up the play slider with the audio player.
    __weak typeof(self) weakSelf = self;
    playSlider.getCurrentTime = ^float (void) { return [weakSelf findTime]; };
    [playSlider highlightLoopRegion];
    
// Load local test files from the testSongs/ directory if testing on the simulator
#if TARGET_OS_SIMULATOR
    NSString *localDir = @"testSongs/";
    if (![self isSongListEmpty])
    {
        // Wipe the tables clean before proceeding
        [self wipeDB];
    }
    
    
    // RETRIEVING LOCAL RESOURCES
    NSBundle *mainBundle;
    mainBundle = [NSBundle mainBundle];
    
    NSArray *localTestTracks = [mainBundle pathsForResourcesOfType:nil inDirectory:localDir];
    NSArray *localTestTrackURLs = [mainBundle URLsForResourcesWithExtension:nil subdirectory:localDir];
    NSUInteger nLocalTracks = localTestTracks.count;
    
    if (nLocalTracks > 0)
    {
        NSLog(@"Simulator: Loading test tracks...");
        [self openDB];
        int counter = 0;
        for (int trk = 0; trk < nLocalTracks; ++trk)
        {
            // Get the track name and display it
            NSUInteger slashLocation = [localTestTracks[trk] rangeOfString:@"/" options:NSBackwardsSearch].location;
            NSString *trackName = [localTestTracks[trk] substringFromIndex:slashLocation+1];
            NSUInteger dotLocation = [trackName rangeOfString:@"." options:NSBackwardsSearch].location;
            trackName = [trackName substringToIndex:dotLocation];
            
            // Ignore the README file
            if ([trackName isEqualToString:@"README"])
            {
                continue;
            }
            ++counter;
            
            NSLog(@"Track %i: %@", counter, trackName);
            
            // Load the track into the database with its URL
            [self addSongToDB:trackName :localTestTrackURLs[trk]];
        }
        sqlite3_close(trackData);
        NSLog(@"%ld track(s) loaded.", totalSongs);
    }
#endif
    
    // Setup a preliminary FFT for vDSP.
    fftSetup = vDSP_create_fftsetup(0, kFFTRadix2);
    nSetup = 1;
    
    [self playMusic];
}

/*!
 * Activates the shuffle loop timer.
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
 * Stops an active timer.
 * @param timer Pointer to timer pointer. The inner pointer will be invalidated.
 */
- (void)stopTimer:(NSTimer *__strong*)timer
{
    if (*timer)
    {
        [*timer invalidate];
        *timer = nil;
    }
}

/*!
 * Stops the shuffle loop timer.
 */
- (void)stopShuffleTimer
{
    [self stopTimer:&shuffleTimer];
}

/*!
 * Stops the fade out timer. Also reset the fade time counter.
 */
- (void)stopFadeTimer
{
    [self stopTimer:&fadeTimer];
    fadeTime = 0;
}


/*!
 * Checks if the audio track should be shuffled.
 * @param timer The timer that invoked this function.
 */
- (void)checkShuffle:(NSTimer *)timer
{
    if (audioPlayer.playing)
    {
        if (!occupied)
        {
            bool willSwitch = false;
            if (SettingsStore.instance.shuffleSetting == REPEATS && SettingsStore.instance.repeatsShuffle > 0 && [self getRepeats] >= currentShuffleRepeats)
            {
                willSwitch = true;
            }
            else if (SettingsStore.instance.shuffleSetting == TIME && SettingsStore.instance.timeShuffle > 0 && [self getElapsedTime] >= currentShuffleTime)
            {
                willSwitch = true;
            }
            if (willSwitch)
            {
                if (SettingsStore.instance.fadeSetting <= 0)
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
 * @param timer The timer that invoked this function.
 */
- (void)fadeOut:(NSTimer *)timer
{
    if (++fadeTime > SettingsStore.instance.fadeSetting * 100)
    {
        [self shuffleTrack];
        [self stopFadeTimer];
    }
    else if (audioPlayer.volume > 0)
    {
        [audioPlayer decrementVolume:volumeDec];
    }
}

/*!
 * Starts tracking and playback of the audio player.
 */
- (void)startPlayback
{
    time = [self getTime];
    [audioPlayer play];
    [self activateShuffleTimer];
    // Only update the play slider if on the main screen.
    if (!occupied)
        [playSlider activateUpdateTimer];
    playSymbol.hidden = false;
}

/*!
 * Cleans up internal values affecting playback, after a stop or before a new song. (Used in playMusic, stopPlayer)
 */
- (void)resetForNewPlayback
{
    [audioPlayer resetLoopCounter];
    [self stopFadeTimer];   // Stop fade if happening, and reset the fade time counter.
    audioPlayer.pauseTime = 0;
    elapsedTimeBeforeTimerActivation = 0;
}

/*!
 * Shuffles the currently playing track.
 */
- (void)shuffleTrack
{
    choose = false;
    [self playMusic];
}

- (void)playMusic
{
    if ([self isSongListEmpty])
    {
        playSlider.maximumValue = 0;    // Prevents any sliding
        return;
    }
    if (!SettingsStore.instance.playlistIndex || !totalPlaylistSongs)
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
                [self updateDB:[NSString stringWithFormat:@"UPDATE Tracks SET loopstart = %f WHERE name = \"%@\"", audioPlayer.loopStart, nameField]];
                [self updateDB:[NSString stringWithFormat:@"UPDATE Tracks SET loopend = 0 WHERE name = \"%@\"", nameField]];
                [self updateDB:[NSString stringWithFormat:@"UPDATE Tracks SET volume = 0.3 WHERE name = \"%@\"", nameField]];
            }
            else
            {
                audioPlayer.loopStart = sqlite3_column_double(statement, 2);
                audioPlayer.loopEnd = sqlite3_column_double(statement, 3);
                volumeSet = sqlite3_column_double(statement, 4);
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
        if (!valid || url == nil)
        {
            sqlite3_close(trackData);
            return;
        }
    }
    // If chosen song text is a number.
    else
    {
        /// Random number to choose a new track with.
        NSInteger random = -1;
        do
        {
            random = arc4random_uniform(totalPlaylistSongs);
            NSArray *splitSongs = [self getSongIndices];
            if (splitSongs && splitSongs.count > random)
            {
                random = [[splitSongs objectAtIndex:random] integerValue];
            }
        } while (musicNumber == random && totalPlaylistSongs != 1);
        musicNumber = random;
        
        [self prepareQuery:[NSString stringWithFormat:@"SELECT * FROM Tracks WHERE id = %li", (long)musicNumber]];
        if (sqlite3_step(statement) == SQLITE_ROW)
        {
            idField = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 0)];
            nameField = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 1)];
            audioPlayer.loopStart = sqlite3_column_double(statement, 2);
            audioPlayer.loopEnd = sqlite3_column_double(statement, 3);
            volumeSet = sqlite3_column_double(statement, 4);
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
        sqlite3_finalize(statement);
        songName.text = nameField;
    }
    sqlite3_close(trackData);
    [self setAudioPlayer:url];
    [self updateVolumeDec];
    if (audioPlayer.loopEnd == 0.0)
    {
        audioPlayer.loopEnd = audioPlayer.duration;
        [self openDB];
        [self updateDB:[NSString stringWithFormat:@"UPDATE Tracks SET loopend = %f WHERE id=\"%li\"", audioPlayer.loopEnd, (long)musicNumber]];
    }
    [self recalculateShuffleTime];
    [self resetForNewPlayback];
    [self startPlayback];
    [self refreshPlaySlider];
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
- (void)refreshPlaySlider
{
    [playSlider setupNewTrack:audioPlayer.duration :audioPlayer.loopStart :audioPlayer.loopEnd];
}
- (void)setAudioLoopStart:(NSTimeInterval)newStart
{
    audioPlayer.loopStart = newStart;
    playSlider.loopStart = audioPlayer.loopStart;
}
- (void)setAudioLoopEnd:(NSTimeInterval)newEnd
{
    audioPlayer.loopEnd = newEnd;
    playSlider.loopEnd = audioPlayer.loopEnd;
}
- (UInt32)getAudioLoopStartFrame
{
    return [audioPlayer loopStartFrame];
}
- (NSTimeInterval)getAudioLoopStart
{
    return audioPlayer.loopStart;
}
- (UInt32)getAudioLoopEndFrame
{
    return [audioPlayer loopEndFrame];
}
- (NSTimeInterval)getAudioLoopEnd
{
    return audioPlayer.loopEnd;
}


- (void)updateVolumeDec
{
    volumeDec = SettingsStore.instance.fadeSetting > 0 ? volumeSet / (SettingsStore.instance.fadeSetting * 100) : 0;
}

- (IBAction)randomSong:(id)sender
{
    if ([self isSongListEmpty])
    {
        [self showNoSongMessage];
        return;
    }

    [self shuffleTrack];
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
        [self startPlayback];
    }
}

- (IBAction)pauseSong:(id)sender
{
    if ([self isSongListEmpty])
    {
        [self showNoSongMessage];
        return;
    }
    [self pausePlayer];
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

- (void)controllerStopPlaying
{
    [self stopShuffleTimer];
    [self stopFadeTimer];
    [playSlider stopUpdateTimer];
    playSymbol.hidden = true;
}

/*!
 * Pauses the audio player.
 */
- (void)pausePlayer
{
    elapsedTimeBeforeTimerActivation += [self getTime] - time;
    [audioPlayer pause];
    [self controllerStopPlaying];
}
/*!
 * Stops the audio player.
 */
- (void)stopPlayer
{
    [audioPlayer stop];
    [self controllerStopPlaying];
    [playSlider stop];
    [self resetForNewPlayback];
}

- (IBAction)playSliderTouchDown:(id)sender
{
    [playSlider stopUpdateTimer];
}
- (IBAction)playSliderTouchUp:(id)sender
{
    if (audioPlayer.playing)
        [playSlider activateUpdateTimer];
}
- (IBAction)playSliderUpdate:(id)sender
{
    if ([self isSongListEmpty])
        return;
    
    [playSlider updateAudioPlayer:audioPlayer]; // Update the audio player time.
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
        [self changeScreen:@"looperParent"];
    }
}

- (IBAction)setGlobalVolume:(id)sender
{
    float scaledVolume = 0;
    float unscaledVolume = [self getVolumeSliderValue];
    if (unscaledVolume > volumeSlider.minimumValue)
    {
        scaledVolume = pow(2.0, unscaledVolume);
    }
    audioPlayer.globalVolume = scaledVolume;
}

- (IBAction)saveGlobalVolume:(id)sender
{
    SettingsStore.instance.masterVolume = [self getVolumeSliderValue];
    [self saveSettings];
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
/*!
 * Gets the elapsed playback time (in microseconds) of the current track.
 * @return The elapsed playback time.
 */
- (double)getElapsedTime
{
    return [self getTime] - time + elapsedTimeBeforeTimerActivation;
}
/*!
 * Gets the number of repeats of the current track.
 * @return The current number of repeats.
 */
- (double)getRepeats
{
    // Use a more robust time-based method, rather than a loop-based method. This allows for jumping around in playback, while still having around the desired number of repeats in playback time.
    return [audioPlayer getRepeatNumber:[self getElapsedTime] * 1e-6];
}

- (void)setOccupied:(bool)newOccupied
{
    occupied = newOccupied;
    if (occupied)
    {
        // Temporarily stop the fade, if happening. The timer will be restarted when updates resume
        [self stopFadeTimer];
        audioPlayer.volume = volumeSet;
        // Stop updating the play slider.
        [playSlider stopUpdateTimer];
    }
    else
    {
        // Start updating the play slider again.
        [playSlider setTime:[self findTime]]; // Refresh once right away, before starting the timer for subsequent calls.
        [playSlider activateUpdateTimer];
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

- (AudioData *)getAudioData
{
    return [audioPlayer getAudioData];
}

- (UInt32)getAudioFrameDuration
{
    return [audioPlayer frameDuration];
}
- (double)getAudioDuration
{
    return audioPlayer.duration;
}

- (NSMutableArray *)audioFindLoopTime
{
    return [audioPlayer findLoopTime];
}

- (void)testTime
{
    double test = audioPlayer.loopEnd - TEST_TIME_OFFSET;
    if (test < 0)
    {
        test = 0;
    }
    [self playSong:nil];    // Starts playback if not playing already.
    [self setCurrentTime:test];
}

- (void)setCurrentTime:(double)newCurrentTime
{
    audioPlayer.currentTime = newCurrentTime;
    [playSlider forceSetTime:audioPlayer.currentTime];
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
    return audioPlayer.currentTime;
}

- (bool)isPlaying
{
    return audioPlayer.playing;
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

- (void)recalculateShuffleTime
{
    if (SettingsStore.instance.shuffleSetting == TIME)
    {
        double timeVariance = SettingsStore.instance.timeShuffleVariance;
        double minRepeatsShuffle = SettingsStore.instance.minRepeatsShuffle;
        double maxRepeatsShuffle = SettingsStore.instance.maxRepeatsShuffle;
        double baseTime = SettingsStore.instance.timeShuffle;
        
        double loopDuration = audioPlayer.loopEnd - audioPlayer.loopStart;
        
        if (minRepeatsShuffle > 0)
        {
            double minTime = (audioPlayer.loopStart + loopDuration * minRepeatsShuffle) / 60.0;
            if (baseTime < minTime)
            {
                baseTime = minTime;
            }
        }
        
        if (maxRepeatsShuffle > 0)
        {
            double maxTime = (audioPlayer.loopStart + loopDuration * maxRepeatsShuffle) / 60.0;
            if (baseTime > maxTime)
            {
                baseTime = maxTime;
            }
        }
        
        double currentVariance = timeVariance - [self randomDouble:2 * timeVariance];
        
        double shuffleTimeMinutes = baseTime + currentVariance;
        currentShuffleTime = shuffleTimeMinutes * 60000000.0;
    }
    else if (SettingsStore.instance.shuffleSetting == REPEATS)
    {
        double repeatsVariance = SettingsStore.instance.repeatsShuffleVariance;
        double minTimeShuffle = SettingsStore.instance.minTimeShuffle * 60.0;
        double maxTimeShuffle = SettingsStore.instance.maxTimeShuffle * 60.0;
        double baseRepeats = SettingsStore.instance.repeatsShuffle;
        
        double loopDuration = audioPlayer.loopEnd - audioPlayer.loopStart;
        double repeatTime = audioPlayer.loopStart + baseRepeats * loopDuration;
        
        if (minTimeShuffle > 0 && repeatTime < minTimeShuffle)
        {
            baseRepeats = (minTimeShuffle - audioPlayer.loopStart) / loopDuration;
        }
        
        // No need to recalculate repeatTime since it is only changed if it is less than the min time,
        // meaning it is definitely not more than the max time.
        if (maxTimeShuffle > 0 && repeatTime > maxTimeShuffle)
        {
            baseRepeats = (maxTimeShuffle - audioPlayer.loopStart) / loopDuration;
        }
        
        double currentVariance = repeatsVariance - [self randomDouble:2 * repeatsVariance];
        
        currentShuffleRepeats = baseRepeats + currentVariance;
    }
}

/*!
 * Gets a random double value between 0 and a maximum.
 * @param max The maximum double value to get.
 * @return A random double value between 0 and max.
 */
- (double)randomDouble:(double)max
{
    unsigned int randMax = (unsigned)RAND_MAX;
    return (double) arc4random_uniform(randMax) / randMax * max;
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

- (void)closeDB
{
    sqlite3_close(trackData);
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

- (NSArray*)getMultiIntegerDB:(NSString *)query
{
    /// The statement to execute the query with.
    sqlite3_stmt *tempStatement;
    sqlite3_prepare_v2(trackData, [query UTF8String], -1, &tempStatement, NULL);
    /// Array of integers obtained from the query.
    NSMutableArray *returnValues = [[NSMutableArray alloc] init];
    while (sqlite3_step(tempStatement) == SQLITE_ROW)
    {
        [returnValues addObject:[NSNumber numberWithInteger:sqlite3_column_int(tempStatement, 0)]];
    }
    sqlite3_finalize(tempStatement);
    return [returnValues copy];
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

- (void)addSongToDB:(NSString *)name :(NSURL *)url
{
    [self prepareQuery:[NSString stringWithFormat:@"SELECT url FROM Tracks WHERE name=\"%@\"", name]];
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        [self updateDB:[NSString stringWithFormat:@"UPDATE Tracks SET url = \"%@\" WHERE name = \"%@\"", url.absoluteString, name]];
    }
    else
    {
        sqlite3_finalize(statement);
        [self prepareQuery:[NSString stringWithFormat:@"SELECT name FROM Tracks WHERE url=\"%@\"", url]];
        if (sqlite3_step(statement) != SQLITE_ROW)
        {
            [self updateDB:[NSString stringWithFormat:@"INSERT INTO Tracks (name, loopstart, loopend, volume, enabled, url) VALUES (\"%@\", 0, 0, 0.3, 1, \"%@\")", name, url.absoluteString]];
            [self incrementTotalSongs];
        }
    }
    sqlite3_finalize(statement);
}

- (void)wipeDB
{
    [self openUpdateDB:@"DELETE FROM Tracks"];
    [self openUpdateDB:@"DELETE FROM Playlists"];
    [self openUpdateDB:@"DELETE FROM PlaylistNames WHERE name != \"All tracks\""];
    
    // Reset fields
    musicNumber = -1;
    url = nil;
    songString = @"";
    idField = @"";
    nameField = @"";
    totalSongs = 0;
    totalPlaylistSongs = 0;
    playlistName.text = @"";
    SettingsStore.instance.playlistIndex = 0;
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
    if (!SettingsStore.instance.playlistIndex)
    {
        totalPlaylistSongs = totalSongs;
    }
}

- (void)decrementTotalSongs
{
    totalSongs--;
    if (!SettingsStore.instance.playlistIndex)
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
    if (SettingsStore.instance.playlistIndex)
    {
        [self openDB];
        /// The name of the current playlist.
        NSString * newName = [self getStringDB:[NSString stringWithFormat:@"SELECT name FROM PlaylistNames where id = %ld", (long)SettingsStore.instance.playlistIndex]];
        [self updatePlaylistName:newName];
        sqlite3_close(trackData);
        if ([newName isEqualToString:@""])
        {
            SettingsStore.instance.playlistIndex = 0;
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
    if (SettingsStore.instance.playlistIndex)
    {
        [self prepareQuery:[NSString stringWithFormat:@"SELECT track FROM Playlists WHERE id = %ld", (long)SettingsStore.instance.playlistIndex]];
    }
    else
    {
        [self prepareQuery:[NSString stringWithFormat:@"SELECT id FROM Tracks"]];
    }
    /// The IDs of all tracks read from the table so far
    NSMutableArray *songsSoFar = [[NSMutableArray alloc] init];
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        /// The database string containing the current track ID
        NSString *idString = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 0)];
        NSNumber *idVal = [NSNumber numberWithInteger:[idString integerValue]];
        [songsSoFar addObject:idVal];
    }
    splitSongs = [NSArray arrayWithArray:songsSoFar];
    sqlite3_finalize(statement);
    return splitSongs;
}

- (NSMutableArray*)getSongList
{
    if (!SettingsStore.instance.playlistIndex)
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

- (NSMutableArray*)getPlaylistNameList
{
    return [self getNameList:@"PlaylistNames"];
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

- (void)saveSettings
{
    [SettingsStore.instance saveSettings];
}

- (float)getVolumeSliderValue
{
    return volumeSlider.value;
}

- (void)didReceiveMemoryWarning
{
    NSLog(@"Low on memory!");
    [super didReceiveMemoryWarning];
}

@end
