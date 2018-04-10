//
//  UILoopSlider.m
//  LoopMusic
//
//  Created by Johann Gan on 4/9/18.
//  Copyright © 2018 Cheng Hann Gan. All rights reserved.
//

#import "UILoopSlider.h"

@implementation UILoopSlider

@synthesize loopingEnabled, looping, loopStart, loopEnd, timeBetweenUpdates, previousValue;

- (void)useDefaultParameters
{
    // Default values
    self.minimumValue = 0;
    loopingEnabled = true;
    looping = false;
    timeBetweenUpdates = 0.25;
    previousValue = -1;
}

- (void)setLoopStart:(double)loopStart
{
    self->loopStart = loopStart;
    looping = false; // Need to re-evaluate after the change
}

- (void)setTime:(double)time
{
    // Start looping.
    if (loopingEnabled && !looping && time > loopStart)
        looping = true;
    
    // Handle the wrap-around if needed.
    if (loopingEnabled && looping)
        self.value = time >= loopStart ? loopStart + fmod(time-loopStart, loopEnd-loopStart) : loopEnd - fmod(loopStart-time, loopEnd-loopStart);
    else
        self.value = MIN(time, self.maximumValue);
    
    previousValue = self.value;
}

- (void)refreshTime
{
    [self setTime:self.value];
}

- (void)stop
{
    self.value = 0;
    looping = false;
}

- (void)setupNewTrack:(double)trackEnd :(double)loopStart :(double)loopEnd
{
    [self stop];
    self.maximumValue = trackEnd;
    self.loopStart = loopStart;
    self.loopEnd = loopEnd;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
