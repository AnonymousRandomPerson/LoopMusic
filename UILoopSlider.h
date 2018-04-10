//
//  UILoopSlider.h
//  LoopMusic
//
//  Created by Johann Gan on 4/9/18.
//  Copyright © 2018 Cheng Hann Gan. All rights reserved.
//

// Playback slider functionality for looped tracks.
#import <UIKit/UIKit.h>

@interface UILoopSlider : UISlider

/// Flag for whether track looping is enabled. Possibly use for modifying display and how the slider value gets set.
@property (nonatomic) bool loopingEnabled;
/// Flag for when the current playback has passed the introduction and reached the loop region.
@property (nonatomic) bool looping;
/// Time (in seconds) where the loop starts.
@property (nonatomic) double loopStart;
/// Time (in seconds) where the loop ends.
@property (nonatomic) double loopEnd;
/// Number of seconds between slider value updates.
@property (nonatomic) double timeBetweenUpdates;
/// The most recently set value that went through bounds checking (setTime or refreshTime). Useful for checking if the value has actually changed, since the valueChanged event seems to fire on touchUp even when the value didn't actually change. This is to get the "snap to the current playing time" feature if the user holds down the slider, lets it play for a bit, and then let's go without moving.
@property (nonatomic) float previousValue;

/*!
 * Sets internal parameters to their defaults.
 */
- (void)useDefaultParameters;

/*!
 * Sets a new loop start point.
 */
- (void)setLoopStart:(double)loopStart;

/*!
 * Sets the slider time with bounds checking (loop region) if necessary.
 * @param time The time to set the slider to.
 */
- (void)setTime:(double)time;

/*!
 * Refreshes the slider time with the current slider value (possibly changed due to user interaction)
 */
- (void)refreshTime;

/*!
 * For resetting internal values when playback is stopped.
 */
- (void)stop;

/*!
 * Sets up for a new track.
 @param trackEnd The end time of the entire track.
 @param loopStart The loop start point of the new track.
 @param loopEnd The loop end point of the new track.
 */
- (void)setupNewTrack:(double)trackEnd :(double)loopStart :(double)loopEnd;

@end
