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
/*NSInteger onState = 3;
float delay2 = 0;
bool stateChange=false;*/


@interface LoopMusicViewController ()

@end

@implementation LoopMusicViewController

@synthesize searchSong, playSong, randomSong, stopSong, songName, settings, dim;

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [self resignFirstResponder];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    stringTemp = [[NSBundle mainBundle] pathForResource:@"Tracks" ofType:@"db"];
    dbPath = [stringTemp UTF8String];
    // Get the documents directory
    database = nil;
    dirPaths = NSSearchPathForDirectoriesInDomains
    (NSDocumentDirectory, NSUserDomainMask, YES);
    docsDir = dirPaths[0];
    // Build the path to the database file
    databasePath = [[NSString alloc] initWithString:[docsDir stringByAppendingPathComponent: @"Tracks.db"]];
    NSFileManager *filemgr = [NSFileManager defaultManager];
    dbPath2 = [databasePath UTF8String];
    sqlite3_open(dbPath2, &trackData);
    // Create database if not existant
    if ([filemgr fileExistsAtPath: databasePath ] == NO)
    {
        if (sqlite3_open(dbPath2, &database) == SQLITE_OK)
        {
            char *errMsg;
            const char *sql_stmt = "create table if not exists Tracks (id integer primary key, name text, loopstart numeric, loopend numeric)";
            if (sqlite3_exec(database, sql_stmt, NULL, NULL, &errMsg) != SQLITE_OK)
            {
                NSLog(@"Failed to create table");
            }
            NSString *querySQL = [NSString stringWithFormat:@"ATTACH '%s' AS Tracks", dbPath];
            sql_stmt = [querySQL UTF8String];
            sqlite3_exec(database, sql_stmt, NULL, NULL, &errMsg);
            querySQL = [NSString stringWithFormat:@"INSERT INTO Tracks SELECT * FROM Tracks.Tracks"];
            sql_stmt = [querySQL UTF8String];
            sqlite3_exec(database, sql_stmt, NULL, NULL, &errMsg);
            sqlite3_close(database);
        }
        else
        {
            NSLog(@"Failed to open/create database");
        }
    }
    // Initialize # of songs
    NSString *querySQL = [NSString stringWithFormat:@"SELECT max(id) FROM Tracks"];
    const char *query_stmt = [querySQL UTF8String];
    sqlite3_prepare_v2(trackData, query_stmt, -1, &statement, NULL);
    sqlite3_step(statement);
    totalSongs = [[[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 0)] integerValue];
    NSLog(@"%li", (long)totalSongs);
    sqlite3_finalize(statement);
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
    /*queue = [NSOperationQueue new];
    [queue setMaxConcurrentOperationCount:2];
    player = [[NSInvocationOperation alloc] initWithTarget:self
                                                  selector:@selector(playMusic)
                                                    object:nil];*/
    /*looper = [[NSInvocationOperation alloc] initWithTarget:self
                                                  selector:@selector(loop)
                                                    object:nil];*/
    //[queue addOperation:player];
    //[queue addOperation:looper];
    delay = 0;
    timer = [NSTimer scheduledTimerWithTimeInterval:.0001
                                             target:self
                                           selector:@selector(timeDec:)
                                           userInfo:nil
                                            repeats:YES];
    time = [self getTime];
    repeats = 0;
    [self playMusic];
    
    NSString *filePath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"Settings.txt"];
    if (filePath)
    {
        NSString *contentOfFile = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
        NSArray *splitSettings = [contentOfFile componentsSeparatedByString:@","];
        shuffleSetting = [splitSettings[0] integerValue];
        timeShuffle = [splitSettings[1] doubleValue];
        timeShuffle2 = [self timeVariance];
        repeatsShuffle = [splitSettings[2] integerValue];
    }
    initBright = [UIScreen mainScreen].brightness;
    dim.on = false;
    //duplicate = -160.0;
    /*CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), //center
                                    NULL, // observer
                                    hasBlankedScreen, // callback
                                    CFSTR("com.apple.springboard.hasBlankedScreen"), // event name
                                    NULL, // object
                                    CFNotificationSuspensionBehaviorDeliverImmediately);
    enabled=true;*/
}

- (void)timeDec:(NSTimer*)timer
{
    if (playing)
    {
        if (audioPlayer.currentTime>=loopEnd-delay) {
            [audioPlayer2 play];
            [audioPlayer stop];
            [audioPlayer prepareToPlay];
            audioPlayer.currentTime=loopTime-delay;
            repeats++;
        }
        if (audioPlayer2.currentTime>=loopEnd-delay) {
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
                buffer = false;
                time = [self getTime];
                repeats = 0;
                choose = false;
                [self playMusic];
                return;
            }
        }
        if (!audioPlayer2.playing && !audioPlayer.playing && time > 10000)
        {
            if (audioPlayer.currentTime == 0)
            {
                //audioPlayer2.currentTime = loopTime-delay;
                [audioPlayer2 play];
                audioPlayer.currentTime = loopTime-delay;
                [audioPlayer prepareToPlay];
            }
            else
            {
                //audioPlayer.currentTime = loopTime-delay;
                [audioPlayer play];
                audioPlayer2.currentTime = loopTime-delay;
                [audioPlayer2 prepareToPlay];
            }
            repeats++;
        }
    }
}

/*static void hasBlankedScreen(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
    NSString* notifyName = (__bridge NSString*)name;
    // this check should really only be necessary if you reuse this one callback method
    //  for multiple Darwin notification events
    if ([notifyName isEqualToString:@"com.apple.springboard.hasBlankedScreen"]) {
        //NSLog(@"screen has either gone dark, or been turned back on!");
        if (onState==3)
        {
            onState=1;
            delay2=0.0;
            stateChange=true;
        }
        else
        {
            onState++;
            if (onState == 2)
            {
                stateChange=true;
            }
        }
    }
    NSLog(@"%li", (long)onState);
}*/

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)data successfully:(BOOL)flag
{
    NSLog(@"!");
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
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    playing=false;
    valid=false;
    dbPath2 = [databasePath UTF8String];
    sqlite3_open(dbPath2, &trackData);
    NSError *error;
    if (chooseSongString)
    {
        chooseSongString = false;
        musicNumber = -1;
        NSString *querySQL = [NSString stringWithFormat:@"SELECT id, name, loopstart, loopend, extension, volume, enabled FROM Tracks WHERE name=\"%@\"", chooseSongText];
        const char *query_stmt = [querySQL UTF8String];
        sqlite3_prepare_v2(trackData, query_stmt, -1, &statement, NULL);
        if (sqlite3_step(statement) == SQLITE_ROW)
        {
            idField = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 0)];
            nameField = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 1)];
            if (sqlite3_column_text(statement, 2) == nil || [[[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 2)] isEqualToString:(@"")])
            {
                loopTime = 0;
                loopEnd = 0;
                extension = @".m4a";
                volumeSet = 0.3;
                enabled = 1;
                NSString *querySQL;
                if (sqlite3_column_text(statement, 4) == nil || [[[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 4)] isEqualToString:(@"")])
                {
                    querySQL = [NSString stringWithFormat:@"UPDATE Tracks SET extension = \".m4a\" WHERE name = \"%@\"", nameField];
                    NSLog(@"%@", querySQL);
                    const char *query_stmt = [querySQL UTF8String];
                    sqlite3_prepare_v2(trackData, query_stmt, -1, &statement2, NULL);
                    sqlite3_step(statement2);
                    sqlite3_finalize(statement2);
                } else {
                    extension = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 4)];
                }
                querySQL = [NSString stringWithFormat:@"UPDATE Tracks SET loopstart = %f WHERE name = \"%@\"", loopTime, nameField];
                NSLog(@"%@", querySQL);
                const char *query_stmt2 = [querySQL UTF8String];
                sqlite3_prepare_v2(trackData, query_stmt2, -1, &statement2, NULL);
                sqlite3_step(statement2);
                sqlite3_finalize(statement2);
                querySQL = [NSString stringWithFormat:@"UPDATE Tracks SET loopend = 0 WHERE name = \"%@\"", nameField];
                NSLog(@"%@", querySQL);
                const char *query_stmt3 = [querySQL UTF8String];
                sqlite3_prepare_v2(trackData, query_stmt3, -1, &statement2, NULL);
                sqlite3_step(statement2);
                sqlite3_finalize(statement2);
                querySQL = [NSString stringWithFormat:@"UPDATE Tracks SET volume = 0.3 WHERE name = \"%@\"", nameField];
                NSLog(@"%@", querySQL);
                const char *query_stmt4 = [querySQL UTF8String];
                sqlite3_prepare_v2(trackData, query_stmt4, -1, &statement2, NULL);
                sqlite3_step(statement2);
                sqlite3_finalize(statement2);
                querySQL = [NSString stringWithFormat:@"UPDATE Tracks SET enabled = 1 WHERE name = \"%@\"", nameField];
                NSLog(@"%@", querySQL);
                const char *query_stmt5 = [querySQL UTF8String];
                sqlite3_prepare_v2(trackData, query_stmt5, -1, &statement2, NULL);
                sqlite3_step(statement2);
                sqlite3_finalize(statement2);
            }
            else
            {
            loopTime = [[[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 2)] doubleValue];
            loopEnd = [[[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 3)] doubleValue];
            extension = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 4)];
            volumeSet = [[[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 5)] doubleValue];
            enabled = [[[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 6)] intValue];
            }
            valid = true;
        }
        sqlite3_finalize(statement);
        nameField = [nameField stringByAppendingString:extension];
        nameField = [@"%@/" stringByAppendingString:nameField];
        if (valid)
        {
            url = [NSURL fileURLWithPath:[NSString stringWithFormat:nameField, [[NSBundle mainBundle] resourcePath]]];
            sqlite3_close(trackData);
        }
        else
        {
            sqlite3_close(trackData);
            return;
        }
        musicNumber = [idField intValue];
    }
    //If chosen song text is a number
    else
    {
        do {
            NSInteger random = -1;
            do {
                random = arc4random() % totalSongs + 1;
            } while (musicNumber == random);
            timeShuffle2 = [self timeVariance];
            musicNumber = random;
            NSString *querySQL = [NSString stringWithFormat:@"SELECT id, name, loopstart, loopend, extension, volume, enabled FROM Tracks WHERE id=\"%li\"", (long)musicNumber];
            const char *query_stmt = [querySQL UTF8String];
            sqlite3_prepare_v2(trackData, query_stmt, -1, &statement, NULL);
            if (sqlite3_step(statement) == SQLITE_ROW)
            {
                idField = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 0)];
                nameField = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 1)];
                loopTime = [[[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 2)] doubleValue];
                loopEnd = [[[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 3)] doubleValue];
                extension = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 4)];
                volumeSet = [[[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 5)] doubleValue];
                enabled = [[[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 6)] intValue];
            }
            else
            {
                sqlite3_close(trackData);
                return;
            }
            sqlite3_finalize(statement);
        } while (!enabled);
        nameField = [nameField stringByAppendingString:extension];
        nameField = [@"%@/" stringByAppendingString:nameField];
        url = [NSURL fileURLWithPath:[NSString stringWithFormat:nameField, [[NSBundle mainBundle] resourcePath]]];
    }
    sqlite3_close(trackData);
    NSLog(@"%@", idField);
    // Change audio player settings
    //songName.text = [[[url path] lastPathComponent] stringByDeletingPathExtension];
    [self.songName performSelectorOnMainThread : @ selector(setText : ) withObject:[[[url path] lastPathComponent] stringByDeletingPathExtension] waitUntilDone:YES];
    NSLog(@"%@", songName.text);
	audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url
                                                         error:&error];
	audioPlayer.numberOfLoops = 0;
    audioPlayer2 = [[AVAudioPlayer alloc] initWithContentsOfURL:url
                                                          error:&error];
	audioPlayer2.numberOfLoops = 0;
    [audioPlayer stop];
    [audioPlayer2 stop];
    audioPlayer.currentTime=0;
    audioPlayer2.currentTime=loopTime-delay;
    audioPlayer.volume = volumeSet;
    audioPlayer2.volume = volumeSet;
    if (!timer) {
        timer = [NSTimer scheduledTimerWithTimeInterval:.0001
                                                 target:self
                                               selector:@selector(timeDec:)
                                               userInfo:nil
                                                repeats:YES];
         }
	if (audioPlayer == nil)
		NSLog(@"%@", [error description]);
    playing=true;
    [audioPlayer play];
    [audioPlayer2 prepareToPlay];
    /*looper = [[NSInvocationOperation alloc] initWithTarget:self
                                                  selector:@selector(loop)
                                                    object:nil];*/
    repeats = 0;
    time = [self getTime];
    //[queue addOperation:looper];
    if (loopEnd == 0.0)
    {
        loopEnd = audioPlayer.duration;
        sqlite3_open(dbPath2, &trackData);
        NSString *querySQL = [NSString stringWithFormat:@"UPDATE Tracks SET loopend = %f WHERE id=\"%li\"", loopEnd, (long)musicNumber];
        NSLog(@"%@", querySQL);
        const char *query_stmt = [querySQL UTF8String];
        sqlite3_prepare_v2(trackData, query_stmt, -1, &statement, NULL);
        sqlite3_step(statement);
        sqlite3_finalize(statement);
        sqlite3_close(trackData);
        NSLog(@"%f", loopEnd);
    }
}

// Loops music
/*-(void)loop
{
    repeats = 0;
    time = 0;
    playing=true;
    while (playing)
    {
        if (audioPlayer.currentTime>=audioPlayer.duration-.2) {
            [audioPlayer2 play];
            [audioPlayer stop];
            audioPlayer.currentTime=loopTime-.2;
            [audioPlayer prepareToPlay];
            repeats++;
        }
        if (audioPlayer2.currentTime>=audioPlayer2.duration-.2) {
            [audioPlayer play];
            [audioPlayer2 stop];
            audioPlayer2.currentTime=loopTime-.2;
            [audioPlayer2 prepareToPlay];
            repeats++;
        }
        if (repeatsShuffle > 0 && shuffleSetting == 2)
        {
            if (repeats >= repeatsShuffle)
            {
                buffer=true;
            }
        }
        if (timeShuffle > 0)
        {
            if (time / 60000 >= timeShuffle && shuffleSetting == 1)
            {
                buffer=true;
            }
        }
        if (buffer)
        {
            buffer=false;
            time = 0;
            repeats = 0;
            choose=false;
            [self playMusic];
            return;
        }
        if (!audioPlayer2.playing && !audioPlayer.playing)
        {
            audioPlayer.currentTime = loopTime-.2;
            [audioPlayer play];
            audioPlayer2.currentTime=loopTime-.2;
            [audioPlayer2 prepareToPlay];
        }
    }
}*/

-(IBAction)randomSong:(id)sender
{
    time = [self getTime];
    repeats = 0;
    choose = false;
    playing=false;
    audioPlayer.currentTime=0;
    audioPlayer2.currentTime=0;
    if (audioPlayer.playing)
        [audioPlayer stop];
    if (audioPlayer2.playing)
        [audioPlayer2 stop];
    [self playMusic];
}

-(IBAction)playSong:(id)sender
{
    if (!audioPlayer.playing && !audioPlayer2.playing)
    {
        time = [self getTime];
        repeats = 0;
        audioPlayer.currentTime=0;
        audioPlayer2.currentTime=loopTime-delay;
        [audioPlayer play];
        [audioPlayer2 prepareToPlay];
        playing=true;
        if (!timer) {
            timer = [NSTimer scheduledTimerWithTimeInterval:.0001
                                                     target:self
                                                   selector:@selector(timeDec:)
                                                   userInfo:nil
                                                    repeats:YES];
        }
        /*looper = [[NSInvocationOperation alloc] initWithTarget:self
                                                      selector:@selector(loop)
                                                        object:nil];
        [queue addOperation:looper];*/
    }
}

-(IBAction)stopSong:(id)sender
{
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    playing=false;
    if (audioPlayer.playing)
        [audioPlayer stop];
    if (audioPlayer2.playing)
        [audioPlayer2 stop];
    if (timer) {
        [timer invalidate];
        timer = nil;
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

/*-(IBAction)chooseSong:(id)sender
{
    playing=false;
    musicNumber = [chooseSong.text intValue];
    choose = true;
    if (chooseSong.text != 0 && musicNumber == 0)
    {
        chooseSongString = true;
    }
    [self playMusic];
    [sender resignFirstResponder];
}*/

-(IBAction)searchSong:(id)sender
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main"
                                                         bundle:nil];
    UIViewController *searchVC = [storyboard instantiateViewControllerWithIdentifier:@"search"];
    [self presentViewController:searchVC
                       animated:true
                     completion:nil];
}

-(IBAction)settings:(id)sender
{
    settingsSongString = songName.text;
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main"
                                                         bundle:nil];
    UIViewController *settingsVC = [storyboard instantiateViewControllerWithIdentifier:@"settings"];
    [self presentViewController:settingsVC
                       animated:true
                     completion:nil];
}

-(int)setLoopTime:(double)newLoopTime
{
    dbPath2 = [databasePath UTF8String];
    loopTime = newLoopTime;
    sqlite3_open(dbPath2, &trackData);
    NSString *querySQL = [NSString stringWithFormat:@"UPDATE Tracks SET loopstart = %f WHERE name = \"%@\"", newLoopTime, songName.text];
    const char *query_stmt = [querySQL UTF8String];
    sqlite3_prepare_v2(trackData, query_stmt, -1, &statement, NULL);
    int result = sqlite3_step(statement);
    NSLog(@"%@, (%i)", querySQL, result);
    sqlite3_finalize(statement);
    sqlite3_close(trackData);
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
    //[chooseSong resignFirstResponder];
}

-(void)setOccupied:(bool)newOccupied
{
    occupied = newOccupied;
}

-(NSString*)getSongName
{
    return songName.text;
}

-(double)getAudioDuration
{
    return audioPlayer.duration;
}

-(void)testTime
{
    double test = loopEnd-delay-5;
    if (test < 0) {
        test = 0;
    }
    [self setCurrentTime:test];
    /*[self playSong:self];
    if (audioPlayer.playing)
    {
        [audioPlayer stop];
        audioPlayer.currentTime=test;
        [audioPlayer play];
    }
    else if (audioPlayer2.playing)
    {
        [audioPlayer2 stop];
        audioPlayer2.currentTime=test;
        [audioPlayer2 play];
    }*/
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
    return audioPlayer.volume;
}

-(void)setVolume:(double)newVolume
{
    if (newVolume < 0 || newVolume > 1)
    {
        return;
    }
    audioPlayer.volume=newVolume;
    audioPlayer2.volume=newVolume;
    dbPath2 = [databasePath UTF8String];
    sqlite3_open(dbPath2, &trackData);
    NSString *querySQL = [NSString stringWithFormat:@"UPDATE Tracks SET volume = %f WHERE name = \"%@\"", newVolume, songName.text];
    const char *query_stmt = [querySQL UTF8String];
    sqlite3_prepare_v2(trackData, query_stmt, -1, &statement, NULL);
    int result = sqlite3_step(statement);
    sqlite3_finalize(statement);
    sqlite3_close(trackData);
    NSLog(@"%@, (%i)", querySQL, result);
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
    /*
    [self stopSong:self];
    double newLoopTime = 1.0;
    double newLoopEnd = 2.0;
    double loopStartArray[] = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0};
    audioPlayerFind = [[AVAudioPlayer alloc] initWithContentsOfURL:url
                                                                 error:nil];
    audioPlayerFind.numberOfLoops = 0;
    audioPlayerFind.volume = 0;
    audioPlayerFind.meteringEnabled = true;
    
    bool possible = true;
    double getAmplitudeJ = 0.0;
    double getAmplitudeK = 0.0;
    NSMutableArray *amplitudes;
    for (double i = 0; i<audioPlayerFind.duration; i+=.05)
    {
        NSLog(@"D");
        [amplitudes addObject:@([self getAmplitude:i])];
    }*/
    /*for (newLoopTime = 1.0; newLoopTime < audioPlayerFind.duration; newLoopTime+=1)
    {
        for (int i = 0; i<10; i++)
        {
            loopStartArray[i] = [self getAmplitude:(newLoopTime+(double)i)];
        }
        //[self nullifyDuplicate];
        for (double j = 1.0; j<audioPlayerFind.duration-.5; j+=.05)
        {
            getAmplitudeJ = [self getAmplitude:(newLoopTime+j)];
            if ([self lenienceRange:getAmplitudeJ other:(loopStartArray[0]-.3)])
            {
                possible = true;
                for (int k = 0; k<10; k++)
                {
                    getAmplitudeK = [self getAmplitude:(newLoopTime+j+k)];
                    if (![self lenienceRange:getAmplitudeK other:loopStartArray[k]])
                    {
                        possible=false;
                        break;
                    }
                }
                if (possible)
                {
                    NSLog(@"%f", newLoopTime);
                    NSLog(@"%f", j);
                    break;
                }
            }
        }
        if (possible)
        {
            break;
        }
    }*/
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

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)event {
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

/*-(double)getAmplitude:(double)newTime
{
    double amplitude = -160.0;
    long long amplitudeDelay = [self getTime];
    if (newTime < 0 || newTime >= audioPlayerFind.duration)
    {
        return -160;
    }
    if (duplicate == -160)
        duplicate = -159;
    audioPlayerFind.currentTime = newTime;
    [audioPlayerFind play];
    while (amplitude <= -100 &&
           amplitude != duplicate &&
           [self getTime] - amplitudeDelay <= 50000)
    {
        [audioPlayerFind updateMeters];
        amplitude = [audioPlayerFind peakPowerForChannel:0];
    }
    [audioPlayerFind stop];
    NSLog(@"%f %f", newTime, amplitude);
    duplicate = amplitude;
    return amplitude;
}

-(bool)lenienceRange:(double)compare1 other:(double)compare2
{
    if (compare1 >= compare2 - .3 && compare1 <= compare2 + .3)
    {
        return true;
    }
    else
    {
        return false;
    }
}

-(void)nullifyDuplicate
{
    duplicate = -160.0;
}*/

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
