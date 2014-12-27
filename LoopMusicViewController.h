//
//  LoopMusicViewController.h
//  LoopMusic
//
//  Created by Cheng Hann Gan on 12/24/13.
//  Copyright (c) 2013 Cheng Hann Gan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <sqlite3.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <sys/time.h>
//#import <MediaPlayer/MediaPlayer.h>
//#import <CoreFoundation/CoreFoundation.h>

extern double loopTime;
extern double loopEnd;
extern NSString *settingsSongString;
extern double timeShuffle;
extern NSInteger repeatsShuffle;
extern NSUInteger shuffleSetting;
/*extern NSInteger onState;
extern float delay2;
extern bool stateChange;*/

@interface LoopMusicViewController : UIViewController {
    AVAudioPlayer *audioPlayer;
    AVAudioPlayer *audioPlayer2;
    AVAudioSession *audioSession;
    //MPNowPlayingInfoCenter *nowPlayingInfo;
    
    NSInteger musicNumber;
    NSURL *url;
    bool choose;
    NSString *songString;
    bool chooseSongString;
    bool playing;
    float delay;
    
    /*NSOperationQueue *queue;
    NSInvocationOperation *player;
    NSInvocationOperation *looper;*/
    
    IBOutlet UIButton *randomSong;
    IBOutlet UIButton *playSong;
    IBOutlet UIButton *stopSong;
    //IBOutlet UITextField *chooseSong;
    IBOutlet UIButton *searchSong;
    IBOutlet UILabel *songName;
    IBOutlet UIButton *settings;
    IBOutlet UISwitch *dim;
    
    NSString *idField;
    NSString *nameField;
    NSString *extension;
    float volumeSet;
    bool enabled;
    double loopField;
    NSInteger totalSongs;
    bool valid;
    NSString *chooseSongText;
    
    NSString *stringTemp;
    sqlite3 *trackData;
    NSString *databasePath;
    const char *dbPath;
    const char *dbPath2;
    sqlite3_stmt *statement;
    sqlite3_stmt *statement2;
    sqlite3 *database;
    NSString *docsDir;
    NSArray *dirPaths;
    
    struct timeval t;
    long long time;
    NSUInteger repeats;
    bool buffer;
    bool occupied;
    
    AVAudioPlayer* audioPlayerFind;
    double duplicate;
    
    float initBright;
}

@property(nonatomic, retain) UIButton *randomSong;
@property(nonatomic, retain) UIButton *playSong;
@property(nonatomic, retain) UIButton *stopSong;
//@property(nonatomic, retain) UITextField *chooseSong;
@property(nonatomic, retain) UIButton *searchSong;
@property(nonatomic, retain) UILabel *songName;
@property(nonatomic, retain) UIButton *settings;
@property(nonatomic, retain) UISwitch *dim;

-(IBAction)randomSong:(id)sender;
-(IBAction)playSong:(id)sender;
-(IBAction)stopSong:(id)sender;
//-(IBAction)chooseSong:(id)sender;
-(IBAction)searchSong:(id)sender;
-(IBAction)settings:(id)sender;
-(IBAction)close:(id)sender;
-(IBAction)dim:(id)sender;


//-(void)loop;
-(void)chooseSong:(NSString*)newSong;
-(void)setDelay:(float)newDelay;
-(void)setOccupied:(bool)newOccupied;
-(NSString*)getSongName;
-(double)getAudioDuration;
-(void)testTime;
-(float)getVolume;
-(void)setVolume:(double)newVolume;
-(float)findTime;
-(int)setLoopTime:(double)newLoopTime;
-(void)setCurrentTime:(double)newCurrentTime;
-(double)getDelay;
-(bool)getEnabled;
-(void)setInitBright:(float)newBright;
-(float)getInitBright;
-(double)timeVariance;

@end