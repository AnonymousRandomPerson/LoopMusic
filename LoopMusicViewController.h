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
#import <MediaPlayer/MediaPlayer.h>

extern double loopTime;
extern double loopEnd;
extern NSString *settingsSongString;
extern double timeShuffle;
extern NSInteger repeatsShuffle;
extern NSUInteger shuffleSetting;
extern double fadeSetting;

@interface LoopMusicViewController : UIViewController
{
    AVAudioPlayer *audioPlayer;
    AVAudioPlayer *audioPlayer2;
    AVAudioSession *audioSession;
    
    NSInteger musicNumber;
    NSURL *url;
    bool choose;
    NSString *songString;
    bool chooseSongString;
    bool playing;
    float delay;
    double fadeTime;
    double volumeDec;
    
    IBOutlet UIButton *randomSong;
    IBOutlet UIButton *playSong;
    IBOutlet UIButton *stopSong;
    IBOutlet UIButton *searchSong;
    IBOutlet UILabel *songName;
    IBOutlet UIButton *settings;
    IBOutlet UISwitch *dim;
    
    NSString *idField;
    NSString *nameField;
    float volumeSet;
    bool enabled;
    double loopField;
    bool valid;
    NSString *chooseSongText;
    NSInteger totalSongs;
    
    const char *dbPath;
    sqlite3 *trackData;
    sqlite3_stmt *statement;
    
    struct timeval t;
    long long time;
    NSUInteger repeats;
    bool buffer;
    bool occupied;
    
    AVAudioPlayer* audioPlayerFind;
    double duplicate;
    
    float initBright;
    
    NSTimer *timer;
}

@property(nonatomic, retain) UIButton *randomSong;
@property(nonatomic, retain) UIButton *playSong;
@property(nonatomic, retain) UIButton *stopSong;
@property(nonatomic, retain) UIButton *searchSong;
@property(nonatomic, retain) UILabel *songName;
@property(nonatomic, retain) UIButton *settings;
@property(nonatomic, retain) UISwitch *dim;

-(IBAction)randomSong:(id)sender;
-(IBAction)playSong:(id)sender;
-(IBAction)stopSong:(id)sender;
-(IBAction)searchSong:(id)sender;
-(IBAction)settings:(id)sender;
-(IBAction)close:(id)sender;
-(IBAction)dim:(id)sender;

-(IBAction)changeScreen:(NSString*)screen;
-(IBAction)back:(id)sender;

-(void)openDB;
-(void)prepareQuery:(NSString*)query;
-(void)updateDB:(NSString*)query;
-(void)openUpdateDB:(NSString*)query;
-(NSInteger)updateDBResult:(NSString*)query;

-(NSInteger)initializeTotalSongs;
-(void)incrementTotalSongs;
-(void)decrementTotalSongs;
-(NSMutableArray*)getSongList;
-(bool)isSongListEmpty;

-(void)playMusic;
-(void)setAudioPlayer:(NSURL*)newURL;
-(void)updateVolumeDec;
-(void)chooseSong:(NSString*)newSong;
-(void)setDelay:(float)newDelay;
-(void)setOccupied:(bool)newOccupied;
-(NSString*)getSongName;
-(void)setNewSongName:(NSString*)newName;
-(double)getAudioDuration;
-(void)testTime;
-(float)getVolume;
-(void)setVolume:(double)newVolume;
-(float)findTime;
-(NSInteger)setLoopTime:(double)newLoopTime;
-(void)setCurrentTime:(double)newCurrentTime;
-(double)getDelay;
-(bool)getEnabled;
-(void)setInitBright:(float)newBright;
-(float)getInitBright;
-(double)timeVariance;

-(void)showErrorMessage:(NSString*)message;
-(void)showNoSongMessage;

@end