//
//  LoopFinderAuto+synthesis.m
//  LoopMusic
//
//  Created by Johann Gan on 3/13/18.
//  Copyright © 2018 Cheng Hann Gan. All rights reserved.
//

#import "LoopFinderAuto+synthesis.h"
#import "LoopFinderAuto+spectra.h"
#import "LoopFinderAuto+analysis.h"

@implementation LoopFinderAuto (synthesis)

- (NSArray *)calcConfidence:(NSArray *)losses :(float)regularization
{
    // Handle 1-element cases (to avoid nan if the number is too big)
    if ([losses count] == 1)
        return @[@1];
    
    bool zeroDenom = false; // Flag for zero-division
    float sumInvs = 0;  // Sum of inverses
    
    NSMutableArray *workArray = [NSMutableArray arrayWithArray:losses];
    for (NSUInteger i = 0; i < [workArray count]; i++)
    {
        float denom = expf([workArray[i] floatValue])-1 + expf(regularization)-1;
        if (denom == 0)
        {
            zeroDenom = true;
            break;
        }
        
        float inv = 1.0/denom;
        sumInvs += inv;
        workArray[i] = [NSNumber numberWithFloat:inv];
    }
    
    // Handle the zero-division case.
    if (zeroDenom)
    {
        for (NSUInteger i = 0; i < [workArray count]; i++)
        {
            float denom = expf([losses[i] floatValue])-1 + expf(regularization)-1;
            
            float value = denom == 0 ? 1 : 0;
            workArray[i] = [NSNumber numberWithFloat:value];
        }
    }
    else    // The normal case
    {
        for (NSUInteger i = 0; i < [workArray count]; i++)
        {
            workArray[i] = [NSNumber numberWithFloat:[workArray[i] floatValue]/sumInvs];
        }
    }
    
    return [workArray copy];
}

- (NSArray *)calcConfidence:(NSArray *)losses
{
    return [self calcConfidence:losses :self->confidenceRegularization];
}


- (NSDictionary *)analyzeLagValue:(AudioDataFloat *)audio :(UInt32)lag
{
    DiffSpectrogramInfo *specDiff = malloc(sizeof(DiffSpectrogramInfo));
    [self diffSpectrogram:audio :lag :specDiff];
    
    NSDictionary *loopRegion = [self inferLoopRegion:specDiff->mses :specDiff->nWindows :specDiff->effectiveWindowDurations];
    
    UInt32 regionStartWindow = (UInt32)[loopRegion[@"start"] unsignedIntegerValue];
    UInt32 regionEndWindow = (UInt32)[loopRegion[@"end"] unsignedIntegerValue];
    float regionCutoff = [loopRegion[@"cutoff"] floatValue];
    float matchLength = [self calcMatchLength:specDiff->mses :specDiff->nWindows :specDiff->effectiveWindowDurations :regionCutoff];
    float mismatchLength = [self calcMismatchLength:specDiff->mses :specDiff->nWindows :regionStartWindow :regionEndWindow :specDiff->effectiveWindowDurations :regionCutoff];
    
    UInt32 regionStartSample = *(specDiff->startSamples + regionStartWindow);
    UInt32 regionEndSample = *(specDiff->startSamples + regionEndWindow) + *(specDiff->windowSizes + regionEndWindow) - 1;
    lag = [self refineLag:audio :lag :regionStartSample :regionEndSample];
    
    NSDictionary *pairs = [self findEndpointPairsSpectra:audio :lag :specDiff->mses :specDiff->nWindows :specDiff->startSamples :specDiff->windowSizes :regionStartWindow :regionEndWindow];
    
    float specMSE = [self biasedMeanSpectrumMSE:specDiff->mses :regionStartWindow :regionEndWindow];
    
    freeDiffSpectrogramInfo(specDiff);
    free(specDiff);
    
    return @{@"startSamples": pairs[@"starts"], @"refinedLags": pairs[@"lags"], @"sampleDiffs": pairs[@"sampleDiffs"], @"spectrumMSE": [NSNumber numberWithFloat:specMSE], @"matchLength": [NSNumber numberWithFloat:matchLength], @"mismatchLength": [NSNumber numberWithFloat:mismatchLength]};
}

@end
