//
//  LoopFinderAuto+analysis.h
//  LoopMusic
//
//  Created by Johann Gan on 2/18/18.
//  Copyright © 2018 Cheng Hann Gan. All rights reserved.
//

#import "LoopFinderAuto.h"

// TO IMPLEMENT
/// Methods for using signal differencing results and signal spectra to find loop point candidates and relevant metrics for ranking.
@interface LoopFinderAuto (analysis)

/*!
 * Selects the (LoopFinderAuto.nBestDurations) initial lag candidates, suppressing candidates that are too similar (based on LoopFinderAuto.minTimeDiff).
 * @param mse Vector of sliding MSE values to pick from. Assumes the first lag value is 0.
 * @param nMSE MSE vector size.
 * @return Output array of candidate lag values. Will have at most (LoopFinderAuto.nBestDurations) elements.
 */
- (NSArray *)selectInitialCandidatesAuto:(float *)mse :(UInt32)nMSE;

@end
