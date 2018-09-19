//
//  SettingsStore.h
//  LoopMusic
//
//  Created by Cheng Hann Gan on 9/17/18.
//  Copyright © 2018 Cheng Hann Gan. All rights reserved.
//

#ifndef SettingsStore_h
#define SettingsStore_h

/// Stores and loads settings for the app.
@interface SettingsStore : NSObject
{
    /// The base amount of time to play a track before shuffling.
    double _timeShuffle;
    /// The number of times to repeat a track before shuffling.
    NSInteger _repeatsShuffle;
    /// The setting for how to shuffle tracks.
    NSUInteger _shuffleSetting;
    /// The amount of time to fade out a track before shuffling.
    double _fadeSetting;
    /// The index of the currently selected playlist.
    NSInteger _playlistIndex;
    /// The current master volume of the app, encompassing all tracks.
    float _masterVolume;
}

/// The base amount of time to play a track before shuffling.
@property(nonatomic) double timeShuffle;
/// The number of times to repeat a track before shuffling.
@property(nonatomic) NSInteger repeatsShuffle;
/// The setting for how to shuffle tracks.
@property(nonatomic) NSUInteger shuffleSetting;
/// The amount of time to fade out a track before shuffling.
@property(nonatomic) double fadeSetting;
/// The index of the currently selected playlist.
@property(nonatomic) NSInteger playlistIndex;
/// The current master volume of the app, encompassing all tracks.
@property(nonatomic) float masterVolume;

/*!
 * Gets the singleton instance of the object.
 * @return The singleton instance of the object.
 */
+ (SettingsStore*)instance;

/*!
 * Loads settings for the app from a file.
 */
- (void)loadSettings;

/*!
 * Saves settings for the app to a file.
 */
- (void)saveSettings;

@end

#endif /* SettingsStore_h */
