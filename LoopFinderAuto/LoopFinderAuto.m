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
    
    t1Estimate = -1;
    t2Estimate = -1;
    
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
    vDSP_Stride stride = 1;
    
    // Remove fade if specified.
    floatAudio->numFrames = audio->numFrames;
    if (useFadeDetection)
    {
        UInt32 fadeStart = [self detectFade:audio];
        if (fadeStart != 0)
        {
            floatAudio->numFrames = fadeStart;
        }
    }
//    floatAudio->numFrames = [self nextPow2:floatAudio->numFrames] >> 1;
    
    // Convert 16-bit audio to 32-bit floating point audio, and calculate the average decibel level.
    floatAudio->channel0 = malloc(floatAudio->numFrames * sizeof(float));
    floatAudio->channel1 = malloc(floatAudio->numFrames * sizeof(float));
    audio16bitFormatToFloatFormat(audio, floatAudio);
    avgVol = [self powToDB:calcAvgPow(floatAudio)];
    
    NSLog(@"Done converting. Average volume = %f", avgVol);
    
    [self performFFTSetup:floatAudio];  // THIS IS THE EXPENSIVE PART
    
//    // Test copying - All of them take almost no time
//    NSLog(@"Copying...");
//    float *cpy = malloc(floatAudio->numFrames * sizeof(float));
////    memcpy(cpy, floatAudio->channel0, floatAudio->numFrames * sizeof(float));
//
////    float zero=0;
////    vDSP_vsadd(floatAudio->channel0, 1, &zero, cpy, 1, floatAudio->numFrames);
//
//    for (int i = 0; i < floatAudio->numFrames; i++)
//        *(cpy + i) = *(floatAudio->channel0 + i);
//
//    free(cpy);
//    NSLog(@"Done copying.");
    
//    // Dictionary with mutable arrays test
//    NSDictionary *dict = @{@"array": [[NSMutableArray alloc] init]};
//    NSLog(@"%@", dict);
//    [dict[@"array"] addObject:@50];
//    NSLog(@"%@", dict);

//    float *fft0Memory = malloc(floatAudio->numFrames * sizeof(float));
//    float *observedMemory = malloc(floatAudio->numFrames * sizeof(float));
//    float *bufferMemory = malloc(floatAudio->numFrames * sizeof(float));
//    DSPSplitComplex observed = {observedMemory, observedMemory + floatAudio->numFrames / 2};
//    DSPSplitComplex fft0 = {fft0Memory, fft0Memory + floatAudio->numFrames / 2};
//    DSPSplitComplex buffer = {bufferMemory, bufferMemory + floatAudio->numFrames / 2};
//
//
//    vDSP_ctoz((DSPComplex *)floatAudio->channel0, 2*stride, &observed, 1, floatAudio->numFrames/2);
//    vDSP_fft_zropt(fftSetup, &observed, 1, &fft0, 1, &buffer, log2(floatAudio->numFrames), kFFTDirection_Forward);
//
//    NSLog(@"Finished FFT of length %i.", floatAudio->numFrames);
    
//    // Test for overlapLengths
//    vDSP_Length nA = 1;
//    vDSP_Length nB = 1;
//    float val = 1;
//    float *a = malloc(nA * sizeof(float));
//    float *b = malloc(nB * sizeof(float));
//    vDSP_vfill(&val, a, 1, nA);
//    vDSP_vfill(&val, b, 1, nB);
//    float *overlapLengths = malloc((nA + nB - 1) * sizeof(float));
//    [self calcSlidingOverlapLength:a :nA :b :nB :overlapLengths];
//    for (int i = 0; i < nA+nB-1; i++)
//        NSLog(@"%f", *(overlapLengths + i));
//    free(a);
//    free(b);
//    free(overlapLengths);
    
    
    // Running sum test
//    vDSP_Length n = 5;
//    float val = 1;
//    float inc = 1;
//    float weight = 1;
//    float *a = malloc((n+1) * sizeof(float));
//    a[0] = 0;
//    vDSP_vramp(&val, &inc, a+1, 1, n);
//    for (int i = 0; i < n+1; i++)
//        NSLog(@"%f", *(a + i));
//    vDSP_vrsum(a, 1, &weight, a, 1, n+1);
//    for (int i = 0; i < n+1; i++)
//        NSLog(@"%f", *(a + i));
    
//    // Test for combinedPowerOutput
//    vDSP_Length nA = 4;
//    vDSP_Length nB = 4;
//    float valA = 1;
//    float valB = valA + nA;
//    float inc = 1;
//    float *a = malloc(nA * sizeof(float));
//    float *b = malloc(nB * sizeof(float));
//    vDSP_vramp(&valA, &inc, a, 1, nA);
//    vDSP_vramp(&valB, &inc, b, 1, nB);
////    vDSP_vfill(&valA, a, 1, nA);
////    vDSP_vfill(&valB, b, 1, nB);
//    float *combinedPowers = malloc((nA + nB - 1) * sizeof(float));
//    [self calcSlidingCombinedPowerOutput:a :nA :b :nB :combinedPowers];
//    for (int i = 0; i < nA+nB-1; i++)
//        NSLog(@"%f", *(combinedPowers + i));
//    free(a);
//    free(b);
//    free(combinedPowers);
    
//    // Test for normalizationFactors
//    vDSP_Length nA = 5;
//    vDSP_Length nB = 5;
//    float valA = 1;
//    float valB = valA + nA;
//    float inc = 2;
//    float *a = malloc(nA * sizeof(float));
//    float *b = malloc(nB * sizeof(float));
//    vDSP_vramp(&valA, &inc, a, 1, nA);
//    vDSP_vramp(&valB, &inc, b, 1, nB);
////    vDSP_vfill(&valA, a, 1, nA);
////    vDSP_vfill(&valB, b, 1, nB);
//    float *normFactors = malloc((nA + nB - 1) * sizeof(float));
//    [self calcNoiseAndOverlapLengthNormalizationFactors:a :nA :b :nB :normFactors];
//    for (int i = 0; i < nA+nB-1; i++)
//        NSLog(@"%f", *(normFactors + i));
//    free(a);
//    free(b);
//    free(normFactors);
    
//    // Test for xcorr/slidingSSE/slidingWeightedMSE
//    vDSP_Length nA = 5;
//    vDSP_Length nB = 5;
//    float valA = 1;
//    float valB = valA+nA;
//    float inc = 1;
//    float *a = malloc(nA * sizeof(float));
//    float *b = malloc(nB * sizeof(float));
//    vDSP_vramp(&valA, &inc, a, 1, nA);
//    vDSP_vramp(&valB, &inc, b, 1, nB);
////    vDSP_vfill(&valB, b, 1, nB);
//    float *sliding = malloc((nA + nB - 1) * sizeof(float));
//    [self slidingWeightedMSE:a :nA :b :nB :sliding];
//    for (int i = 0; i < nA+nB-1; i++)
//        NSLog(@"%f", *(sliding + i));
//
//    // Test for spacedMinima
//    self.minTimeDiff = 1.0/FRAMERATE;
//    vDSP_Length nBest = 5;
//    NSDictionary *minima = [self spacedMinima:sliding :nA+nB-1 :nBest];
//    NSLog(@"# best: %li", nBest);
//    NSLog(@"%@", minima);
//
//    free(a);
//    free(b);
//    free(sliding);
    
//    // Test for autoSlidingWeightedMSE
//    vDSP_Length nA = 10;
//    float valA = 1;
//    float inc = 1;
//    float *a = malloc(nA * sizeof(float));
//    vDSP_vramp(&valA, &inc, a, 1, nA);
////    vDSP_vfill(&valA, a, 1, nA);
//    float *automse = malloc(nA * sizeof(float));
//    [self autoSlidingWeightedMSE:a :nA :automse];
//    for (int i = 0; i < nA; i++)
//        NSLog(@"%f", *(automse + i));
//
//    // Test for selectInitialCandidatesAuto
//    self.nBestDurations = 3;
//    self.minTimeDiff = 3.0/FRAMERATE;
//    NSDictionary *minima = [self spacedMinima:automse :nA :self.nBestDurations];
//    NSLog(@"# best: %li", self.nBestDurations);
//    NSLog(@"%@", minima);
//
//    free(a);
//    free(automse);
    
    // EVIDENTLY FLOAT PRECISION MIGHT NOT ENOUGH FOR XCORR WHEN DEALING WITH VERY LARGE AMOUNTS OF DATA. TRY SWITCHING OVER TO DOUBLE PRECISION? (ALTHOUGH THE INACCURACIES SEEM TO BECOME NEGLIGIBLE FOR THE MSE)
    
    
    
    
//    // Test for smoothen
//    vDSP_Length nA = 10;
//    float valA = 1;
//    float inc = 1;
//    float *a = malloc(nA * sizeof(float));
////    vDSP_vramp(&valA, &inc, a, 1, nA);
////     vDSP_vfill(&valA, a, 1, nA);
//
//    for (int j = 1; j <= 9; j++)
//    {
//        for (int i = 0; i < nA; i++)
//            *(a + i) = cos(6.28 * i / nA);
//        [self smoothen:a :nA :j];
//        NSLog(@"----------");
//        NSLog(@"r = %i", j);
//        for (int i = 0; i < nA; i++)
//            NSLog(@"%f", *(a + i));
//        NSLog(@"----------");
//    }
//    free(a);
    
//    // Test for calcSpectrum
//    vDSP_Length nA = 10000;
//    float *a = malloc(nA * sizeof(float));
//    float *spectrum = 0;
//    vDSP_Length nBins = 0;
//    for (int i = 0; i < nA; i++)
//        *(a + i) = cos(400*6.28 * i / (float)FRAMERATE) + cos(2000*6.28 * i / (float)FRAMERATE + 3.14);
//    [self calcSpectrum:a :nA :&spectrum :&nBins :FRAMERATE/2];
//    NSLog(@"nBins = %i", nBins);
//    for (int i = 0; i < nBins; i++)
//        NSLog(@"%f", *(spectrum + i));
//    free(spectrum);
    
//    // Test for spectrumMSE
//    float a[6] = {1.123, 2.3, 20, 4.92, .5, 1e-13};
//    float b[6] = {2.5, 2.1, 3.05, 2.65, 1.2, 5e-13};
//    float mse = 0;
//    [self spectrumMSE:a :b :6 :&mse];
//    NSLog(@"MSE = %f", mse);
    
//    // Tests for AudioDataFloat analysis functions
//    float array1[5] = {.4, .1, -.5, .3, .1};
//    float array2[5] = {-.2, .24, .1, -.5, .2};
////    float array1[5] = {1, 0, 2, -2, 3};
////    float array2[5] = {1, -1, 1, -2, 1};
//
//    AudioDataFloat *testAudio = malloc(sizeof(AudioDataFloat));
//    testAudio->numFrames = 5;
//    testAudio->channel0 = malloc(testAudio->numFrames * sizeof(float));
//    testAudio->channel1 = malloc(testAudio->numFrames * sizeof(float));
//    for (int i = 0; i < testAudio->numFrames; i++)
//    {
//        *(testAudio->channel0 + i) = array1[i];
//        *(testAudio->channel1 + i) = array2[i];
//    }
//
//    // Test for audioAutoMSE
//    NSLog(@"audioAutoMSE");
//    float *result = malloc(testAudio->numFrames * sizeof(float));
//    [self audioAutoMSE:testAudio :result];
//    for (int i = 0; i < testAudio->numFrames; i++)
//        NSLog(@"%f", *(result + i));
//
//    free(result);
//
//    // Test for audioMSE
//    NSLog(@"audioMSE");
//    UInt32 startFirst = 0;
//    UInt32 endFirst = 4;
//    UInt32 startSecond = 1;
//    UInt32 endSecond = 2;
//    UInt32 resultLength = endFirst-startFirst+1+endSecond-startSecond+1-1;
//    result = malloc(resultLength * sizeof(float));
//    [self audioMSE:testAudio :startFirst :endFirst :startSecond :endSecond :result];
//    for (int i = 0; i < resultLength; i++)
//        NSLog(@"%f", *(result + i));
//
//    free(result);
//
//    free(testAudio->channel0);
//    free(testAudio->channel1);
//    free(testAudio);

    
//    // Tests for diffSpectrogram
//    const int arraysize = 20;
//    float array1[arraysize] = {.4, .1, -.5, .3, .1, .6, -.1, .2, .4, .02, .05, .123, .52, -.12, .9, .8, -.2, -.243, -.5, 0.01};
//    float array2[arraysize] = {-.2, .24, .1, -.5, .2, .3, -.4, .1, 1, -.4, .03, .34, .1, -.2, .5, .3, -.04, -.03, -1, 1e-5};
////    float array1[10] = {1, 0, 2, -2, 3};
////    float array2[10] = {1, -1, 1, -2, 1};
//
//    AudioDataFloat *testAudio = malloc(sizeof(AudioDataFloat));
//    testAudio->numFrames = arraysize;
//    testAudio->channel0 = malloc(testAudio->numFrames * sizeof(float));
//    testAudio->channel1 = malloc(testAudio->numFrames * sizeof(float));
//    for (int i = 0; i < testAudio->numFrames; i++)
//    {
//        *(testAudio->channel0 + i) = array1[i];
//        *(testAudio->channel1 + i) = array2[i];
//    }
//    // Tests for analyzeLagValue
//    UInt32 lag = 4;
//    self.fftLength = 4;
//    self.minTimeDiff = 4.0/FRAMERATE;
//    self.minLoopLength = 1.0/FRAMERATE;
//    self.sampleDiffTol = 1.01;
////    self.t1Estimate = 1.0/FRAMERATE;
////    self.t2Estimate = 15.0/FRAMERATE;
////    self.t1Penalty = 1;
////    self.t2Penalty = 1;
//    NSDictionary *lagAnalysis = [self analyzeLagValue:testAudio :lag];
//    NSLog(@"fftLength = %i", self.fftLength);
//    NSLog(@"minTimeDiff = %f", self.minTimeDiff);
//    NSLog(@"minLoopLength = %f", self.minLoopLength);
//    NSLog(@"sampleDiffTol = %f", self.sampleDiffTol);
//    NSLog(@"results: %@", lagAnalysis);
//
//    // Tests for findLoopNoEst
//    self.leftIgnore = 0;
//    self.rightIgnore = 0;
//    NSDictionary *algorithmResults = [self findLoopNoEst:testAudio];
//    NSLog(@"RESULTS: %@", algorithmResults);
    
//
//    DiffSpectrogramInfo *output = malloc(sizeof(DiffSpectrogramInfo));
//    [self diffSpectrogram:testAudio :lag :output];
//    for (int i = 0; i < output->nWindows; i++)
//    {
//        NSLog(@"MSE: %f", *(output->mses + i));
////        NSLog(@"start: %li", *(output->startSamples + i));
////        NSLog(@"window size: %li", *(output->windowSizes + i));
////        NSLog(@"window duration: %f", *(output->effectiveWindowDurations + i));
//    }
//
//    // Tests for inferLoopRegion
//    NSDictionary *region = [self inferLoopRegion:output->mses :output->nWindows :output->effectiveWindowDurations];
//    NSLog(@"%@", region);
//    UInt32 regionStartIndex = [region[@"start"] unsignedIntegerValue];
//    UInt32 regionEndIndex = [region[@"end"] unsignedIntegerValue];
//
//    // Tests for calcMatchLength and calcMismatchLength
//    float match = [self calcMatchLength:output->mses :output->nWindows :output->effectiveWindowDurations :[region[@"cutoff"] floatValue]];
//    float mismatch = [self calcMismatchLength:output->mses :output->nWindows :regionStartIndex :regionEndIndex :output->effectiveWindowDurations :[region[@"cutoff"] floatValue]];
//
//    NSLog(@"Match length = %f", match);
//    NSLog(@"Mismatch length = %f", mismatch);
//
//    // Tests for refineLag
//    self.minTimeDiff = 4.0/FRAMERATE;
//    UInt32 regionStartSample = *(output->startSamples + regionStartIndex);
//    UInt32 regionEndSample = *(output->startSamples + regionEndIndex) + *(output->windowSizes + regionEndIndex) - 1;
//    UInt32 newLag = [self refineLag:testAudio :lag :regionStartSample :regionEndSample];
//    NSLog(@"base lag = %u", lag);
//    NSLog(@"refined lag = %u", newLag);
//
//    // Tests for biasedMeanSpectrumMSE
//    float loss = [self biasedMeanSpectrumMSE:output->mses :regionStartIndex :regionEndIndex];
//    NSLog(@"loss = %f", loss);
//
//    // Tests for findEndpointPairsSpectra/findEndpointPairs
//    self.sampleDiffTol = 1.005;
//    self.minLoopLength = 0;
//    NSLog(@"minTimeDiff: %f", self.minTimeDiff);
//    NSLog(@"minLoopLength: %f", self.minLoopLength);
//    NSLog(@"sDiffTol: %f", self.sampleDiffTol);
//    NSDictionary *pairs = [self findEndpointPairsSpectra:testAudio :lag :output->mses :output->nWindows :output->startSamples :output->windowSizes :regionStartIndex :regionEndIndex];
//    NSLog(@"pairs: %@", pairs);
//
//    // With estimates and some variance
//    self.t1Estimate = 9.0/FRAMERATE;
//    self.t2Estimate = 16.0/FRAMERATE;
//    self.t1Penalty = 0.9;
//    self.t2Penalty = 0.9;
//    NSDictionary *pairsEstimate = [self findEndpointPairsSpectra:testAudio :lag :output->mses :output->nWindows :output->startSamples :output->windowSizes :regionStartIndex :regionEndIndex];
//    NSLog(@"pairsEstimate: %@", pairsEstimate);
//
//    // Tests for findEndpointPairsNoVariance
//    self.t1Estimate = 3.0/FRAMERATE;
//    self.t2Estimate = 5.0/FRAMERATE;
//    self.t1Penalty = 1;
//    self.t2Penalty = 1;
//    NSDictionary *pairsNoVar = [self findEndpointPairsSpectra:testAudio :lag :output->mses :output->nWindows :output->startSamples :output->windowSizes :regionStartIndex :regionEndIndex];
//    NSLog(@"pairsNoVar: %@", pairsNoVar);

//    // Tests for estimate methods
//    self.minLoopLength = 0.1;
//    self.t1Estimate = 1.5;
//    self.t1Penalty = .9;
//    self.t1Radius = .5;
//    self.t2Estimate = 9.5;
//    self.t2Penalty = 0.9;
//    NSLog(@"t1: %u, t2: %u, loopMode: %i, s1: %i, s2: %i", [self hasT1Estimate], [self hasT2Estimate], [self loopMode], [self s1Estimate], [self s2Estimate]);
//    UInt32 testNumFrames = 441001;
//    NSLog(@"tau: %@, t1: %@, t2: %@", [self tauLimits:testNumFrames], [self t1Limits:testNumFrames], [self t2Limits:testNumFrames]);

//    freeDiffSpectrogramInfo(output);
//    free(output);
//
//    free(testAudio->channel0);
//    free(testAudio->channel1);
//    free(testAudio);
    
    
//    // Tests for calcConfidence
//    NSArray *confs = [self calcConfidence:@[@0, @0]];
//    NSLog(@"confs: %@", confs);
    
//    [self useDefaultParams];
    NSDictionary *realResults = [self findLoopNoEst:floatAudio];
    NSLog(@"RESULTS: %@", realResults);
    
//    free(fft0Memory);
//    free(observedMemory);
//    free(bufferMemory);
    free(floatAudio->channel0);
    free(floatAudio->channel1);
    free(floatAudio);
    
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
                              @"confidences": @[@0.2729, @0.2475, @0.18, @0.1132, @0.0693, @0.0464, @0.0259, @0.0212, @0.0125, @0.0112],
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
    
//    return results;
    return realResults;
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
