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
#import <Accelerate/Accelerate.h>
#import <MediaPlayer/MediaPlayer.h>
#import "AudioPlayer.h"
#import "UILoopSlider.h"

/// The name of the current track.
extern NSString *settingsSongString;

@interface LoopMusicViewController : UIViewController
{
    /// The audio player that plays tracks.
    AudioPlayer *audioPlayer;
    
    /// The database index of the current track.
    NSInteger musicNumber;
    /// The resource URL of the current track.
    NSURL *url;
    /// Whether a track is being manually chosen by the user.
    bool choose;
    /// The name of the current track.
    NSString *songString;
    /// Whether a track is being chosen by its name.
    bool chooseSongString;
    /// The amount of microseconds that the current track has been playing for before the shuffle timer was most recently activated... only updated at pause time, and reset at stop time or song changes.
    double elapsedTimeBeforeTimerActivation;
    
    /// The amount of milliseconds that the current track has been fading out for.
    double fadeTime;
    /// The amount to decrement volume per tick when fading out.
    double volumeDec;
    
    /// Button to randomize the current track.
    IBOutlet UIButton *randomSong;
    /// Button to play/resume the current track.
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
    /// Whether a screen other than the main screen is showing.
    bool occupied;
    
    /// Timer used to loop tracks.
    NSTimer *shuffleTimer;
    /// Timer used to fade out tracks.
    NSTimer *fadeTimer;
    /// Timer used to update the playback slider.
    NSTimer *playSliderUpdateTimer;
    
    /// The actual amount of time (in microseconds) to play a track before shuffling.
    double currentShuffleTime;
    /// The actual amount of repeats to play a track for before shuffling.
    double currentShuffleRepeats;
}

typedef enum {
    NONE,
    TIME,
    REPEATS
} ShuffleSetting;

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
/// Playback slider.
@property (nonatomic, retain) IBOutlet UILoopSlider *playSlider;

/// FFT setup object for vDSP.
@property(nonatomic) FFTSetup fftSetup;
/// N used for the current FFT setup object.
@property(nonatomic) unsigned long nSetup;

/*!
 * Chooses a random track to be played.
 * @param sender The object that called this function.
 */
- (IBAction)randomSong:(id)sender;
/*!
 * Plays or resumes the current track.
 * @param sender The object that called this function.
 */
- (IBAction)playSong:(id)sender;
/*!
 * Pauses playback of the current track.
 * @param sender The object that called this function.
 */
- (IBAction)pauseSong:(id)sender;
/*!
 * Stops playback of the current track.
 * @param sender The object that called this function.
 */
- (IBAction)stopSong:(id)sender;
/*!
 * Suspends the slider update timer when the user starts interacting with the playback slider.
 * @param sender The object that called this function.
 */
- (IBAction)playSliderTouchDown:(id)sender;
/*!
 * Resumes the slider update timer after the user lets go of the playback slider.
 * @param sender The object that called this function.
 */
- (IBAction)playSliderTouchUp:(id)sender;
/*!
 * Updates the audio player time and the playback slider time when the slider is interacted with.
 * @param sender The object that called this function.
 */
- (IBAction)playSliderUpdate:(id)sender;
/*!
 * Navigates to the search screen.
 * @param sender The object that called this function.
 */
- (IBAction)searchSong:(id)sender;
/*!
 * Navigates to the settings screen.
 * @param sender The object that called this function.
 */
- (IBAction)settings:(id)sender;
/*!
 * Navigates to the loop finder screen.
 * @param sender The object that called this function.
 */
- (IBAction)loopFinder:(id)sender;
/*!
 * Navigates to a certain screen.
 * @param screen The name of the screen to navigate to.
 */
- (IBAction)changeScreen:(NSString *)screen;
/*!
 * Navigates to the previous screen.
 * @param sender The object that called this function.
 */
- (IBAction)back:(id)sender;
/*!
 * Sets the global volume of the app.
 * @param sender The object that called this function.
 */
- (IBAction)setGlobalVolume:(id)sender;
/*!
 * Saves the global volume of the app to the settings file.
 * @param sender The object that called this function.
 */
- (IBAction)saveGlobalVolume:(id)sender;

/*!
 * Opens the track database.
 */
- (void)openDB;
/*!
 * Closes the track database.
 */
- (void)closeDB;
/*!
 * Prepares a database query.
 * @param query The query to prepare.
 */
- (void)prepareQuery:(NSString *)query;
/*!
 * Executes a query to update the database.
 * @param query The query to update the database with.
 */
- (void)updateDB:(NSString *)query;
/*!
 * Gets an integer from a database query.
 * @param query The database query to get an integer with.
 * @return The integer obtained from the database query.
 */
- (NSInteger)getIntegerDB:(NSString *)query;
/*!
 * Gets multiple integers from a database query.
 * @param query The database query to get the integers with.
 * @return Array of integers obtained from the database query.
 */
- (NSArray*)getMultiIntegerDB:(NSString *)query;
/*!
 * Opens the database and updates it.
 * @param query The query to update the database with.
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
 */
- (void)addSongToDB:(NSString *)name :(NSURL *)url;
/*!
 * Wipes the database clean.
 */
- (void)wipeDB;

/*!
 * Loads the total number of tracks in the app.
 * @return The total number of tracks in the app.
 */
- (NSInteger)initializeTotalSongs;
/*!
 * Increments the total number of tracks in the app.
 */
- (void)incrementTotalSongs;
/*!
 * Decrements the total number of tracks in the app.
 */
- (void)decrementTotalSongs;
/*!
 * Increments the total number of tracks in the current playlist.
 */
- (void)incrementPlaylistSongs;
/*!
 * Decrements the total number of tracks in the current playlist.
 */
- (void)decrementPlaylistSongs;
/*!
 * Updates the database with changes to the current playlist.
 */
- (void)updatePlaylistSongs;
/*!
 * Gets the IDs of all tracks in the current playlist.
 * @return An array (of NSNumber *) containing the IDs of all tracks in the current playlist.
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
 * @return An array containing the names of all playlist names.
 */
- (NSMutableArray*)getPlaylistNameList;
/*!
 * Gets the name of the current playlist.
 * @return The name of the current playlist.
 */
- (NSString *)getPlaylistName;
/*!
 * Updates the name of the current playlist according to the playlist index.
 */
- (void)updatePlaylistName;
/*!
 * Updates the name of the current playlist.
 * @param name The new name of the current playlist.
 */
- (void)updatePlaylistName:(NSString *)name;

/*!
 * Plays a track from the beginning.
 */
- (void)playMusic;
/*!
 * Sets audio players to the URL of the current track.
 * @param newURL The URL of the current track.
 */
- (void)setAudioPlayer:(NSURL*)newURL;
/*!
 * Refreshes the play slider with the most current loop and track data.
 */
- (void)refreshPlaySlider;
/*!
 * Sets the loop start point for the audio player.
 * @param newStart The new start point.
 */
- (void)setAudioLoopStart:(NSTimeInterval)newStart;
/*!
 * Sets the loop end point for the audio player.
 * @param newEnd The new start point.
 */
- (void)setAudioLoopEnd:(NSTimeInterval)newEnd;
/*!
 * Returns the loop start point for the audio player in frames.
 * @return A UInt32 of the audio player's start frame.
 */
- (UInt32)getAudioLoopStartFrame;
/*!
 * Returns the loop start point for the audio player in seconds.
 * @return A NSTimeInterval of the audio player's start point.
 */
- (NSTimeInterval)getAudioLoopStart;
/*!
 * Returns the loop end point for the audio player in frames.
 * @return An NSTimeInterval of the audio player's end frame.
 */
- (UInt32)getAudioLoopEndFrame;
/*!
 * Returns the loop end point for the audio player in seconds.
 * @return An NSTimeInterval of the audio player's end point.
 */
- (NSTimeInterval)getAudioLoopEnd;

/*!
 * Updates the fade-out volume decrement according to the fade-out setting and the current track.
 */
- (void)updateVolumeDec;
/*!
 * Plays a specific track.
 * @param newSong The name of the track to play.
 */
- (void)chooseSong:(NSString *)newSong;
/*!
 * Sets whether a screen other than the main screen is showing.
 * @param newOccupied Whether a screen other than the main screen is showing.
 */
- (void)setOccupied:(bool)newOccupied;
/*!
 * Gets the name of the current track.
 * @return The name of the current track.
 */
- (NSString *)getSongName;
/*!
 * Sets the name of the current track.
 * @param newName The name to set the current track to.
 */
- (void)setNewSongName:(NSString *)newName;
/*!
 * Gets the currently loaded audio data in the audio player.
 * @return The AudioData pointer to the current track.
 */
- (AudioData *)getAudioData;
/*!
 * Gets the duration of the current track in frames.
 * @return The duration of the current track in frames.
 */
- (UInt32)getAudioFrameDuration;
/*!
 * Gets the duration of the current track in seconds.
 * @return The duration of the current track in seconds.
 */
- (double)getAudioDuration;
/*!
 * Calls the audioPlayer's method to find a loop time.
 * @return An array of suitable start times.
 */
- (NSMutableArray *)audioFindLoopTime;
/*!
 * Sets the playback time to five seconds before the loop time.
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
 */
- (void)setVolume:(double)newVolume;
/*!
 * Gets the playback time of the current track.
 * @return The playback time of the current track.
 */
- (float)findTime;
/*!
 * Gets whether the audio player is playing.
 * @return Boolean for whether the audio player is playing.
 */
- (bool)isPlaying;
/*!
 * Sets the loop time of the current track.
 * @param newLoopTime The time to set the loop time to.
 * @return The result code of the database update query for setting the loop time.
 */
- (NSInteger)setLoopTime:(double)newLoopTime;
/*!
 * Sets the playback time of the current track.
 * @param newCurrentTime The time to set the playback time to.
 */
- (void)setCurrentTime:(double)newCurrentTime;
/*!
 * Recalculates internal shuffle time limit parameter, based on the base time and a random variation.
 */
- (void)recalculateShuffleTime;

/*!
 * Displays an error message on the screen.
 * @param message The error message to display.
 */
- (void)showErrorMessage:(NSString *)message;
/*!
 * Displays an error message stating that a track needs to be added to the app.
 */
- (void)showNoSongMessage;
/*!
 * Shows a message dialogue with a confirmation and a cancel button.
 * @param title The title of the message dialogue box.
 * @param message The message to display.
 * @param okay The text to display in the confirmation button.
 */
- (void)showTwoButtonMessage:(NSString *)title :(NSString *)message :(NSString *)okay;
/*!
 * Shows a message dialogue with a text input and confirmation/cancel buttons.
 * @param title The title of the message dialogue box.
 * @param message The message to display.
 * @param okay The text to display in the confirmation button.
 * @param initText The initial text to display in the text input box.
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
