//
//  AudioTimer.h
//  LoopMusic
//
//  Created by Cheng Hann Gan on 5/9/16.
//  Copyright © 2016 Cheng Hann Gan. All rights reserved.
//

#ifndef AudioTimer_h
#define AudioTimer_h

#import "AudioPlayer.h"

@interface AudioTimer : NSObject
{
    /// Scheduler for running the timer.
    AEBlockScheduler *scheduler;
    /// The audio player that plays tracks.
    AudioPlayer *audioPlayer;
}

/*!
 * Initializes the audio timer.
 * @param audioPlayer The audio player that the timer is attached to.
 * @return The new audio player.
 */
- (id)initWithPlayer:(AudioPlayer *)audioPlayer;

/*!
 * Cancels the currently scheduled block in the timer.
 * @return
 */
- (void)cancelBlock;

/*!
 * Changes the scheduled block in the timer.
 * @param time The time offset (in seconds) that the block will be executed at.
 * @param block The block to execute when the timer finishes.
 * @param beforeTime The time on the audio player before this function was called.
 * @return
 */
- (void)changeBlock:(double)time :(AEBlockSchedulerBlock)audioBlock :(AEBlockSchedulerBlock)mainBlock :(NSTimeInterval) beforeTime;

@end

#endif /* AudioTimer_h */
