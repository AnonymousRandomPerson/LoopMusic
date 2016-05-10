//
//  AudioPlayer.m
//  LoopMusic
//
//  Created by Cheng Hann Gan on 5/9/16.
//  Copyright © 2016 Cheng Hann Gan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AudioPlayer.h"

@implementation AudioPlayer

- (id)init
{
    self = [super init];
    _audioController = [[AEAudioController alloc] initWithAudioDescription:AEAudioStreamBasicDescriptionNonInterleaved16BitStereo
                                                             inputEnabled:false];
    /// Holds error messages that may occur during audio controller initialization.
    NSError *error;
    bool result = [_audioController start:&error];
    if (!result)
    {
        NSLog(@"%@", [error description]);
    }
    return self;
}

- (AEAudioController *)audioController
{
    return _audioController;
}

- (NSTimeInterval)currentTime
{
    return audioPlayer.currentTime;
}

- (void)setCurrentTime:(NSTimeInterval)currentTime
{
    audioPlayer.currentTime = currentTime;
}

- (float)volume
{
    return audioPlayer.volume;
}

- (void)setVolume:(float)volume
{
    audioPlayer.volume = volume;
}

- (bool)playing
{
    return audioPlayer.channelIsPlaying;
}

- (void)setPlaying:(bool)playing
{
    audioPlayer.channelIsPlaying = playing;
}

- (double)duration
{
    return audioPlayer.duration;
}

- (void)play
{
    [audioPlayer playAtTime:0];
    self.playing = true;
}

- (void)stop
{
    self.playing = false;
}

- (void)initAudioPlayer:(NSURL *)newURL :(NSError *)error
{
    if (audioPlayer)
    {
        [_audioController removeChannels:@[audioPlayer]];
    }
    audioPlayer = [AEAudioFilePlayer audioFilePlayerWithURL:newURL
                                                      error:&error];
    if (!error)
    {
        [_audioController addChannels:@[audioPlayer]];
    }
}

@end
