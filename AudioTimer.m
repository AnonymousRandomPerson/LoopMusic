//
//  AudioTimer.m
//  LoopMusic
//
//  Created by Cheng Hann Gan on 5/9/16.
//  Copyright © 2016 Cheng Hann Gan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AudioTimer.h"

const static NSString *BLOCKIDENTIFIER = @"loop";

@implementation AudioTimer

- (id)initWithPlayer:(AudioPlayer *)newAudioPlayer
{
    self = [super init];
    
    audioPlayer = newAudioPlayer;
    /// The audio controller inside the audio player.
    AEAudioController *audioController = newAudioPlayer.audioController;
    scheduler = [[AEBlockScheduler alloc] initWithAudioController:audioController];
    [audioController addTimingReceiver:scheduler];
    return self;
}

- (void)cancelBlock
{
    [scheduler cancelScheduleWithIdentifier:BLOCKIDENTIFIER];
}

- (void)changeBlock:(double)time :(AEBlockSchedulerBlock)audioBlock :(AEBlockSchedulerBlock)mainBlock :(NSTimeInterval) beforeTime
{
    [self cancelBlock];
    if (time < 0)
    {
        time = 0;
    }
    
    time = time - audioPlayer.currentTime + beforeTime;
    uint64_t hostTime = [AEBlockScheduler now] + [AEBlockScheduler hostTicksFromSeconds:time];
    [scheduler scheduleBlock:audioBlock
                      atTime:hostTime
               timingContext:AEAudioTimingContextOutput
                  identifier:BLOCKIDENTIFIER
     mainThreadResponseBlock:mainBlock];
}

@end