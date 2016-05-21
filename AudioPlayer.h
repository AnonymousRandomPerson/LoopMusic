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


/// Contains data for an audio track.
typedef struct AudioData
{
    /// The number of frames in the current track.
    UInt32 numFrames;
    /// The current playback frame of the audio player.
    UInt32 currentFrame;
    /// Whether a new track is being loaded.
    bool loading;
    /// The sample data for the playing track.
    AudioBufferList *playingList;
} AudioData;

@interface AudioPlayer : NSObject
{
    /// The audio controller that manages the audio player.
    AEAudioController *_audioController;
    /// The channel used to play audio.
    AEBlockChannel *_blockChannel;
    
    /// Pointer to the current audio track.
    AudioData *audioData;
    /// Data for the current audio track.
    AudioData audioDataStore;
    /// Data for the queued audio track.
    AudioData *bufferAudioData;
    /// Audio data to free from memory.
    AudioData *freeData;
    
    /// The current volume of the audio player.
    float _volume;
    /// Whether the audio player is currently playing.
    bool _playing;
    /// The time that the current track will loop back to when looping.
    UInt32 _loopStart;
    /// The time that the current track will loop back from when looping.
    UInt32 _loopEnd;
    
    /// Timer for freeing tracks from memory.
    NSTimer *freeTimer;
}

/// The current playback time of the audio player.
@property(nonatomic) NSTimeInterval currentTime;
/// The current volume of the audio player.
@property(nonatomic) float volume;
/// Whether the audio player is currently playing.
@property(nonatomic, readonly) bool playing;
/// The duration of the track in the audio player.
@property(nonatomic, readonly) double duration;
/// The time that the current track will loop back to when looping.
@property(nonatomic) NSTimeInterval loopStart;
/// The time that the current track will loop back from when looping.
@property(nonatomic) NSTimeInterval loopEnd;
/// Whether a new track is being loaded.
@property(nonatomic) bool loading;

/*!
 * Starts playback of the audio player.
 * @return
 */
- (void)play;

/*!
 * Stops playback of the audio player.
 * @return
 */
- (void)stop;

/*!
 * Initializes the audio player.
 * @param newURL The audio file to initialize the audio player with.
 * @param error Will be set if any errors occur during initialization.
 * @return
 */
- (void)initAudioPlayer:(NSURL *)newURL :(NSError *)error;

/*!
 * Finds suitable start times to loop to.
 * @return An array of suitable start times.
 */
- (NSMutableArray *)findLoopTime;

@end

#endif /* AudioPlayer_h */
