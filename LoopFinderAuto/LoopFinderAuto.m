//
//  LoopFinderAuto.m
//  LoopMusic
//
//  Created by Johann Gan on 1/21/18.
//  Copyright © 2018 Cheng Hann Gan. All rights reserved.
//

#import "LoopFinderAuto.h"
#import "LoopFinderAuto+differencing.h"
#import "LoopFinderAuto+spectra.h"
#import "LoopFinderAuto+analysis.h"
#import "LoopFinderAuto+synthesis.h"
#import "LoopFinderAuto+fadeDetection.h"

@implementation LoopFinderAuto

@synthesize nBestDurations, nBestPairs, leftIgnore, rightIgnore, sampleDiffTol, minLoopLength, minTimeDiff, fftLength, overlapPercent, t1Estimate, t2Estimate, tauRadius, t1Radius, t2Radius, tauPenalty, t1Penalty, t2Penalty, useFadeDetection, fftSetup, nSetup;

- (id)init
{
    t1Estimate = -1;
    t2Estimate = -1;
    [self useDefaultParams];
    
    return self;
}

- (void)useDefaultParams
{
    // INTERNAL VALUES
    firstFrame = 0;
//    nFrames = 0;    // Placeholder value
    
    avgVol = 0;     // Placeholder value
    dBLevel = 60;
    powRef = 1e-12;
    
    noiseRegularization = 1e-3;
    confidenceRegularization = 2.5;
    
    // PARAMETERS
    nBestDurations = 10;
    nBestPairs = 5;
    
    leftIgnore = 5;
    rightIgnore = 5;
    sampleDiffTol = 0.05;    // DETERMINE A GOOD VALUE FOR THIS.
    minLoopLength = 5;
    minTimeDiff = 0.1;
    fftLength = (1 << 17);
    overlapPercent = 50;
    
    tauRadius = 1;
    t1Radius = 1;
    t2Radius = 1;
    
    tauPenalty = 0;
    t1Penalty = 0;
    t2Penalty = 0;
    
    useFadeDetection = false;
    
//    nSetup = 0;
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
- (NSInteger)sanitizeInt: (NSInteger)inputValue :(NSInteger)minValue :(NSInteger)maxValue
{
    return MIN(MAX(inputValue, minValue), maxValue);
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
    // 0 doesn't work. 1 causes problems with vDSP because it's odd.
    if (fftLength < 2)
    {
        self->fftLength = 2;
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
    return MAX(2, ++num); // 0 doesn't work. 1 causes problems with vDSP because it's odd.
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

- (bool)hasT1Estimate
{
    return self.t1Estimate != -1;
}
- (bool)hasT2Estimate
{
    return self.t2Estimate != -1;
}

- (loopModeValue)loopMode
{
    if ([self hasT1Estimate] && [self hasT2Estimate])
        return loopModeT1T2;
    else if ([self hasT1Estimate])
        return loopModeT1Only;
    else if ([self hasT2Estimate])
        return loopModeT2Only;
    else
        return loopModeAuto;
}

- (UInt32)s1Estimate
{
    return roundf(self.t1Estimate * FRAMERATE);
}

- (UInt32)s2Estimate
{
    return roundf(self.t2Estimate * FRAMERATE);
}


float lastTime(UInt32 numFrames)
{
    return (float)(MAX(numFrames, 1) - 1) / FRAMERATE;  // Floor at 0.
}
// Helper for the three limit functions below.
- (NSArray *)estimateLimits:(UInt32)numFrames :(float)estimate :(float)penalty :(float)radius
{
    float lastFrameTime = lastTime(numFrames);
    if (penalty == 1)
        return @[[NSNumber numberWithFloat:estimate], [NSNumber numberWithFloat:estimate]];
    else if(penalty == 0)
        return @[[NSNumber numberWithFloat:[self sanitizeFloat:estimate-radius :0 :lastFrameTime]], [NSNumber numberWithFloat:[self sanitizeFloat:estimate+radius :0 :lastFrameTime]]];
    else
    {
        float minVal = [self sanitizeFloat:MAX(estimate - 1.0/[self slopeFromPenalty:penalty] + 1.0/FRAMERATE, estimate-radius) :0 :lastFrameTime];
        float maxVal = [self sanitizeFloat:MIN(estimate + 1.0/[self slopeFromPenalty:penalty] - 1.0/FRAMERATE, estimate+radius) :0 :lastFrameTime];
        return @[[NSNumber numberWithFloat:minVal], [NSNumber numberWithFloat:maxVal]];
    }
}
- (NSArray *)tauLimits:(UInt32)numFrames
{
    if ([self loopMode] != loopModeT1T2)
        return @[[NSNumber numberWithFloat:self.minLoopLength], [NSNumber numberWithFloat:lastTime(numFrames)]];
    
    return [self estimateLimits:numFrames :self.t2Estimate - self.t1Estimate :self.tauPenalty :self.tauRadius];
}
- (NSArray *)t1Limits:(UInt32)numFrames
{
    if (![self hasT1Estimate])
    {
        if (![self hasT2Estimate])  // Ensures that when t2Limits calls t1Limits, infinite loops don't occur.
            return @[@0, [NSNumber numberWithFloat:lastTime(numFrames)-self.minLoopLength]];
        else
            return @[@0, [NSNumber numberWithFloat:[self sanitizeFloat:[[self t2Limits:numFrames][1] floatValue] - self.minLoopLength :0]]];
    }
    
    return [self estimateLimits:numFrames :self.t1Estimate :self.t1Penalty :self.t1Radius];
}
- (NSArray *)t2Limits:(UInt32)numFrames
{
    if (![self hasT2Estimate])
    {
        float lastFrameTime = lastTime(numFrames);
        if (![self hasT1Estimate])  // Ensures that when t1Limits calls t2Limits, infinite loops don't occur.
            return @[[NSNumber numberWithFloat:self.minLoopLength], [NSNumber numberWithFloat:lastFrameTime]];
        else
        {
            return @[[NSNumber numberWithFloat:[self sanitizeFloat:[[self t1Limits:numFrames][0] floatValue] + self.minLoopLength :0 :lastFrameTime]], [NSNumber numberWithFloat:lastFrameTime]];
        }
    }
    
    return [self estimateLimits:numFrames :self.t2Estimate :self.t2Penalty :self.t2Radius];
}


- (float)slopeFromPenalty:(float)penalty
{
    return tanf(penalty * M_PI/2);
}

//- (void)performFFTSetup
//{
//    [self performFFTSetupOfSize:(1 << 21)];
//}
- (void)performFFTSetup:(AudioDataFloat *)audio
{
    // For a sample of length n, an FFT of at least 2n-1 is needed for a cross-correlation between two vectors of length n. Round 2n-1 up to the nearest power of 2 for FFT.
    [self performFFTSetupOfSize:[self nextPow2:(2*audio->numFrames - 1)]];
}
// Skeleton for performFFTSetup and peformFFTSetup:
- (void)performFFTSetupOfSize:(unsigned long)n
{
//    NSLog(@"Existing n: %lu", nSetup);
    // Perform setup only if necessary.
    if (n > nSetup)
    {
        NSLog(@"Setting up FFT of length %lu", n);
        vDSP_destroy_fftsetup(fftSetup);
        fftSetup = vDSP_create_fftsetup(lround(log2(n)), kFFTRadix2);
        nSetup = n;
        NSLog(@"Done setting up FFT.");
    }
}
//- (void)performFFTDestroy
//{
//    vDSP_destroy_fftsetup(self->fftSetup);
//    self->nSetup = 0;
//    NSLog(@"Done destroying FFT.");
//}



- (NSDictionary *)findLoop:(const AudioData *)audio
{
    // To hold the floating-point-converted audio data.
    AudioDataFloat *floatAudio = malloc(sizeof(AudioDataFloat));
    
    // Remove fade if specified.
    floatAudio->numFrames = audio->numFrames;
    if (self.useFadeDetection)
    {
        UInt32 fadeStart = [self detectFade:audio];
        if (fadeStart != 0)
            floatAudio->numFrames = fadeStart;
    }
    
    // Convert 16-bit audio to 32-bit floating point audio, and calculate the average decibel level.
    floatAudio->channel0 = malloc(floatAudio->numFrames * sizeof(float));
    floatAudio->channel1 = malloc(floatAudio->numFrames * sizeof(float));
    audio16bitFormatToFloatFormat(audio, floatAudio);
    
    avgVol = [self powToDB:calcAvgPow(floatAudio)];
    
    // Prepare the FFT if needed
    [self performFFTSetup:floatAudio]; // THIS IS EXPENSIVE
    
    // Perform the algorithm
    NSDictionary *results;
    if ([self loopMode] == loopModeAuto)
    {
        results = [self findLoopNoEst:floatAudio];
        NSLog(@"RESULTS: %@", results);
    }
    else
    {
        results = [self findLoopWithEst:floatAudio];
        NSLog(@"RESULTS WITH ESTIMATES: %@", results);
    }
    
    free(floatAudio->channel0);
    free(floatAudio->channel1);
    free(floatAudio);
    
//    // Test values: results for "Celebration of Peace"
//    NSDictionary *results = [@{@"baseDurations": @[@7144200, @793800, @6350400, @1190700, @7342650,
//                                                  @7243425, @7541100, @7441875, @396900, @297675],
//                              @"startFrames": @[@[@918249, @951058, @853372, @935102, @969283],
//                                                @[@4315482, @4294907, @4322444, @4244666, @4218510],
//                                                @[@1313729, @1271290, @1296676, @1369138, @1266868],
//                                                @[@4224596, @4289313, @4233635, @4210327, @4256929],
//                                                @[@419678, @439403, @473669, @444998, @489504],
//                                                @[@615157, @620770, @653188, @556267, @628376],
//                                                @[@552840, @642350, @654001, @588233, @572311],
//                                                @[@509880, @444075, @502587, @517550, @476629],
//                                                @[@2108701, @2132442, @2125510, @2137604, @2094129],
//                                                @[@4409221, @4488838, @4398200, @4391538, @4508074]],
//                              @"endFrames": @[@[@8062449, @8095258, @7997572, @8079302, @8113483],
//                                              @[@5109282, @5088707, @5116244, @5038466, @5012310],
//                                              @[@7664129, @7621690, @7647076, @7719538, @7617268],
//                                              @[@5415296, @5480013, @5424335, @5401027, @5447629],
//                                              @[@7762328, @7782053, @7816319, @7787648, @7832154],
//                                              @[@7858582, @7864195, @7896613, @7799692, @7871801],
//                                              @[@8093940, @8183450, @8195101, @8129333, @8113411],
//                                              @[@7951755, @7885950, @7944462, @7959425, @7918504],
//                                              @[@2505601, @2529342, @2522410, @2534504, @2491029],
//                                              @[@4706896, @4786513, @4695875, @4689213, @4805749]],
//                              @"confidences": @[@0.2729, @0.2475, @0.18, @0.1132, @0.0693, @0.0464, @0.0259, @0.0212, @0.0125, @0.0112],
//                              @"sampleDifferences": @[@[@0.0006714, @0.0006714, @0.0007629, @0.0008545, @0.0008545],
//                                                      @[@0.0037, @0.0038, @0.0042, @0.0063, @0.0065],
//                                                      @[@0.0032, @0.0042, @0.0051, @0.0057, @0.0075],
//                                                      @[@0.0056, @0.0059, @0.006, @0.0063, @0.0065],
//                                                      @[@0.0037, @0.0037, @0.0064, @0.0072, @0.0076],
//                                                      @[@0.0062, @0.007, @0.007, @0.0076, @0.0077],
//                                                      @[@0.0039, @0.006, @0.0061, @0.0062, @0.0068],
//                                                      @[@0.0037, @0.0061, @0.0064, @0.0069, @0.0074],
//                                                      @[@0.0044, @0.0053, @0.0053, @0.0056, @0.0059],
//                                                      @[@0.0048, @0.006, @0.006, @0.0063, @0.0068]]
//                              }
//                             copy];
    
    return results;
}

- (float)powToDB:(float)power
{
    return 10 * log10(power / powRef);
}


// C-style helper functions.
void audio16bitToAudioFloat(SInt16 *data16bit, vDSP_Stride stride, float *dataFloat, vDSP_Length n)
{
    float maxAmp = 1 << 15;
    vDSP_vflt16(data16bit, stride, dataFloat, stride, n);
    vDSP_vsdiv(dataFloat, stride, &maxAmp, dataFloat, stride, n);
}
void audio16bitFormatToFloatFormat(const AudioData *audio16bit, AudioDataFloat *audioFloat)
{
    vDSP_Stride stride = 1;
    
    // POSSIBLE SPEEDUP: REDUCE EFFECTIVE FRAMERATE
//    vDSP_Stride stride = 4;
//    audioFloat->numFrames = ceilf((float)audioFloat->numFrames / stride);
    
    audio16bitToAudioFloat((SInt16 *)audio16bit->playingList->mBuffers[0].mData, stride, audioFloat->channel0, audioFloat->numFrames);
    audio16bitToAudioFloat((SInt16 *)audio16bit->playingList->mBuffers[1].mData, stride, audioFloat->channel1, audioFloat->numFrames);
}
float calcAvgPow(AudioDataFloat *audioFloat)
{
    vDSP_Stride stride = 1;
    
    float channel0meansquare = 0;
    float channel1meansquare = 0;
    vDSP_measqv(audioFloat->channel0, stride, &channel0meansquare, audioFloat->numFrames);
    vDSP_measqv(audioFloat->channel1, stride, &channel1meansquare, audioFloat->numFrames);
    return (channel0meansquare + channel1meansquare) / 2;
}

@end
