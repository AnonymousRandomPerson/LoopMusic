//
//  UILoopSlider.h
//  LoopMusic
//
//  Created by Johann Gan on 4/9/18.
//  Copyright © 2018 Cheng Hann Gan. All rights reserved.
//

// Playback slider functionality for looped tracks.
#import <UIKit/UIKit.h>
#import "AudioPlayer.h"

@interface UILoopSlider : UISlider
{
    /// Internal refresh timer.
    NSTimer *updateTimer;
    
    /// Box for the pre-loop region.
    UIView *preLoopBox;
    /// Box for the loop region.
    UIView *loopBox;
    /// Box for the post-loop region.
    UIView *postLoopBox;
}

/// The height of the boxes over the three loop regions, as a multiple of the slider height.
@property (nonatomic) double boxHeightMultiplier;
/// Whether the preLoopBox is hidden. Needed because the actual pointers are nil for a while after viewDidLoad gets called in the main screen.
@property (nonatomic) bool preLoopBoxHidden;
/// Whether the loopBox is hidden.
@property (nonatomic) bool loopBoxHidden;
/// Whether the postLoopBox is hidden.
@property (nonatomic) bool postLoopBoxHidden;
/// Color of preLoopBox.
@property (nonatomic) UIColor *preLoopBoxColor;
/// Color of loopBox.
@property (nonatomic) UIColor *loopBoxColor;
/// Color of postLoopBox.
@property (nonatomic) UIColor *postLoopBoxColor;

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
/// Flag for whether the refresh timer is in fast mode in preparation for the loop end.
@property (nonatomic) bool fastMode;
/// Internal parameter for how many <timeBetweenUpdate>s there can be before the end point before switching to fast mode.
@property (nonatomic) double intervalThreshold;
/// Block that returns the current time to update to.
@property (nonatomic) float (^getCurrentTime) (void);

/*!
 * Sets internal parameters to their defaults.
 */
- (void)useDefaultParameters;
/*!
 * Sets graphical parameters to their defaults.
 */
- (void)useDefaultGraphics;

/*!
 * Sets the thumb image of the slider. Necessary workaround to prevent the slider "jumping" upon valueChanged, due to some weird glitch with the slider.
 * @param imageName The name of the image file.
 * @param sideLength The side length the image should be resized to before setting it as the slider image.
 */
- (void)setThumbImageFromFilename:(NSString *)imageName :(NSInteger)sideLength;

/*!
 * Copies the settings from one play slider to another.
 * @param otherSlider The slider to copy settings from.
 */
- (void)copySettingsFromSlider:(UILoopSlider *)otherSlider;

/*!
 * Activates the slider update timer in normal (slow) mode.
 */
- (void)activateUpdateTimer;
/*!
 * Stops the playback slider update timer.
 */
- (void)stopUpdateTimer;

/*!
 * Draws a box over the pre-loop region.
 */
- (void)highlightPreLoopRegion;
/*!
 * Draws a box over the loop region.
 */
- (void)highlightLoopRegion;
/*!
 * Draws a box over the post-loop region.
 */
- (void)highlightPostLoopRegion;
/*!
 * Draws a box over the pre- and post-loop regions.
 */
- (void)highlightNonLoopRegion;

/*!
 * Removes the pre-loop region box.
 */
- (void)unhighlightPreLoopRegion;
/*!
 * Removes the loop region box.
 */
- (void)unhighlightLoopRegion;
/*!
 * Removes the post-loop region box.
 */
- (void)unhighlightPostLoopRegion;
/*!
 * Removes the pre- and post-loop boxes.
 */
- (void)unhighlightNonLoopRegion;

/*!
 * Updates an AudioPlayer based on the current slider value. Should be called for a valueChanged event.
 * @player The AudioPlayer to update (mutate properties).
 */
- (void)updateAudioPlayer:(AudioPlayer *)player;

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
 * Sets the slider time with bounds checking (track length), disregarding loop region checking.
 * @param time The time to set the slider to.
 */
- (void)forceSetTime:(double)time;

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
