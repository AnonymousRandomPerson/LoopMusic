//
//  LoopFinderAuto.h
//  LoopMusic
//
//  Created by Johann Gan on 1/21/18.
//  Copyright © 2018 Cheng Hann Gan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AudioData.h"


/// Automatic loop finder for audio files.
@interface LoopFinderAuto : NSObject
{
    // INTERNAL VALUES
    /// The "first" frame of the audio file, for the purposes of loop finding.
    UInt32 firstFrame;
    /// The length of the entire analysis window, in frames, for the purposes of loop finding.
    UInt32 nFrames;   // Could be smaller than the actual audio length due to things like fade truncation.
    
    /// Average volume of the entire audio file, in dB.
    float avgVol;
    /// After shifting the audio volume such that avgVol is equal to this value, comparisons between spectra will only factor in frequency bins where both bins have a volume greater than 0 dB.
    float dBLevel;
    /// Reference power level used in decibel calculation.
    float powRef;
    
    /// Regularization for confidence value calculation.
    float confidenceRegularization;
    
    // END INTERNAL VALUES
}

// PARAMETERS
/// The number of duration value candidates to return from loop finding.
@property(nonatomic) NSInteger nBestDurations;
/// The number of start-end frame pairs to return per lag value from loop finding.
@property(nonatomic) NSInteger nBestPairs;

/// Number of seconds from the sliding mean square difference calculation to ignore, counting from the first value.
@property(nonatomic) float leftIgnore;
/// Number of seconds from the sliding mean square difference calculation to ignore, counting from the last value.
@property(nonatomic) float rightIgnore;

/// Tolerance for sample difference between starting frame and ending frame for an acceptable loop point pair.
@property(nonatomic) SInt16 sampleDiffTol;
/// Minimum number of seconds of harmonic similarity needed for a pair to count as a loop.
@property(nonatomic) float minLoopLength;
/// Minimum time difference in seconds to be used for non-maximum suppression when selecting top lag values and top start-end pairs.
@property(nonatomic) float minTimeDiff;

/// FFT size for each window in spectrogram calculations. Must be a power of two.
@property(nonatomic) UInt32 fftLength;
/// Overlap percent for spectrogram windows.
@property(nonatomic) float overlapPercent;


/// Optional estimation of the starting time. -1 is a flag for nothing.
@property(nonatomic) float t1Estimate;
/// Optional estimation of the ending time. -1 is a flag for nothing.
@property(nonatomic) float t2Estimate;

/// Deviation from estimated duration value to allow.
@property(nonatomic) float tauRadius;
/// Deviation from estimated starting time to allow.
@property(nonatomic) float t1Radius;
/// Deviation from estimated ending time to allow.
@property(nonatomic) float t2Radius;

// Penalty magnitudes must be from 0 to 1 inclusive. 0 represents a rectangular weighting, where every value within the acceptable range is weighted equally for ranking. 1 represents absolute certainty in estimate, and deviation from the estimate will not be allowed. For values in between, deviation from estimate is penalized by a multiple that increases linearly with deviation. For higher penalty values, the line has a higher slope.
/// Penalty magnitude for deviation from estimated duration value.
@property(nonatomic) float tauPenalty;
/// Penalty magnitude for deviation from estimated start time.
@property(nonatomic) float t1Penalty;
/// Penalty magnitude for deviation from estimated end time.
@property(nonatomic) float t2Penalty;


/// Flag for whether or not to automatically detect and remove a possible ending fade in the input audio data.
@property(nonatomic) bool useFadeDetection;

// END PARAMETERS

/*!
 * Finds and ranks possible loop points given some audio data.
 * @param audio The audio data structure containing the audio samples.
 * @return An NSDictionary* containing: [(NSArray* of NSNumber*) "baseDurations" - base loop duration (lag) values in frames, (NSArray* of NSArray* of NSNumber*) "startFrames" - corresponding start frames for each base duration value, (NSArray* of NSArray* of NSNumber*) "endFrames" - corresponding end frames, (NSArray* of NSNumber*) "confidences" - confidence values for each base duration value, (NSArray* of NSArray* of NSNumber*) "sampleDifferences" - sample differences for each start-end pair].
 */
- (NSDictionary *)findLoop:(const AudioData *)audio;

/*!
 * Sets all parameters to default values.
 */
- (void)useDefaultParams;

/*!
 * Detects fade in an audio signal.
 * @param audio The audio data structure containing the audio samples.
 * @return The sample number of the beginning of the fade.
 */
- (UInt32)detectFade:(const AudioData *)audio;

@end
