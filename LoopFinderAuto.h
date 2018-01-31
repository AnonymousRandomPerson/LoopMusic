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
    /// The "last" frame of the audio file, for the purposes of loop finding.
    UInt32 lastFrame;   // Could be smaller than the actual last frame due to things like fade truncation.
    
    /// Average volume of the entire audio file, in dB.
    float avgVol;
    /// After shifting the audio volume such that avgVol is equal to this value, comparisons between spectra will only factor in frequency bins where both bins have a volume greater than 0 dB.
    float dBLevel;
    /// Reference power level used in decibel calculation.
    float powRef;
    
    /// Regularization for confidence value calculation.
    float confidenceRegularization;
    
    // END INTERNAL VALUES
    
    
    // PARAMETERS
    /// The number of lag value candidates to return from loop finding.
    NSInteger nBestLags;
    /// The number of start-end frame pairs to return per lag value from loop finding.
    NSInteger nBestPairs;
    
    /// Number of seconds from the sliding mean square difference calculation to ignore, counting from the first value.
    float leftIgnore;
    /// Number of seconds from the sliding mean square difference calculation to ignore, counting from the last value.
    float rightIgnore;
    
    /// Tolerance for sample difference between starting frame and ending frame for an acceptable loop point pair.
    SInt16 sampleDiffTol;
    /// Minimum number of seconds of harmonic similarity needed for a pair to count as a loop.
    float minLoopLength;
    /// Minimum time difference in seconds to be used for non-maximum suppression when selecting top lag values and top start-end pairs.
    float minTimeDiff;
    
    /// FFT size for each window in spectrogram calculations. Must be a power of two.
    UInt32 fftLength;
    /// Overlap percent for spectrogram windows.
    float overlapPercent;
    
    
    /// Optional estimation of the starting time.
    float t1Estimate;
    /// Optional estimation of the ending time.
    float t2Estimate;
    
    /// Deviation from estimated lag value to allow.
    float tauRadius;
    /// Deviation from estimated starting time to allow.
    float t1Radius;
    /// Deviation from estimated ending time to allow.
    float t2Radius;
    
    // Penalty magnitudes must be from 0 to 1 inclusive. 0 represents a rectangular weighting, where every value within the acceptable range is weighted equally for ranking. 1 represents absolute certainty in estimate, and deviation from the estimate will not be allowed. For values in between, deviation from estimate is penalized by a multiple that increases linearly with deviation. For higher penalty values, the line has a higher slope.
    /// Penalty magnitude for deviation from estimated lag value.
    float tauPenalty;
    /// Penalty magnitude for deviation from estimated start time.
    float t1Penalty;
    /// Penalty magnitude for deviation from estimated end time.
    float t2Penalty;
    
    
    /// Flag for whether or not to automatically detect and remove a possible ending fade in the input audio data.
    bool useFadeDetection;
    
    // END PARAMETERS
}

/*!
 * Finds and ranks possible loop points given some audio data.
 * @param audio The audio data structure containing the audio samples (ALSO NEEDS THE SAMPLING FREQUENCY?!).
 * @return An NSDictionary* containing: [(NSArray* of UInt32) base lag values, (NSArray* of NSArray* of UInt32) corresponding start frames for each base lag value, (NSArray* of NSArray* of UInt32) corresponding end frames, (NSArray* of NSNumber) confidence values for each base lag value, (NSArray* of NSArray* of SInt16) sample differences for each start-end pair].
 */
- (NSDictionary *)findLoop:(AudioData *)audio;

@end
