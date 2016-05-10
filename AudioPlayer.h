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

@interface AudioPlayer : NSObject
{
    /// The audio player that plays tracks.
    @public AEAudioFilePlayer *audioPlayer;
}

/// The audio controller that manages the audio player.
@property(nonatomic, retain) AEAudioController *audioController;
/// The current playback time of the audio player.
@property(nonatomic) NSTimeInterval currentTime;
/// The current volume of the audio player.
@property(nonatomic) float volume;
/// Whether the audio player is currently playing.
@property(nonatomic) bool playing;
/// The duration of the track in the audio player.
@property(nonatomic, readonly) double duration;

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

@end

#endif /* AudioPlayer_h */
