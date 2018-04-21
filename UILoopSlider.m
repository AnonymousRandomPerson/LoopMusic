//
//  UILoopSlider.m
//  LoopMusic
//
//  Created by Johann Gan on 4/9/18.
//  Copyright © 2018 Cheng Hann Gan. All rights reserved.
//

#import "UILoopSlider.h"

@implementation UILoopSlider

@synthesize boxHeightMultiplier, preLoopBoxHidden, loopBoxHidden, postLoopBoxHidden, preLoopBoxColor, loopBoxColor, postLoopBoxColor, loopingEnabled, looping, loopStart, loopEnd, timeBetweenUpdates, fastMode, intervalThreshold, previousValue, getCurrentTime;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    [self useDefaultParameters];
    [self useDefaultGraphics];
    getCurrentTime = ^float (void) { return 0; };   // Default block always returns 0 as the current time. Needs to be non-nil for proper functioning.
    
    [self setThumbImageFromFilename:@"thumb.png" :40]; // Necessary workaround for the weird tracking glitch with the slider thumb.
    
    return self;
}
- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // Form the boxes.
    if (!preLoopBox && self.maximumValue > 0)
    {
        // Initialize the boxes.
        preLoopBox = [[UIView alloc] initWithFrame:[self createFrame:self.minimumValue :loopStart]];
        postLoopBox = [[UIView alloc] initWithFrame:[self createFrame:loopEnd :self.maximumValue]];
        loopBox = [[UIView alloc] initWithFrame:[self createFrame:loopStart :loopEnd]];
        
        // To enable touches to pass through
        preLoopBox.userInteractionEnabled = false;
        loopBox.userInteractionEnabled = false;
        postLoopBox.userInteractionEnabled = false;
        
        // Aesthetics
        preLoopBox.layer.cornerRadius = 3;
        loopBox.layer.cornerRadius = 3;
        postLoopBox.layer.cornerRadius = 3;
        
        [self insertSubview:preLoopBox belowSubview:self.subviews.lastObject];
        [self insertSubview:postLoopBox belowSubview:self.subviews.lastObject];
        [self insertSubview:loopBox belowSubview:self.subviews.lastObject];
        
        [self refreshBoxes];
    }
}

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
}
- (void)useDefaultGraphics
{
    boxHeightMultiplier = 1.1;
    
    // Default to hidden
    [self unhighlightLoopRegion];
    [self unhighlightNonLoopRegion];
    
    // Default colors
    float alpha = 0.25;
    self.preLoopBoxColor = [[UIColor redColor] colorWithAlphaComponent:alpha];
    self.postLoopBoxColor = [[UIColor blueColor] colorWithAlphaComponent:alpha];
    self.loopBoxColor = [[UIColor greenColor] colorWithAlphaComponent:alpha];
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
    [self refreshBoxes]; // Adjust to the new height.
}

/*!
 * Creates a rectangle over a given region.
 * @param x0 The region start.
 * @param x1 The region end.
 * @return The rectangle over the region.
 */
- (CGRect)createFrame:(CGFloat)x0 :(CGFloat)x1
{
    CGRect trackRect = [self trackRectForBounds:self.bounds];
    CGRect thumbRect = [self thumbRectForBounds:self.bounds trackRect:trackRect value:self.value];
    CGFloat sliderHeight = thumbRect.size.width;
    CGFloat y0 = thumbRect.origin.y - (boxHeightMultiplier - 1)/2 * sliderHeight;
    return CGRectMake(x0, y0, x1-x0, boxHeightMultiplier*sliderHeight);
}

/*!
 * Gets the x-coordinate of the lower bound of the slider.
 * @return The x-coordinate of the lower bound.
 */
- (CGFloat)lowerBound
{
    return self.bounds.origin.x;
}
/*!
 * Gets the x-coordinate of the upper bound of the slider.
 * @return The x-coordinate of the upper bound.
 */
- (CGFloat)upperBound
{
    return self.bounds.origin.x + self.bounds.size.width;
}
/*!
 * Gets the width of the slider thumb.
 * @return The slider thumb width.
 */
- (CGFloat)thumbWidth
{
    double extraWidth = 13 / 3.0;   // Intrinsic to the default thumb image ("thumb.png") because of the transparent padding. There are ~6-7 pixels on either side in the original image, and the image is scaled from 120px to 40px.
    return self.currentThumbImage.size.width - extraWidth;
}
/*!
 * Gets the x-coordinate corresponding to a given time on the slider.
 * @param time The slider time value.
 * @return The x-coordinate corresponding to the time value.
 */
- (CGFloat)coordinateFromTime:(double)time
{
    CGRect trackRect = [self trackRectForBounds:self.bounds];
    return trackRect.origin.x + [self thumbWidth]/2 + (trackRect.size.width - [self thumbWidth]) * time / self.maximumValue;
}

/*!
 * Refreshes the state of the loop boxes.
 */
- (void)refreshBoxes
{
    // Refresh the hidden states
    preLoopBox.hidden = preLoopBoxHidden;
    loopBox.hidden = loopBoxHidden;
    postLoopBox.hidden = postLoopBoxHidden;
    
    // Refresh the colors
    preLoopBox.backgroundColor = preLoopBoxColor;
    loopBox.backgroundColor = loopBoxColor;
    postLoopBox.backgroundColor = postLoopBoxColor;
    
    // Attempts to completely encapsulate the thumb in the highlighted region, rather than gauging by the thumb's center.
    CGFloat loopStartCoord = [self coordinateFromTime:loopStart] - [self thumbWidth]/2;
    CGFloat loopEndCoord = [self coordinateFromTime:loopEnd] + [self thumbWidth]/2;

    [UIView animateWithDuration:0.1 animations:^{
        preLoopBox.frame = [self createFrame:[self lowerBound] :loopStartCoord];
        loopBox.frame = [self createFrame:loopStartCoord :loopEndCoord];
        postLoopBox.frame = [self createFrame:loopEndCoord :[self upperBound]];
    }];
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
    self.loopingEnabled = otherSlider.loopingEnabled;
    self.timeBetweenUpdates = otherSlider.timeBetweenUpdates;
    self.getCurrentTime = otherSlider.getCurrentTime;
    
    self.minimumValue = otherSlider.minimumValue;
    self.maximumValue = otherSlider.maximumValue;
    self.loopStart = otherSlider.loopStart;
    self.loopEnd = otherSlider.loopEnd;
    self.value = otherSlider.value;
    self.previousValue = otherSlider.previousValue;
    
    self.looping = otherSlider.looping;
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

- (void)highlightPreLoopRegion
{
    preLoopBoxHidden = false;
    [self refreshBoxes];
}
- (void)highlightLoopRegion
{
    loopBoxHidden = false;
    [self refreshBoxes];
}
- (void)highlightPostLoopRegion
{
    postLoopBoxHidden = false;
    [self refreshBoxes];
}
- (void)highlightNonLoopRegion
{
    [self highlightPreLoopRegion];
    [self highlightPostLoopRegion];
}

- (void)unhighlightPreLoopRegion
{
    preLoopBoxHidden = true;
    [self refreshBoxes];
}
- (void)unhighlightLoopRegion
{
    loopBoxHidden = true;
    [self refreshBoxes];
}
- (void)unhighlightPostLoopRegion
{
    postLoopBoxHidden = true;
    [self refreshBoxes];
}
- (void)unhighlightNonLoopRegion
{
    [self unhighlightPreLoopRegion];
    [self unhighlightPostLoopRegion];
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

- (void)setMinimumValue:(float)minimumValue
{
    [super setMinimumValue:minimumValue];
    [self refreshBoxes];
}

- (void)setMaximumValue:(float)maximumValue
{
    [super setMaximumValue:maximumValue];
    [self refreshBoxes];
}

- (void)setLoopStart:(double)loopStart
{
    self->loopStart = MAX(0, loopStart);
    looping = false; // Need to re-evaluate after the change
    [self refreshBoxes];
}

- (void)setLoopEnd:(double)loopEnd
{
    self->loopEnd = MIN(self.maximumValue, loopEnd);
    [self refreshBoxes];
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
        self.value = MAX(self.minimumValue, MIN(time, self.maximumValue));
    
    previousValue = self.value;
}
- (void)forceSetTime:(double)time
{
    self.value = MAX(self.minimumValue, MIN(time, self.maximumValue));
    
    if (self.value < loopStart || self.value > loopEnd)
        looping = false;
    else
        looping = true;
    
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
