//
//  LoopFinderAuto.m
//  LoopMusic
//
//  Created by Johann Gan on 1/21/18.
//  Copyright © 2018 Cheng Hann Gan. All rights reserved.
//

#import "LoopFinderAuto.h"

@implementation LoopFinderAuto

@synthesize nBestDurations, nBestPairs, leftIgnore, rightIgnore, sampleDiffTol, minLoopLength, minTimeDiff, fftLength, overlapPercent, t1Estimate, t2Estimate, tauRadius, t1Radius, t2Radius, tauPenalty, t1Penalty, t2Penalty, useFadeDetection;

- (id)init
{
    [self useDefaultParams];
    
    return self;
}

- (void)useDefaultParams
{
    // INTERNAL VALUES
    firstFrame = 0;
    nFrames = 0;    // Placeholder value
    
    avgVol = 0;     // Placeholder value
    dBLevel = 60;
    powRef = 1e-12;

    confidenceRegularization = 2.5;
    
    // PARAMETERS
    nBestDurations = 10;
    nBestPairs = 5;
    
    leftIgnore = 5;
    rightIgnore = 5;
    sampleDiffTol = 300;    // DETERMINE A GOOD VALUE FOR THIS.
    minLoopLength = 5;
    minTimeDiff = 0.1;
    fftLength = (1 << 17);
    overlapPercent = 50;
    
    t1Estimate = -1;
    t2Estimate = -1;
    
    tauRadius = 5;
    t1Radius = 5;
    t2Radius = 5;
    
    tauPenalty = 0;
    t1Penalty = 0;
    t2Penalty = 0;
    
    useFadeDetection = false;
}

// Helpers for input validation of numbers floored at a minimum value or kept within a range.
- (float)sanitizeFloat: (float)inputValue :(float)minValue
{
    return MAX(inputValue, minValue);
}
- (float)sanitizeFloat: (float)inputValue :(float)minValue :(float)maxValue
{
    return MIN(MAX(inputValue, minValue), maxValue);
}
- (NSInteger)sanitizeInt: (NSInteger)inputValue :(NSInteger)minValue
{
    return MAX(inputValue, minValue);
}


// Custom setters with validation
- (void)setNBestDurations:(NSInteger)nBestDurations
{
    self->nBestDurations = [self sanitizeInt:nBestDurations:1];
}
- (void)setNBestPairs:(NSInteger)nBestPairs
{
    self->nBestPairs = [self sanitizeInt:nBestPairs:1];
}
- (void)setLeftIgnore:(float)leftIgnore
{
    self->leftIgnore = [self sanitizeFloat:leftIgnore :0];
}
- (void)setRightIgnore:(float)rightIgnore
{
    self->rightIgnore = [self sanitizeFloat:rightIgnore :0];
}
- (void)setMinLoopLength:(float)minLoopLength
{
    self->minLoopLength = [self sanitizeFloat:minLoopLength :0];
}
- (void)setMinTimeDiff:(float)minTimeDiff
{
    self->minTimeDiff = [self sanitizeFloat:minTimeDiff :0];
}

- (void)setFftLength:(UInt32)fftLength
{
    // 0 doesn't work
    if (!fftLength)
    {
        self->fftLength = 1;
        return;
    }
    
    // Rounds to the nearest power of 2, picking the higher one if tied.
    UInt32 next2 = [self nextPow2:fftLength];
    self->fftLength = (next2 - fftLength > fftLength - (next2 >> 1)) ? next2 >> 1 : next2;
}
// Helper for setFftLength to calculate the next highest power of 2
- (UInt32)nextPow2:(UInt32)num
{
    num--;
    num |= num >> 1;
    num |= num >> 2;
    num |= num >> 4;
    num |= num >> 8;
    num |= num >> 16;
    return ++num;
}
- (void)setOverlapPercent:(float)overlapPercent
{
    self->overlapPercent = [self sanitizeFloat:overlapPercent :0 :100];
}
- (void)setT1Radius:(float)t1Radius
{
    self->t1Radius = [self sanitizeFloat:t1Radius :0];
}
- (void)setT2Radius:(float)t2Radius
{
    self->t2Radius = [self sanitizeFloat:t2Radius :0];
}
- (void)setTauRadius:(float)tauRadius
{
    self->tauRadius = [self sanitizeFloat:tauRadius :0];
}
- (void)setT1Penalty:(float)t1Penalty
{
    self->t1Penalty = [self sanitizeFloat:t1Penalty :0 : 1];
}
- (void)setT2Penalty:(float)t2Penalty
{
    self->t2Penalty = [self sanitizeFloat:t2Penalty :0 : 1];
}
- (void)setTauPenalty:(float)tauPenalty
{
    self->tauPenalty = [self sanitizeFloat:tauPenalty :0 : 1];
}



- (NSDictionary *)findLoop:(const AudioData *)audio
{
    // Calculate values for internal usage.
    nFrames = audio->numFrames;
    if (useFadeDetection)
    {
        UInt32 fadeStart = [self detectFade:audio];
        if (fadeStart != 0)
        {
            nFrames = fadeStart;
        }
    }
    avgVol = [self calcAvgVol:audio];

    // Test values: results for "Celebration of Peace"
    NSDictionary *results = [@{@"baseDurations": @[@7144200, @793800, @6350400, @1190700, @7342650,
                                                  @7243425, @7541100, @7441875, @396900, @297675],
                              @"startFrames": @[@[@918249, @951058, @853372, @935102, @969283],
                                                @[@4315482, @4294907, @4322444, @4244666, @4218510],
                                                @[@1313729, @1271290, @1296676, @1369138, @1266868],
                                                @[@4224596, @4289313, @4233635, @4210327, @4256929],
                                                @[@419678, @439403, @473669, @444998, @489504],
                                                @[@615157, @620770, @653188, @556267, @628376],
                                                @[@552840, @642350, @654001, @588233, @572311],
                                                @[@509880, @444075, @502587, @517550, @476629],
                                                @[@2108701, @2132442, @2125510, @2137604, @2094129],
                                                @[@4409221, @4488838, @4398200, @4391538, @4508074]],
                              @"endFrames": @[@[@8062449, @8095258, @7997572, @8079302, @8113483],
                                              @[@5109282, @5088707, @5116244, @5038466, @5012310],
                                              @[@7664129, @7621690, @7647076, @7719538, @7617268],
                                              @[@5415296, @5480013, @5424335, @5401027, @5447629],
                                              @[@7762328, @7782053, @7816319, @7787648, @7832154],
                                              @[@7858582, @7864195, @7896613, @7799692, @7871801],
                                              @[@8093940, @8183450, @8195101, @8129333, @8113411],
                                              @[@7951755, @7885950, @7944462, @7959425, @7918504],
                                              @[@2505601, @2529342, @2522410, @2534504, @2491029],
                                              @[@4706896, @4786513, @4695875, @4689213, @4805749]],
                              @"confidences": @[@0.2729, @0.2475, @0.18, @0.1132, @0.0693,
                                                @0.0464, @0.0259, @0.0212, @0.0125, @0.0112],
                              @"sampleDifferences": @[@[@0.0006714, @0.0006714, @0.0007629, @0.0008545, @0.0008545],
                                                      @[@0.0037, @0.0038, @0.0042, @0.0063, @0.0065],
                                                      @[@0.0032, @0.0042, @0.0051, @0.0057, @0.0075],
                                                      @[@0.0056, @0.0059, @0.006, @0.0063, @0.0065],
                                                      @[@0.0037, @0.0037, @0.0064, @0.0072, @0.0076],
                                                      @[@0.0062, @0.007, @0.007, @0.0076, @0.0077],
                                                      @[@0.0039, @0.006, @0.0061, @0.0062, @0.0068],
                                                      @[@0.0037, @0.0061, @0.0064, @0.0069, @0.0074],
                                                      @[@0.0044, @0.0053, @0.0053, @0.0056, @0.0059],
                                                      @[@0.0048, @0.006, @0.006, @0.0063, @0.0068]]
                              }
                             copy];
    return results;
}

- (UInt32)detectFade:(const AudioData *)audio
{
    return 0;
}

// Helper function to calculate the average volume of an audio sample
- (float)calcAvgVol:(const AudioData *)audio
{
    return 0;
}

@end
