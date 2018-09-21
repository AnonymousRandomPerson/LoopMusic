//
//  SettingsStore.m
//  LoopMusic
//
//  Created by Cheng Hann Gan on 9/17/18.
//  Copyright © 2018 Cheng Hann Gan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SettingsStore.h"

/// The base directory where settings files are stored.
static NSString *DOCUMENTS_DIR = @"Documents";
/// The name of the plist where settings are stored.
static NSString *SETTINGS_PLIST = @"Settings.plist";

/// Plist key for timeShuffle.
static NSString *KEY_TIME_SHUFFLE = @"timeShuffle";
/// Plist key for minTimeShuffle.
static NSString *KEY_MIN_TIME_SHUFFLE = @"minTimeShuffle";
/// Plist key for maxTimeShuffle.
static NSString *KEY_MAX_TIME_SHUFFLE = @"maxTimeShuffle";
/// Plist key for repeatsShuffle.
static NSString *KEY_REPEATS_SHUFFLE = @"repeatsShuffle";
/// Plist key for minRepeatsShuffle.
static NSString *KEY_MIN_REPEATS_SHUFFLE = @"minRepeatsShuffle";
/// Plist key for maxRepeatsShuffle.
static NSString *KEY_MAX_REPEATS_SHUFFLE = @"maxRepeatsShuffle";
/// Plist key for timeShuffleVariance.
static NSString *KEY_TIME_SHUFFLE_VARIANCE = @"timeShuffleVariance";
/// Plist key for repeatsShuffleVariance.
static NSString *KEY_REPEATS_SHUFFLE_VARIANCE = @"repeatsShuffleVariance";
/// Plist key for shuffleSetting.
static NSString *KEY_SHUFFLE_SETTING = @"shuffleSetting";

/// Plist key for fadeSetting.
static NSString *KEY_FADE_SETTING = @"fadeSetting";
/// Plist key for playlistIndex.
static NSString *KEY_PLAYLIST_INDEX = @"playlistIndex";
/// Plist key for masterVolume.
static NSString *KEY_MASTER_VOLUME = @"masterVolume";

/// The singleton instance of the object.
static SettingsStore *_instance;

@implementation SettingsStore

@synthesize timeShuffle, minTimeShuffle, maxTimeShuffle, repeatsShuffle, minRepeatsShuffle, maxRepeatsShuffle, timeShuffleVariance, repeatsShuffleVariance, shuffleSetting, fadeSetting, playlistIndex, masterVolume;

+ (SettingsStore*)instance {
    return _instance;
}

+ (void)initialize
{
    if (!_instance)
    {
        _instance = [[SettingsStore alloc] init];
        [_instance loadSettings];
    }
}

- (id)init {
    return _instance ? _instance : [super init];
}

- (void)loadSettings
{
    NSString *documentsFilePath = [NSHomeDirectory() stringByAppendingPathComponent:DOCUMENTS_DIR];
    NSString *settingsFilePath = [documentsFilePath stringByAppendingPathComponent:SETTINGS_PLIST];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // Default values.
    shuffleSetting = 1;
    timeShuffle = 3.5;
    repeatsShuffle = 3;
    fadeSetting = 2;
    playlistIndex = 0;
    masterVolume = 0;
    timeShuffleVariance = 0.5;
    repeatsShuffleVariance = 0;
    minTimeShuffle = 0;
    maxTimeShuffle = 0;
    minRepeatsShuffle = 0;
    maxRepeatsShuffle = 0;
    
    if ([fileManager fileExistsAtPath:settingsFilePath])
    {
        /// The contents of the settings file.
        NSDictionary *settingsDict = [[NSDictionary alloc] initWithContentsOfFile:settingsFilePath];
        fadeSetting = [[settingsDict objectForKey:KEY_FADE_SETTING] doubleValue];
        masterVolume = [[settingsDict objectForKey:KEY_MASTER_VOLUME] floatValue];
        playlistIndex = [[settingsDict objectForKey:KEY_PLAYLIST_INDEX] integerValue];
        repeatsShuffle = [[settingsDict objectForKey:KEY_REPEATS_SHUFFLE] doubleValue];
        shuffleSetting = [[settingsDict objectForKey:KEY_SHUFFLE_SETTING] integerValue];
        timeShuffle = [[settingsDict objectForKey:KEY_TIME_SHUFFLE] doubleValue];
        minTimeShuffle = [[settingsDict objectForKey:KEY_MIN_TIME_SHUFFLE] doubleValue];
        maxTimeShuffle = [[settingsDict objectForKey:KEY_MAX_TIME_SHUFFLE] doubleValue];
        minRepeatsShuffle = [[settingsDict objectForKey:KEY_MIN_REPEATS_SHUFFLE] doubleValue];
        maxRepeatsShuffle = [[settingsDict objectForKey:KEY_MAX_REPEATS_SHUFFLE] doubleValue];
        repeatsShuffleVariance = [[settingsDict objectForKey:KEY_REPEATS_SHUFFLE_VARIANCE] doubleValue];
        
        NSString* timeShuffleVarianceValue = [settingsDict objectForKey:KEY_TIME_SHUFFLE_VARIANCE];
        if (timeShuffleVarianceValue != nil)
        {
            timeShuffleVariance = [timeShuffleVarianceValue doubleValue];
        }
    }
    else
    {
        /// If needed, convert the old plain text settings format.
        NSString *plainTextFilePath = [documentsFilePath stringByAppendingPathComponent:@"Settings.txt"];
        NSError *error = nil;
        NSString *plainTextSettings = [NSString stringWithContentsOfFile:plainTextFilePath encoding:NSUTF8StringEncoding error:&error];
        if (error)
        {
            NSLog(@"Error loading plain text settings file: %@", error);
        }
        if (plainTextSettings)
        {
            /// The contents of the settings file, split into individual settings.
            NSArray *splitSettings = [plainTextSettings componentsSeparatedByString:@","];
            shuffleSetting = [splitSettings[0] integerValue];
            timeShuffle = [splitSettings[1] doubleValue];
            repeatsShuffle = [splitSettings[2] doubleValue];
            fadeSetting = splitSettings.count > 3 ? [splitSettings[3] doubleValue] : fadeSetting;
            playlistIndex = splitSettings.count > 4 ? [splitSettings[4] integerValue] : playlistIndex;
            masterVolume = splitSettings.count > 5 ? [splitSettings[5] floatValue] : masterVolume;
        }
        [self saveSettings];
        
        error = nil;
        [fileManager removeItemAtPath:plainTextFilePath error:&error];
        if (error)
        {
            NSLog(@"Error removing plain text settings file: %@", error);
        }
    }
}

- (void)saveSettings
{
    NSString *settingsFilePath = [[NSHomeDirectory() stringByAppendingPathComponent:DOCUMENTS_DIR] stringByAppendingPathComponent:SETTINGS_PLIST];
    NSMutableDictionary *saveDict = [NSMutableDictionary dictionaryWithCapacity:6];
    [saveDict setValue:[NSString stringWithFormat:@"%@", @(fadeSetting)] forKey:KEY_FADE_SETTING];
    [saveDict setValue:[NSString stringWithFormat:@"%@", @(masterVolume)] forKey:KEY_MASTER_VOLUME];
    [saveDict setValue:[NSString stringWithFormat:@"%@", @(playlistIndex)] forKey:KEY_PLAYLIST_INDEX];
    [saveDict setValue:[NSString stringWithFormat:@"%@", @(repeatsShuffle)] forKey:KEY_REPEATS_SHUFFLE];
    [saveDict setValue:[NSString stringWithFormat:@"%@", @(shuffleSetting)] forKey:KEY_SHUFFLE_SETTING];
    [saveDict setValue:[NSString stringWithFormat:@"%@", @(timeShuffle)] forKey:KEY_TIME_SHUFFLE];
    [saveDict setValue:[NSString stringWithFormat:@"%@", @(timeShuffleVariance)] forKey:KEY_TIME_SHUFFLE_VARIANCE];
    [saveDict setValue:[NSString stringWithFormat:@"%@", @(repeatsShuffleVariance)] forKey:KEY_REPEATS_SHUFFLE_VARIANCE];
    [saveDict setValue:[NSString stringWithFormat:@"%@", @(minTimeShuffle)] forKey:KEY_MIN_TIME_SHUFFLE];
    [saveDict setValue:[NSString stringWithFormat:@"%@", @(maxTimeShuffle)] forKey:KEY_MAX_TIME_SHUFFLE];
    [saveDict setValue:[NSString stringWithFormat:@"%@", @(minRepeatsShuffle)] forKey:KEY_MIN_REPEATS_SHUFFLE];
    [saveDict setValue:[NSString stringWithFormat:@"%@", @(maxRepeatsShuffle)] forKey:KEY_MAX_REPEATS_SHUFFLE];
    
    NSError *error = nil;
    NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:saveDict
                                                                   format:NSPropertyListXMLFormat_v1_0
                                                                  options:0
                                                                    error:&error];
    if (error)
    {
        NSLog(@"Error saving data: %@", error);
    }
    else
    {
        [plistData writeToFile:settingsFilePath atomically:YES];
    }
}

@end
