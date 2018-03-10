//
//  LoopFinderAuto+analysis.m
//  LoopMusic
//
//  Created by Johann Gan on 2/18/18.
//  Copyright © 2018 Cheng Hann Gan. All rights reserved.
//

#import "LoopFinderAuto+analysis.h"

@implementation LoopFinderAuto (analysis)

// For qsort, sorting indices by array value
typedef struct float_enumeration
{
    UInt32 index;
    float value;
} float_enumeration;

// For qsort
int compare(const void* a, const void* b)
{
    float float_a = (*((float_enumeration *)a)).value;
    float float_b = (*((float_enumeration *)b)).value;
    
    if (float_a == float_b)
        return 0;
    else if (float_a < float_b)
        return -1;
    else
        return 1;
}

// TEST THIS FUNCTION
- (NSArray *)selectInitialCandidatesAuto:(float *)mse :(UInt32)nMSE
{
    float_enumeration *sortedMSE = malloc(nMSE * sizeof(float_enumeration));
    for (UInt32 i = 0; i < nMSE; i++)
    {
        (*(sortedMSE + i)).index = i;
        (*(sortedMSE + i)).value = *(mse + i);
    }
    qsort(sortedMSE, nMSE, sizeof(float_enumeration), compare);
    
    NSMutableArray *lags = [[NSMutableArray alloc] init];
    for (UInt32 i = 0; i < nMSE; i++)
    {
        // Non-maximum suppression
        for (int j = 0; j < [lags count]; j++)
        {
            if (labs((*(sortedMSE + i)).index - [lags[j] integerValue]) < self.minTimeDiff*FRAMERATE)
                continue;
        }
        
        [lags addObject:[NSNumber numberWithUnsignedInteger:i]];
    }
    free(sortedMSE);
    return [lags copy];
}

@end
