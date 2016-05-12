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
static const UInt32 FRAMERATE = 44100;
/// The number of frames that have to match for the loop finder to accept a time.
static const UInt32 NUMMATCHINGFRAMES = 1;
/// The range of the loop finder's search.
static const float SEARCHRANGE = 1;
/// The tolerance of the loop finder's search.
static const float SEARCHTOLERANCE = 300;

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
    return audioData->currentFrame / (NSTimeInterval)FRAMERATE;
}

- (void)setCurrentTime:(NSTimeInterval)currentTime
{
    bufferAudioData->currentFrame = currentTime * FRAMERATE;
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
    return audioData->numFrames / (NSTimeInterval)FRAMERATE;
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

- (bool)loading
{
    return audioData->loading;
}

- (void)setLoading:(bool)loading
{
    if (audioData)
    {
        audioData->loading = loading;
    }
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
    if (freeData)
    {
        for (int i = 0; i < 2; i++)
        {
            free(freeData->playingList->mBuffers[i].mData);
        }
        free(freeData->playingList);
        free(freeData);
        freeData = nil;
    }
    AEAudioFileLoaderOperation *operation = [[AEAudioFileLoaderOperation alloc] initWithFileURL:newURL
                                                                         targetAudioDescription:_audioController.audioDescription];
    [operation start];
    if (operation.error)
    {
        error = operation.error;
    }
    else
    {
        /// Audio data to be loaded into the buffer.
        AudioData *newData = malloc(sizeof(AudioData));
        newData->numFrames = operation.lengthInFrames;
        newData->playingList = operation.bufferList;
        newData->loading = false;
        newData->currentFrame = 0;
        bufferAudioData = newData;
        
        if (!_blockChannel)
        {
            _blockChannel =
            [AEBlockChannel channelWithBlock:^(const AudioTimeStamp *time, UInt32 frames, AudioBufferList *audio)
            {
                AudioData *oldData = audioData;
                audioData = bufferAudioData;
                if (oldData != audioData)
                {
                    freeData = oldData;
                }
                for (int i = 0; i < frames; i++)
                {
                    for (int j = 0; j < 2; j++)
                    {
                        ((SInt16 *)audio->mBuffers[j].mData)[i] = ((SInt16 *)audioData->playingList->mBuffers[j].mData)[audioData->currentFrame] * _volume;
                    }
                    audioData->currentFrame++;
                    if (audioData->currentFrame >= audioData->numFrames)
                    {
                        audioData->currentFrame = 0;
                    }
                    else if (!audioData->loading && audioData->currentFrame >= _loopEnd)
                    {
                        audioData->currentFrame = _loopStart;
                    }
                }
            }];
        }
    }
}

- (NSTimeInterval)findLoopTime
{
    if (_loopEnd > audioData->numFrames - NUMMATCHINGFRAMES)
    {
        return -1;
    }
    
    /// The range of the search in frames.
    UInt32 searchRangeFrames = SEARCHRANGE * FRAMERATE;
    if (audioData->numFrames < searchRangeFrames << 1 || _loopStart >= _loopEnd )
    {
        return -1;
    }
    
    /// The end frames that must match with the start frames to be accepted.
    SInt16 endFrames[NUMMATCHINGFRAMES * 2];
    
    /// For loop iterator.
    UInt32 i, j;
    /// Counter for filling arrays.
    UInt32 arrayCounter = 0;
    for (i = _loopEnd; i < _loopEnd + NUMMATCHINGFRAMES; i++)
    {
        for (j = 0; j < 2; j++)
        {
            endFrames[arrayCounter++] = ((SInt16 *)audioData->playingList->mBuffers[j].mData)[i];
        }
    }
    
    /// Whether an acceptable start point was found.
    bool found;
    /// The start point being examined.
    UInt32 foundPoint = -1;
    for (UInt32 k = 0; k < searchRangeFrames; k++)
    {
        for (int n = -1; n < 2; n += 2)
        {
            arrayCounter = 0;
            foundPoint = _loopStart + k * n;
            found = true;
            for (i = foundPoint; i < foundPoint + NUMMATCHINGFRAMES; i++)
            {
                for (j = 0; j < 2; j++)
                {
                    /// The current sample from the loop start being compared.
                    SInt16 startSample = ((SInt16 *)audioData->playingList->mBuffers[j].mData)[i];
                    /// The current sample from the loop end being compared.
                    SInt16 endSample = endFrames[arrayCounter++];
                    if (abs(endSample - startSample) > SEARCHTOLERANCE)
                    {
                        found = false;
                        break;
                    }
                    else if (arrayCounter > 5)
                    {
                        NSLog(@"%f", foundPoint / (NSTimeInterval)FRAMERATE);
                    }
                }
                if (!found)
                {
                    break;
                }
            }
            if (found)
            {
                break;
            }
        }
        if (found)
        {
            break;
        }
    }
    
    return found ? foundPoint / (NSTimeInterval)FRAMERATE : -1;
}

@end
