//
//  LoopFinderAuto.m
//  LoopMusic
//
//  Created by Johann Gan on 1/21/18.
//  Copyright © 2018 Cheng Hann Gan. All rights reserved.
//

#import "LoopFinderAuto.h"

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
    floatAudio->stride = 1;
    
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
    floatAudio->numFrames = [self nextPow2:floatAudio->numFrames] >> 1;
    
    // Convert 16-bit audio to 32-bit floating point audio, and calculate the average decibel level.
    floatAudio->channel0 = (float *)malloc(floatAudio->numFrames * sizeof(float));
    floatAudio->channel1 = (float *)malloc(floatAudio->numFrames * sizeof(float));
    audio16bitFormatToFloatFormat(audio, floatAudio);
    avgVol = [self powToDB:calcAvgPow(floatAudio)];
    
    NSLog(@"Done converting. Average volume = %f", avgVol);
    
    [self performFFTSetup:floatAudio];  // THIS IS THE EXPENSIVE PART
    
//    // Test copying
//    NSLog(@"Copying...");
//    float *cpy = malloc(floatAudio->numFrames * sizeof(float));
////    memcpy(cpy, floatAudio->channel0, floatAudio->numFrames * sizeof(float));
//
//    float zero=0;
//    vDSP_vsadd(floatAudio->channel0, 1, &zero, cpy, 1, floatAudio->numFrames);
//    free(cpy);
//    NSLog(@"Done copying.");

    float *fft0Memory = malloc(floatAudio->numFrames * sizeof(float));
    float *observedMemory = malloc(floatAudio->numFrames * sizeof(float));
    float *bufferMemory = malloc(floatAudio->numFrames * sizeof(float));
    DSPSplitComplex observed = {observedMemory, observedMemory + floatAudio->numFrames / 2};
    DSPSplitComplex fft0 = {fft0Memory, fft0Memory + floatAudio->numFrames / 2};
    DSPSplitComplex buffer = {bufferMemory, bufferMemory + floatAudio->numFrames / 2};

    
    vDSP_ctoz((DSPComplex *)floatAudio->channel0, 2*floatAudio->stride, &observed, 1, floatAudio->numFrames/2);
    vDSP_fft_zropt(fftSetup, &observed, 1, &fft0, 1, &buffer, log2(floatAudio->numFrames), kFFTDirection_Forward);
    
    NSLog(@"Finished FFT of length %i.", floatAudio->numFrames);
    
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
//    vDSP_Length nA = 1000;
//    vDSP_Length nB = 1000;
//    float valA = 1;
//    float valB = 5;
//    float inc = 1;
//    float *a = malloc(nA * sizeof(float));
//    float *b = malloc(nB * sizeof(float));
//    vDSP_vramp(&valA, &inc, a, 1, nA);
////    vDSP_vramp(&valB, &inc, b, 1, nB);
//    vDSP_vfill(&valB, b, 1, nB);
//    float *sliding = malloc((nA + nB - 1) * sizeof(float));
//    [self slidingWeightedMSE:a :nA :b :nB :sliding];
//    for (int i = 0; i < nA+nB-1; i++)
//        NSLog(@"%f", *(sliding + i));
//    free(a);
//    free(b);
//    free(sliding);
    
//    // Test for autoSlidingWeightedMSE
//    vDSP_Length nA = 10000;
//    float valA = 1;
//    float inc = 1;
//    float *a = malloc(nA * sizeof(float));
////    vDSP_vramp(&valA, &inc, a, 1, nA);
//    vDSP_vfill(&valA, a, 1, nA);
//    float *automse = malloc(nA * sizeof(float));
//    [self autoSlidingWeightedMSE:a :nA :automse];
//    for (int i = 0; i < nA; i++)
//        NSLog(@"%f", *(automse + i));
//    free(a);
//    free(automse);
    
    // EVIDENTLY FLOAT PRECISION MIGHT NOT ENOUGH FOR XCORR WHEN DEALING WITH VERY LARGE AMOUNTS OF DATA. TRY SWITCHING OVER TO DOUBLE PRECISION? (ALTHOUGH THE INACCURACIES SEEM TO BECOME NEGLIGIBLE FOR THE MSE)
    
    
    free(fft0Memory);
    free(observedMemory);
    free(bufferMemory);
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

- (float)powToDB:(float)power
{
    return 10 * log10(power / powRef);
}




// Performs slidingWeightedMSE of a vector x with itself, and returns only the right half, due to symmetry. The size of result is n, the same size as x, representing MSE at all non-negative lag values, starting from zero.
- (void)autoSlidingWeightedMSE:(float *)x :(vDSP_Length)n :(float *)result
{
    float *fullSlidingMSE = (float *)malloc([self calcOutputLength:n :n] * sizeof(float));
    [self slidingWeightedMSE:x :n :x :n :fullSlidingMSE];
    memcpy(result, fullSlidingMSE + n-1, n * sizeof(float));
    free(fullSlidingMSE);
}
// Performs a noise-normalized (average power over the overlap interval) sliding MSE (SSE normalized by overlap interval length) calculation between signals a and b of lengths nA and nB, respectively. Result will be nA + nB - 1 elements long.
- (void)slidingWeightedMSE:(float *)a :(vDSP_Length)nA :(float *)b :(vDSP_Length)nB :(float *)result
{
    const vDSP_Stride stride = 1;
    vDSP_Length outputLength = [self calcOutputLength:nA :nB];
    
    [self slidingSSE:a :nA :b :nB :result];
    float *normFactors = (float *)malloc(outputLength * sizeof(float));
    
    [self calcNoiseAndOverlapLengthNormalizationFactors:a :nA :b :nB :normFactors];
    vDSP_vdiv(normFactors, stride, result, stride, result, stride, outputLength);
    free(normFactors);
}
// Performs a sliding sum-of-square-errors calculation, in the same manner as a cross-correlation, except summing the pointwise square differences between curves rather than the pointwise products.
- (void)slidingSSE:(float *)a :(vDSP_Length)nA :(float *)b :(vDSP_Length)nB :(float *)result
{
    // SSE(tau) = -2*xcorr(tau) + sum(a(overlap window)^2) + sum(b(overlap window)^2)
    //          = -2*xcorr(tau) + combined_pwr_output(overlap window)
    const vDSP_Stride stride = 1;
    vDSP_Length outputLength = [self calcOutputLength:nA :nB];
    [self xcorr:a :nA :b :nB :result];
    
    float *combinedPowers = (float *)malloc(outputLength * sizeof(float));
    [self calcSlidingCombinedPowerOutput:a :nA :b :nB :combinedPowers];
    float negative2 = -2;
    vDSP_vsma(result, stride, &negative2, combinedPowers, stride, result, stride, outputLength);
    free(combinedPowers);
}
// Performs a cross-correlation between signals a and b of lengths nA and nB, respectively. Result will be nA + nB - 1 elements long.
- (void)xcorr:(float *)a :(vDSP_Length)nA :(float *)b :(vDSP_Length)nB :(float *)result
{
    const vDSP_Stride stride = 1;
    vDSP_Length outputLength = [self calcOutputLength:nA :nB];
    vDSP_Length nMax = MAX(nA, nB);
    vDSP_Length nFFT = [self nextPow2:2*nMax-1];    // Also ensures nFFT >= 2
    vDSP_Length log2nFFT = log2(nFFT);
    
    float zero = 0;
    
    // zero-pad so that the cross-correlation ends up being the left-most part of the inverse fft, with only trailing zeros and no leading zeros.
    float *aPadded = (float *)malloc(nFFT * sizeof(float));
    float *bPadded = (float *)malloc(nFFT * sizeof(float));
    vDSP_vfill(&zero, aPadded, stride, nB-1);
    vDSP_vfill(&zero, aPadded+outputLength, stride, nFFT-outputLength);
    vDSP_vfill(&zero, bPadded+nB, stride, nFFT-nB);
    memcpy(aPadded+nB-1, a, nA * sizeof(float));
    memcpy(bPadded, b, nB * sizeof(float));
    
    
//    NSLog(@"aPadded");
//    for (int i = 0; i < nFFT; i++)
//        NSLog(@"%f", *(aPadded + i));
//    NSLog(@"bPadded");
//    for (int i = 0; i < nFFT; i++)
//        NSLog(@"%f", *(bPadded + i));
    
    // Do FFT on aPadded and bPadded.
    float *aSplitComplexMemory = malloc(nFFT * sizeof(float));
    float *bSplitComplexMemory = malloc(nFFT * sizeof(float));
    float *bufferMemory = malloc(2*nFFT * sizeof(float));   // 2x the size for later use in complex-complex inverse FFT
    DSPSplitComplex aSplitComplex = {aSplitComplexMemory, aSplitComplexMemory + nFFT/2};
    DSPSplitComplex bSplitComplex = {bSplitComplexMemory, bSplitComplexMemory + nFFT/2};
    DSPSplitComplex buffer = {bufferMemory, bufferMemory + nFFT/2};

    vDSP_ctoz((DSPComplex *)aPadded, 2*stride, &aSplitComplex, stride, nFFT/2);
    vDSP_ctoz((DSPComplex *)bPadded, 2*stride, &bSplitComplex, stride, nFFT/2);
    vDSP_fft_zript(fftSetup, &aSplitComplex, stride, &buffer, log2nFFT, kFFTDirection_Forward);
    vDSP_fft_zript(fftSetup, &bSplitComplex, stride, &buffer, log2nFFT, kFFTDirection_Forward);
    
//    NSLog(@"fft(a), full");
//    for (int i = 0; i < nFFT; i++)
//        NSLog(@"%f", *(aSplitComplex.realp + i));
//    NSLog(@"fft(a), real part");
//    for (int i = 0; i < nFFT/2; i++)
//        NSLog(@"%f", *(aSplitComplex.realp + i));
//    NSLog(@"fft(a), imaginary part");
//    for (int i = 0; i < nFFT/2; i++)
//        NSLog(@"%f", *(aSplitComplex.imagp + i));
    
    
    // Do unpacking of the FFT results and elementwise multiply aSplitComplex * conj(bSplitComplex), where aSplitComplex and bSplitComplex are the forward FFT results.
    float *fullXcorrMemory = malloc(2*nFFT * sizeof(float));
    DSPSplitComplex fullXcorr = {fullXcorrMemory, fullXcorrMemory + nFFT};
    
    vDSP_zvcmul(&bSplitComplex, stride, &aSplitComplex, stride, &fullXcorr, stride, nFFT/2);
    // Unpack and multiply the 0 and N/2 elements separately from the rest, due to packing format.
    *(fullXcorr.realp) = *(aSplitComplex.realp) * *(bSplitComplex.realp);
    *(fullXcorr.imagp) = 0;
    *(fullXcorr.realp + nFFT/2) = *(aSplitComplex.imagp) * *(bSplitComplex.imagp);
    *(fullXcorr.imagp + nFFT/2) = 0;
    // Normalize everything by 4 = 2^2, because each of the FFT values is scaled to be 2x the standard value.
    float normalizeFFT = 4;
    vDSP_vsdiv(fullXcorr.realp, stride, &normalizeFFT, fullXcorr.realp, stride, nFFT/2 + 1);
    vDSP_vsdiv(fullXcorr.imagp + 1, stride, &normalizeFFT, fullXcorr.imagp + 1, stride, nFFT/2 - 1);    // The 0 and n/2 + 1 elements are always 0, so no need to modify them.
    // Fill in the end of fullXcorr using the symmetry utilized in packing (mirrored around element nFFT/2, and disregarding element 0)
    vDSP_vsadd(fullXcorr.realp + 1, stride, &zero, fullXcorr.realp + nFFT-1, -stride, nFFT/2 - 1);
    float negative1 = -1;   // For flipping the sign on the imaginary part.
    vDSP_vsmul(fullXcorr.imagp + 1, stride, &negative1, fullXcorr.imagp + nFFT-1, -stride, nFFT/2 - 1);
    
    free(aSplitComplexMemory);
    free(bSplitComplexMemory);
    
//    NSLog(@"fullXcorr, real part");
//    for (int i = 0; i < nFFT; i++)
//        NSLog(@"%f", *(fullXcorr.realp + i));
//    NSLog(@"fullXcorr, imaginary part");
//    for (int i = 0; i < nFFT; i++)
//        NSLog(@"%f", *(fullXcorr.imagp + i));
    
    
    // Inverse FFT fullXcorr to get the actual cross-correlation, with zeros at the end.
    buffer.realp = bufferMemory; buffer.imagp = bufferMemory + nFFT;  // Resize the buffer.
    vDSP_fft_zipt(fftSetup, &fullXcorr, stride, &buffer, log2nFFT, kFFTDirection_Inverse);  // Note: complex FFT, not real FFT.
    free(bufferMemory);
    
//    NSLog(@"ifft, real part");
//    for (int i = 0; i < nFFT; i++)
//        NSLog(@"%f", *(fullXcorr.realp + i));
//    NSLog(@"ifft, imaginary part");
//    for (int i = 0; i < nFFT; i++)
//        NSLog(@"%f", *(fullXcorr.imagp + i));
    
    // Copy the first outputLength elements into <results> and ignore the trailing zeros. Normalize by nFFT, since complex inverse transforms use a scaling factor of that size.
    float scaleDown = (float)nFFT;
    vDSP_vsdiv(fullXcorr.realp, stride, &scaleDown, result, stride, outputLength);
    free(fullXcorrMemory);
    
    free(aPadded);
    free(bPadded);
}

// THE BELOW FUNCTIONS HAVE BEEN TESTED. THE ABOVE FUNCTIONS HAVE NOT YET BEEN TESTED.
// Supporting functions for slidingWeightedMSE to calculate the weights. The last argument is the output in each function.
- (void)calcNoiseAndOverlapLengthNormalizationFactors:(float *)a :(vDSP_Length)nA :(float *)b :(vDSP_Length)nB :(float *)normalizationFactors
{
    // Normalization for cross-correlation is done by regularized average power and sliding window overlap length.
    // The total combined power output is divided by 2*overlapLength to get the average power over the overlap window (/n) over both signals (/2). This value is then regularized by some predetermined small value to prevent division by zero.
    // The overlap length is used as-is.
    // Simple algebra results in a normalization factor of:
    //
    // combinedPower/2 + overlapLength*regularization
    //
    
    const vDSP_Stride stride = 1;
    vDSP_Length outputLength = [self calcOutputLength:nA :nB];
    float powerFactor = .5;
    float *combinedPowers = (float *)malloc(outputLength * sizeof(float));
    float *overlapLengths = (float *)malloc(outputLength * sizeof(float));
    
    [self calcSlidingCombinedPowerOutput:a :nA :b :nB :combinedPowers];
    [self calcSlidingOverlapLength:a :nA :b :nB :overlapLengths];
    
    vDSP_vsmsma(combinedPowers, stride, &powerFactor, overlapLengths, stride, &noiseRegularization, normalizationFactors, stride, outputLength);
    
    free(combinedPowers);
    free(overlapLengths);
}
- (void)calcSlidingCombinedPowerOutput:(float *)a :(vDSP_Length)nA :(float *)b :(vDSP_Length)nB :(float *)combinedPowerOutput
{
    // Sums the powers over the sliding cross-correlation overlap window across both signals.
    const vDSP_Stride stride = 1;
    vDSP_Length outputLength = [self calcOutputLength:nA :nB];
    vDSP_Length minLength = MIN(nA, nB);
    float weight = 1;
    
    // Pad each side with a 0 because of how vDSP_vrsum works (it ignores the first element when it takes a running sum).
    float *aPowers = (float *)malloc((nA+2) * sizeof(float));
    float *bPowers = (float *)malloc((nB+2) * sizeof(float));
    *(aPowers) = 0;
    *(bPowers) = 0;
    *(aPowers + nA+1) = 0;
    *(bPowers + nB+1) = 0;
    vDSP_vsq(a, stride, aPowers+1, stride, nA);
    vDSP_vsq(b, stride, bPowers+1, stride, nB);
    
    // Left part of combinedPowerOutput
    // +1 length for the guaranteed zero in front due to vDSP_vrsum
    float *aPowerForwardRunSum = (float *)malloc((minLength+1) * sizeof(float));
    float *bPowerBackwardRunSum = (float *)malloc((minLength+1) * sizeof(float));
    vDSP_vrsum(aPowers, stride, &weight, aPowerForwardRunSum, stride, minLength+1);
    vDSP_vrsum(bPowers+nB+1, -stride, &weight, bPowerBackwardRunSum, stride, minLength+1);
    
    vDSP_vadd(aPowerForwardRunSum+1, stride, bPowerBackwardRunSum+1, stride, combinedPowerOutput, stride, minLength);
    
    // Middle part of combinedPowerOutput
    float smallPower = 0;
    vDSP_Length nSliding = outputLength - (2*minLength-1);
    float *slidingLargePower = (float *)malloc(nSliding * sizeof(float));
    if (nB < nA)
    {
        smallPower = *(bPowerBackwardRunSum+minLength); // Last element
        vDSP_vswsum(aPowers+2, stride, slidingLargePower, stride, nSliding, minLength); // Start at the 2nd possibly non-zero element a aPowers and assign to slidingLargePower forwards.
    }
    else
    {
        smallPower = *(aPowerForwardRunSum+minLength);  // Last element
        vDSP_vswsum(bPowers+1, stride, slidingLargePower+nSliding-1, -stride, nSliding, minLength); // Start at the 1st possibly non-zero element and assign to slidingLargePower backwards.
    }
    
    vDSP_vsadd(slidingLargePower, stride, &smallPower, combinedPowerOutput+minLength, stride, nSliding);
    
    free(aPowerForwardRunSum);
    free(bPowerBackwardRunSum);
    free(slidingLargePower);
    
    // Right part of combinedPowerOutput (for minLength - 1, not minLength)
    // +1 length for the guaranteed zero in front.
    float *aPowerBackwardRunSum = (float *)malloc(minLength * sizeof(float));
    float *bPowerForwardRunSum = (float *)malloc(minLength * sizeof(float));
    vDSP_vrsum(aPowers+nA+1, -stride, &weight, aPowerBackwardRunSum, stride, minLength);
    vDSP_vrsum(bPowers, stride, &weight, bPowerForwardRunSum, stride, minLength);
    
    vDSP_vadd(aPowerBackwardRunSum+1, stride, bPowerForwardRunSum+1, stride, combinedPowerOutput+outputLength-1, -stride, minLength-1);
    
    free(aPowerBackwardRunSum);
    free(bPowerForwardRunSum);
    
    
    free(aPowers);
    free(bPowers);
}
- (void)calcSlidingOverlapLength:(float *)a :(vDSP_Length)nA :(float *)b :(vDSP_Length)nB :(float *)overlapLengths
{
    // Sliding cross-correlation overlap window lengths.
    // Overlap lengths will be a trapezoidal shape, with a ramp up to a cap, then eventual ramp down.
    const vDSP_Stride stride = 1;
    vDSP_Length outputLength = [self calcOutputLength:nA :nB];
    vDSP_Length minLength = MIN(nA, nB);
    float minOverlap = 1;
    float overlapIncrement = 1;
    float maxOverlap = (float)minLength;

    vDSP_vramp(&minOverlap, &overlapIncrement, overlapLengths, stride, minLength);
    vDSP_vfill(&maxOverlap, overlapLengths + minLength, stride, outputLength - (2*minLength-1));
    vDSP_vramp(&minOverlap, &overlapIncrement, overlapLengths+outputLength-1, -stride, minLength-1);
    
//    // Old, inefficient implementation
//    float *rampUp = (float *)malloc(outputLength * sizeof(float));
//    vDSP_vramp(&minOverlap, &overlapIncrement, rampUp, stride, outputLength);
//
//    float *rampDown = (float *)malloc(outputLength * sizeof(float));
//    vDSP_vramp(&minOverlap, &overlapIncrement, rampDown + outputLength - 1, -stride, outputLength);
//
//    float *valueCap = (float *)malloc(outputLength * sizeof(float));
//    vDSP_vfill(&maxOverlap, valueCap, stride, outputLength);
//
//    // Minimize over all three vectors
//    vDSP_vmin(rampUp, stride, rampDown, stride, overlapLengths, stride, outputLength);
//    vDSP_vmin(valueCap, stride, overlapLengths, stride, overlapLengths, stride, outputLength);
//
//    free(rampUp);
//    free(rampDown);
//    free(valueCap);
}
// Calculates the length of the output vector for sliding differences, given the lengths of the input vectors.
- (vDSP_Length)calcOutputLength:(vDSP_Length)nA :(vDSP_Length)nB
{
    return nA + nB - 1;
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
    audio16bitToAudioFloat((SInt16 *)audio16bit->playingList->mBuffers[0].mData, audioFloat->stride, audioFloat->channel0, audioFloat->numFrames);
    audio16bitToAudioFloat((SInt16 *)audio16bit->playingList->mBuffers[1].mData, audioFloat->stride, audioFloat->channel1, audioFloat->numFrames);
}
float calcAvgPow(AudioDataFloat *audioFloat)
{
    float channel0meansquare = 0;
    float channel1meansquare = 0;
    vDSP_measqv(audioFloat->channel0, audioFloat->stride, &channel0meansquare, audioFloat->numFrames);
    vDSP_measqv(audioFloat->channel1, audioFloat->stride, &channel1meansquare, audioFloat->numFrames);
    return (channel0meansquare + channel1meansquare) / 2;
}

@end
