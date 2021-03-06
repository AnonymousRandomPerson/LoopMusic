//
//  LoopFinderAuto+fadeDetection.h
//  LoopMusic
//
//  Created by Johann Gan on 2/18/18.
//  Copyright © 2018 Cheng Hann Gan. All rights reserved.
//

#import "LoopFinderAuto.h"

// TO IMPLEMENT
/// Methods for preliminary fade detection/removal in audio signals.
@interface LoopFinderAuto (fadeDetection)

/*!
 * Detects fade in an audio signal.
 * @param audio The audio data structure containing the audio samples.
 * @return The sample number of the beginning of the fade.
 */
- (UInt32)detectFade:(const AudioData *)audio;

@end
