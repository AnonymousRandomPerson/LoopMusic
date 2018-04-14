//
//  UILoopSlider.m
//  LoopMusic
//
//  Created by Johann Gan on 4/9/18.
//  Copyright © 2018 Cheng Hann Gan. All rights reserved.
//

#import "UILoopSlider.h"

@implementation UILoopSlider

@synthesize loopingEnabled, looping, loopStart, loopEnd, timeBetweenUpdates, fastMode, intervalThreshold, previousValue, getCurrentTime;

- (void)useDefaultParameters
{
    // Default values
    self.minimumValue = 0;
    loopingEnabled = true;
    looping = false;
    timeBetweenUpdates = 0.25;
    intervalThreshold = 1.5;
    fastMode = false;
    previousValue = -1;
    [self setThumbImageFromFilename:@"thumb.png" :40]; // Necessary workaround for the weird tracking glitch with the slider thumb.
    getCurrentTime = ^float (void) { return 0; };   // Default block always returns 0 as the current time. Needs to be set for proper functioning.
}

- (void)setThumbImageFromFilename:(NSString *)imageName :(NSInteger)sideLength
{
    CGSize size = CGSizeMake(sideLength, sideLength);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    [[UIImage imageNamed:imageName] drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [self setThumbImage:image forState:UIControlStateNormal];
    [self setThumbImage:image forState:UIControlStateSelected];
    [self setThumbImage:image forState:UIControlStateHighlighted];
}

/*!
 * Refreshes the play slider.
 * @param timer The timer that invoked this function.
 */
- (void)refreshSlider:(NSTimer *)timer
{
    [self setTime:self.getCurrentTime()];
    
    if (!fastMode && loopEnd - self.getCurrentTime() <= intervalThreshold*timeBetweenUpdates)
    {
        [self switchToFastTimerMode];
//        NSLog(@"Activating fast mode.");
    }
    else if (fastMode && loopEnd - self.getCurrentTime() > intervalThreshold*timeBetweenUpdates)
    {
        [self activateUpdateTimer];
//        NSLog(@"Deactivating fast mode.");
    }
}

- (void)copySettingsFromSlider:(UILoopSlider *)otherSlider
{
    loopingEnabled = otherSlider.loopingEnabled;
    timeBetweenUpdates = otherSlider.timeBetweenUpdates;
    getCurrentTime = otherSlider.getCurrentTime;
    
    self.minimumValue = otherSlider.minimumValue;
    self.maximumValue = otherSlider.maximumValue;
    loopStart = otherSlider.loopStart;
    loopEnd = otherSlider.loopEnd;
    self.value = otherSlider.value;
    previousValue = otherSlider.previousValue;
    
    looping = otherSlider.looping;
}

- (void)activateUpdateTimer
{
    [self stopUpdateTimer];
    fastMode = false;
    updateTimer = [NSTimer scheduledTimerWithTimeInterval:timeBetweenUpdates
                                                   target:self
                                                 selector:@selector(refreshSlider:)
                                                 userInfo:nil
                                                  repeats:YES];
}

/*!
 * Switches the update timer to a much finer resolution. For when the loop point is near.
 */
- (void)switchToFastTimerMode
{
    double fastUpdateInterval = 1e-3;   // Millisecond resolution
    [self stopUpdateTimer];
    fastMode = true;
    updateTimer = [NSTimer scheduledTimerWithTimeInterval:fastUpdateInterval
                                                   target:self
                                                 selector:@selector(refreshSlider:)
                                                 userInfo:nil
                                                  repeats:YES];
}

- (void)stopUpdateTimer
{
    if (updateTimer)
    {
        [updateTimer invalidate];
        updateTimer = nil;
    }
}

- (void)updateAudioPlayer:(AudioPlayer *)player
{
    // Check if the value has actually changed, since the valueChanged event seems to fire on touchUp even when the value didn't actually change. This is to get the "snap to the current playing time" feature if the user holds down the slider, lets it play for a bit, and then let's go without moving.
    if (self.value != self.previousValue)
    {
        [self refreshTime];
        player.currentTime = self.value;
        player.pauseTime = self.value;  // Won't have any effect if not paused, since pauseTime gets reset upon pausing anyway.
    }
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
