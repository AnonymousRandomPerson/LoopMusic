//
//  LoopMusicViewController.h
//  LoopMusic
//
//  Created by Cheng Hann Gan on 12/24/13.
//  Copyright (c) 2013 Cheng Hann Gan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <sqlite3.h>
#import <sys/time.h>
#import <MediaPlayer/MediaPlayer.h>
#import "AudioPlayer.h"

/// The name of the current track.
extern NSString *settingsSongString;
/// The base amount of time to play a track before shuffling.
extern double timeShuffle;
/// The number of times to repeat a track before shuffling.
extern NSInteger repeatsShuffle;
/// The setting for how to shuffle tracks.
extern NSUInteger shuffleSetting;
/// The amount of time to fade out a track before shuffling.
extern double fadeSetting;
/// The index of the currently selected playlist.
extern NSInteger playlistIndex;

@interface LoopMusicViewController : UIViewController
{
    /// The audio player that plays tracks.
    AudioPlayer *audioPlayer;
    
    /// The database index of the current track.
    NSInteger musicNumber;
    /// The index of the current track within the current playlist
    NSInteger musicIndex;
    /// The resource URL of the current track.
    NSURL *url;
    /// Whether a track is being manually chosen by the user.
    bool choose;
    /// The name of the current track.
    NSString *songString;
    /// Whether a track is being chosen by its name.
    bool chooseSongString;
    /// The amount of milliseconds that the current track has been fading out for.
    double fadeTime;
    /// The amount to decrement volume per tick when fading out.
    double volumeDec;
    
    /// Button to randomize the current track.
    IBOutlet UIButton *randomSong;
    /// Button to play the current track.
    IBOutlet UIButton *playSong;
    /// Button to stop playback of the current track.
    IBOutlet UIButton *stopSong;
    /// Button to search for a track to play.
    IBOutlet UIButton *searchSong;
    /// Label for the name of the current track.
    IBOutlet UILabel *songName;
    /// Button to go to playback settings.
    IBOutlet UIButton *settings;
    /// Label for the name of the current playlist.
    IBOutlet UILabel *playlistName;
    /// Symbol for whether the player is playing.
    IBOutlet UILabel *playSymbol;
    /// Slider for adjusting the global volume of the app.
    IBOutlet UISlider *volumeSlider;
    
    /// The database ID for the loading track.
    NSString *idField;
    /// The name of the loading track.
    NSString *nameField;
    /// The relative volume of the loading track.
    float volumeSet;
    /// Whether the loading track is enabled in shuffle.
    bool enabled;
    /// Whether the loading track is valid.
    bool valid;
    /// The name of the track being chosen.
    NSString *chooseSongText;
    /// The total number of tracks in the app.
    NSInteger totalSongs;
    /// The total number of tracks in the current playlist.
    NSInteger totalPlaylistSongs;
    
    /// The path of the track database.
    const char *dbPath;
    /// The connection to the track database.
    sqlite3 *trackData;
    /// The currently active statement to the track database.
    sqlite3_stmt *statement;
    
    /// The time that the current track started playing at.
    long long time;
    /// The number of times the current track has repeated.
    NSUInteger repeats;
    /// Whether a screen other than the main screen is showing.
    bool occupied;
    
    /// Timer used to loop tracks.
    NSTimer *shuffleTimer;
    /// Timer used to fade out tracks.
    NSTimer *fadeTimer;
}

/// Button to randomize the current track.
@property(nonatomic, retain) UIButton *randomSong;
/// Button to play the current track.
@property(nonatomic, retain) UIButton *playSong;
/// Button to stop playback of the current track.
@property(nonatomic, retain) UIButton *stopSong;
/// Button to search for a track to play.
@property(nonatomic, retain) UIButton *searchSong;
/// Label for the name of the current track.
@property(nonatomic, retain) UILabel *songName;
/// Button to go to playback settings.
@property(nonatomic, retain) UIButton *settings;

/*!
 * Chooses a random track to be played.
 * @param sender The object that called this function.
 * @return
 */
- (IBAction)randomSong:(id)sender;
/*!
 * Plays the current track.
 * @param sender The object that called this function.
 * @return
 */
- (IBAction)playSong:(id)sender;
/*!
 * Stops playback of the current track.
 * @param sender The object that called this function.
 * @return
 */
- (IBAction)stopSong:(id)sender;
/*!
 * Navigates to the search screen.
 * @param sender The object that called this function.
 * @return
 */
- (IBAction)searchSong:(id)sender;
/*!
 * Navigates to the settings screen.
 * @param sender The object that called this function.
 * @return
 */
- (IBAction)settings:(id)sender;
/*!
 * Navigates to the loop finder screen.
 * @param sender The object that called this function.
 * @return
 */
- (IBAction)loopFinder:(id)sender;
/*!
 * Navigates to a certain screen.
 * @param sender The name of the screen to navigate to.
 * @return
 */
- (IBAction)changeScreen:(NSString *)screen;
/*!
 * Navigates to the previous screen.
 * @param sender The object that called this function.
 * @return
 */
- (IBAction)back:(id)sender;
/*!
 * Sets the global volume of the app.
 * @param sender The object that called this function.
 * @return
 */
- (IBAction)setGlobalVolume:(id)sender;
/*!
 * Saves the global volume of the app to the settings file.
 * @param sender The object that called this function.
 * @return
 */
- (IBAction)saveGlobalVolume:(id)sender;

/*!
 * Opens the track database.
 * @return
 */
- (void)openDB;
/*!
 * Prepares a database query.
 * @param query The query to prepare.
 * @return
 */
- (void)prepareQuery:(NSString *)query;
/*!
 * Executes a query to update the database.
 * @param query The query to update the database with.
 * @return
 */
- (void)updateDB:(NSString *)query;
/*!
 * Gets an integer from a database query.
 * @param query The database query to get an integer with.
 * @return The integer obtained from the database query.
 */
- (NSInteger)getIntegerDB:(NSString *)query;
/*!
 * Opens the database and updates it.
 * @param query The query to update the database with.
 * @return
 */
- (void)openUpdateDB:(NSString *)query;
/*!
 * Executes a query to update the database.
 * @param query The query to update the database with.
 * @return The result code of the query.
 */
- (NSInteger)updateDBResult:(NSString *)query;
/*!
 * Executes queries to add a song to the database.
 * @param name The song name.
 * @param url The song URL.
 * @return
 */
- (void)addSongToDB:(NSString *)name :(NSURL *)url;
/*!
 * Wipes the database clean.
 * @return
 */
- (void)wipeDB;

/*!
 * Loads the total number of tracks in the app.
 * @return The total number of tracks in the app.
 */
- (NSInteger)initializeTotalSongs;
/*!
 * Increments the total number of tracks in the app.
 * @return
 */
- (void)incrementTotalSongs;
/*!
 * Decrements the total number of tracks in the app.
 * @return
 */
- (void)decrementTotalSongs;
/*!
 * Increments the total number of tracks in the current playlist.
 * @return
 */
- (void)incrementPlaylistSongs;
/*!
 * Decrements the total number of tracks in the current playlist.
 * @return
 */
- (void)decrementPlaylistSongs;
/*!
 * Updates the database with changes to the current playlist.
 * @return
 */
- (void)updatePlaylistSongs;
/*!
 * Gets the IDs of all tracks in the current playlist.
 * @return An array containing the IDs of all tracks in the current playlist.
 */
- (NSArray*)getSongIndices;
/*!
 * Gets the names of all tracks in the current playlist.
 * @return An array containing the names of all tracks in the current playlist.
 */
- (NSMutableArray*)getSongList;
/*!
 * Gets the names of all tracks in the app.
 * @return An array containing the names of all tracks in the app.
 */
- (NSMutableArray*)getTotalSongList;
/*!
 * Checks if there are no tracks in the current playlist.
 * @return Whether there are no tracks in the current playlist.
 */
- (bool)isSongListEmpty;
/*!
 * Gets the names of all playlists.
 * @return An array containing the names of all playlists.
 */
- (NSMutableArray*)getPlaylistList;
/*!
 * Gets the name of the current playlist.
 * @return The name of the current playlist.
 */
- (NSString *)getPlaylistName;
/*!
 * Updates the name of the current playlist according to the playlist index.
 * @return
 */
- (void)updatePlaylistName;
/*!
 * Updates the name of the current playlist.
 * @param name The new name of the current playlist.
 * @return
 */
- (void)updatePlaylistName:(NSString *)name;

/*!
 * Plays a track.
 * @return
 */
- (void)playMusic;
/*!
 * Sets audio players to the URL of the current track.
 * @param newURL The URL of the current track.
 * @return
 */
- (void)setAudioPlayer:(NSURL*)newURL;
/*!
 * Updates the fade-out volume decrement according to the fade-out setting and the current track.
 * @return
 */
- (void)updateVolumeDec;
/*!
 * Plays a specific track.
 * @param newSong The name of the track to play.
 * @return
 */
- (void)chooseSong:(NSString *)newSong;
/*!
 * Sets whether a screen other than the main screen is showing.
 * @param newOccupied Whether a screen other than the main screen is showing.
 * @return
 */
- (void)setOccupied:(bool)newOccupied;
/*!
 * Gets the name of the current track.
 * @return The name of the current track.
 */
- (NSString *)getSongName;
/*!
 * Sets the name of the current track.
 * @param The name to set the current track to.
 * @return
 */
- (void)setNewSongName:(NSString *)newName;
/*!
 * Gets the duration of the current track.
 * @return The duration of the current track.
 */
- (double)getAudioDuration;
/*!
 * Sets the playback time to five seconds before the loop time.
 * @return
 */
- (void)testTime;
/*!
 * Gets the relative volume of the current track.
 * @return The relative volume of the current track.
 */
- (float)getVolume;
/*!
 * Sets the relative volume of the current track.
 * @param newVolume The volume to set the relative volume to.
 * @return
 */
- (void)setVolume:(double)newVolume;
/*!
 * Gets the playback time of the current track.
 * @return The playback time of the current track.
 */
- (float)findTime;
/*!
 * Sets the loop time of the current track.
 * @param newLoopTime The time to set the loop time to.
 * @return The result code of the database update query for setting the loop time.
 */
- (NSInteger)setLoopTime:(double)newLoopTime;
/*!
 * Sets the playback time of the current track.
 * @param newCurrentTime The time to set the playback time to.
 * @return
 */
- (void)setCurrentTime:(double)newCurrentTime;
/*!
 * Varies the amount of time to play the current track before shuffling.
 * @return A randomly varied amount of time to play the current track before shuffling.
 */
- (double)timeVariance;

/*!
 * Displays an error message on the screen.
 * @param message The error message to display.
 * @return
 */
- (void)showErrorMessage:(NSString *)message;
/*!
 * Displays an error message stating that a track needs to be added to the app.
 * @return
 */
- (void)showNoSongMessage;
/*!
 * Shows a message dialogue with a confirmation and a cancel button.
 * @param title The title of the message dialogue box.
 * @param message The message to display.
 * @param okay The text to display in the confirmation button.
 * @return
 */
- (void)showTwoButtonMessage:(NSString *)title :(NSString *)message :(NSString *)okay;
/*!
 * Shows a message dialogue with a text input and confirmation/cancel buttons.
 * @param title The title of the message dialogue box.
 * @param message The message to display.
 * @param okay The text to display in the confirmation button.
 * @param initText The initial text to display in the text input box.
 * @return
 */
- (void)showTwoButtonMessageInput:(NSString *)title :(NSString *)message :(NSString *)okay :(NSString *)initText;
/*!
 * Gets the value of the global volume slider.
 * @return The value of the global volume slider.
 */
- (float)getVolumeSliderValue;

/*!
 * Saves the non-track-specific settings of the app.
 */
- (void)saveSettings;

@end
