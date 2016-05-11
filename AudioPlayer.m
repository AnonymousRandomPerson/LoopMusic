//
//  AudioPlayer.m
//  LoopMusic
//
//  Created by Cheng Hann Gan on 5/9/16.
//  Copyright © 2016 Cheng Hann Gan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AudioPlayer.h"

/// The frame rate of the audio player.
static const int FRAMERATE = 44100;
/// Represents a 0 value on an unsigned sample.
static const int MIDSAMPLEVALUE = 32768;
/// Represents the lowest possible unsigned sample value.
static const int MAXSAMPLEVALUE = 65535;

@implementation AudioPlayer

- (id)init
{
    self = [super init];
    _audioController = [[AEAudioController alloc] initWithAudioDescription:AEAudioStreamBasicDescriptionNonInterleaved16BitStereo
                                                             inputEnabled:false];
    _audioController.automaticLatencyManagement = false;
    /// Holds error messages that may occur during audio controller initialization.
    NSError *error;
    bool result = [_audioController start:&error];
    if (!result)
    {
        NSLog(@"%@", [error description]);
    }
    return self;
}

- (NSTimeInterval)currentTime
{
    return _currentFrame / (NSTimeInterval)FRAMERATE;
}

- (void)setCurrentTime:(NSTimeInterval)currentTime
{
    _currentFrame = currentTime * FRAMERATE;
}

- (float)volume
{
    return _volume;
}

- (void)setVolume:(float)volume
{
    if (volume < 0)
    {
        volume = 0;
    }
    _volume = volume;
}

- (bool)playing
{
    return _playing;
}

- (double)duration
{
    return _numFrames / (NSTimeInterval)FRAMERATE;
}

- (NSTimeInterval)loopStart
{
    return _loopStart / (NSTimeInterval)FRAMERATE;
}

- (void)setLoopStart:(NSTimeInterval)loopStart
{
    _loopStart = loopStart * FRAMERATE;
}

- (NSTimeInterval)loopEnd
{
    return _loopEnd / (NSTimeInterval)FRAMERATE;
}

- (void)setLoopEnd:(NSTimeInterval)loopEnd
{
    _loopEnd = loopEnd * FRAMERATE;
}

- (void)play
{
    _playing = true;
    if ([self numChannels] == 0)
    {
        [_audioController addChannels:@[_blockChannel]];
    }
}

- (void)stop
{
    _playing = false;
    if ([self numChannels] > 0)
    {
        [_audioController removeChannels:@[_blockChannel]];
    }
}

/*!
 * Gets the number of active channels in the audio controller.
 * @return The number of active channels in the audio controller.
 */
- (NSInteger)numChannels
{
    return [[_audioController channels] count];
}

- (void)initAudioPlayer:(NSURL *)newURL :(NSError *)error
{
    AEAudioFileLoaderOperation *operation = [[AEAudioFileLoaderOperation alloc] initWithFileURL:newURL
                                                                         targetAudioDescription:_audioController.audioDescription];
    [operation start];
    if (operation.error)
    {
        error = operation.error;
    }
    else
    {
        _bufferList = operation.bufferList;
        if (!_playingList)
        {
            _playingList = _bufferList;
        }
        _numFrames = operation.lengthInFrames;
        
        if (!_blockChannel)
        {
            _blockChannel =
            [AEBlockChannel channelWithBlock:^(const AudioTimeStamp *time, UInt32 frames, AudioBufferList *audio)
            {
                /// The current frame number after this block is executed.
                for (int i = 0; i < frames; i++)
                {
                    for (int j = 0; j < 2; j++)
                    {
                        UInt16 sample = ((UInt16 *)_playingList->mBuffers[j].mData)[_currentFrame];
                        if (sample < MIDSAMPLEVALUE)
                        {
                            sample = sample * _volume;
                        }
                        else
                        {
                            sample = MAXSAMPLEVALUE - (MAXSAMPLEVALUE - sample) * _volume;
                        }
                        ((SInt16*)audio->mBuffers[j].mData)[i] = MIDSAMPLEVALUE - (MIDSAMPLEVALUE - sample) * 1;
                    }
                    _currentFrame++;
                    if (_currentFrame >= _numFrames)
                    {
                        _currentFrame = 0;
                    }
                    else if (_currentFrame >= _loopEnd)
                    {
                        _currentFrame = _loopStart;
                    }
                }
                _playingList = _bufferList;
            }];
        }
    }
}

@end
