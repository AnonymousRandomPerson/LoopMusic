//
//  AudioData.h
//  LoopMusic
//
//  Created by Johann Gan on 1/21/18.
//  Copyright © 2018 Cheng Hann Gan. All rights reserved.
//

#ifndef AudioData_h
#define AudioData_h

#import <TheAmazingAudioEngine.h>

/// The frame rate of the audio player.
extern const UInt32 FRAMERATE;

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

#endif /* AudioData_h */
