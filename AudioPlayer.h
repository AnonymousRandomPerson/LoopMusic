//
//  AudioPlayer.h
//  LoopMusic
//
//  Created by Cheng Hann Gan on 5/9/16.
//  Copyright © 2016 Cheng Hann Gan. All rights reserved.
//

#ifndef AudioPlayer_h
#define AudioPlayer_h

#import <TheAmazingAudioEngine.h>
#import <math.h>
#import "AudioData.h"


@interface AudioPlayer : NSObject
{
    /// The audio controller that manages the audio player.
    AEAudioController *_audioController;
    /// The channel used to play audio.
    AEBlockChannel *_blockChannel;
    
    /// Pointer to the current audio track.
    AudioData *audioData;
    /// Data for the queued audio track.
    AudioData *bufferAudioData;
    /// Audio data to free from memory.
    AudioData *freeData;
    
    /// The current volume of the audio player.
    float _volume;
    /// The global volume of the app.
    float _globalVolume;
    /// Whether the audio player is currently playing.
    bool _playing;
    /// The time that the current track will loop back to when looping.
    UInt32 _loopStart;
    /// The time that the current track will loop back from when looping.
    UInt32 _loopEnd;
    /// The number of times the track has looped.
    NSUInteger loopCount;
    
    /// Timer for freeing tracks from memory.
    NSTimer *freeTimer;
}

/// The current playback time of the audio player.
@property(nonatomic) NSTimeInterval currentTime;
/// The current volume of the audio player.
@property(nonatomic) float volume;
/// The global volume of the app.
@property(nonatomic) float globalVolume;
/// Whether the audio player is currently playing.
@property(nonatomic, readonly) bool playing;
/// The duration of the track in the audio player in seconds.
@property(nonatomic, readonly) double duration;
/// The time at which to resume the track if paused.
@property(nonatomic) double pauseTime;
/// The time that the current track will loop back to when looping in seconds.
@property(nonatomic) NSTimeInterval loopStart;
/// The time that the current track will loop back from when looping in seconds.
@property(nonatomic) NSTimeInterval loopEnd;
/// Whether a new track is being loaded.
@property(nonatomic) bool loading;

/*!
 * Decrements the base volume.
 * @param volumeDec The amount to decrement by.
 */
- (void)decrementVolume:(float)volumeDec;

/*!
 * Returns the loop start point in frames.
 * @return The loop start point frame number.
 */
- (UInt32)loopStartFrame;
/*!
 * Returns the loop end point in frames.
 * @return The loop end point frame number.
 */
- (UInt32)loopEndFrame;
/*!
 * Returns the loop duration in frames.
 * @return The loop duration in frames.
 */
- (UInt32)frameDuration;

/*!
 * Converts a time in seconds to frame number.
 * @return The input time as a frame number.
 */
+ (UInt32)timeToFrame:(NSTimeInterval)time;
/*!
 * Converts a frame number to a time in seconds.
 * @return The input frame as a time in seconds.
 */
+ (NSTimeInterval)frameToTime:(UInt32)frame;


/*!
 * Starts/resumes playback of the audio player.
 */
- (void)play;

/*!
 * Pauses playback of the audio player.
 */
- (void)pause;

/*!
 * Stops playback of the audio player.
 */
- (void)stop;


/*!
 * Gets the current loop count
 */
- (NSUInteger)getLoopCount;
/*!
 * Resets the loop counter.
 */
- (void)resetLoopCounter;
/*!
 * Gets the repeat number, given an elapsed playback time in seconds.
 */
- (double)getRepeatNumber:(double)elapsedTime;

/*!
 * Initializes the audio player.
 * @param newURL The audio file to initialize the audio player with.
 * @param error Will be set if any errors occur during initialization.
 */
- (void)initAudioPlayer:(NSURL *)newURL :(NSError *)error;

/*!
 * Gets the currently loaded audio data in the audio player.
 * @return The AudioData pointer to the current track.
 */
- (AudioData *)getAudioData;

/*!
 * Checks if there is any audio data loaded into the player.
 * @return Whether there is any audio data loaded into the player.
 */
- (bool)hasAudioData;

/*!
 * Finds suitable start times to loop to.
 * @return An array of suitable start times.
 */
- (NSMutableArray *)findLoopTime;

@end

#endif /* AudioPlayer_h */
