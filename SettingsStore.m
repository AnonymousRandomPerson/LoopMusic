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
/// Plist key for repeatsShuffle.
static NSString *KEY_REPEATS_SHUFFLE = @"repeatsShuffle";
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

+ (SettingsStore*)instance {
    return _instance;
}

- (void)initialize
{
    if (!_instance)
    {
        _instance = [[SettingsStore alloc] init];
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
    
    if ([fileManager fileExistsAtPath:settingsFilePath])
    {
        /// The contents of the settings file.
        NSDictionary *settingsDict = [[NSDictionary alloc] initWithContentsOfFile:settingsFilePath];
        _fadeSetting = [[settingsDict objectForKey:KEY_FADE_SETTING] doubleValue];
        _masterVolume = [[settingsDict objectForKey:KEY_MASTER_VOLUME] floatValue];
        _playlistIndex = [[settingsDict objectForKey:KEY_PLAYLIST_INDEX] integerValue];
        _repeatsShuffle = [[settingsDict objectForKey:KEY_REPEATS_SHUFFLE] integerValue];
        _shuffleSetting = [[settingsDict objectForKey:KEY_SHUFFLE_SETTING] unsignedIntegerValue];
        _timeShuffle = [[settingsDict objectForKey:KEY_TIME_SHUFFLE] doubleValue];
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
            _shuffleSetting = [splitSettings[0] unsignedIntegerValue];
            _timeShuffle = [splitSettings[1] doubleValue];
            _repeatsShuffle = [splitSettings[2] integerValue];
            _fadeSetting = splitSettings.count > 3 ? [splitSettings[3] doubleValue] : 2;
            _playlistIndex = splitSettings.count > 4 ? [splitSettings[4] integerValue] : 0;
            _masterVolume = splitSettings.count > 5 ? [splitSettings[5] floatValue] : 0;
        }
        else
        {
            // Default values.
            _shuffleSetting = 1;
            _timeShuffle = 3.5;
            _repeatsShuffle = 3;
            _fadeSetting = 2;
            _playlistIndex = 0;
            _masterVolume = 0;
        }
        [self saveSettings];
        
        error = nil;
        //[fileManager removeItemAtPath:documentsFilePath error:&error];
        if (error)
        {
            NSLog(@"Error removing plain text settings file: %@", error);
        }
    }
}

- (void)saveSettings
{
    NSString *settingsFilePath = [[NSHomeDirectory() stringByAppendingPathComponent:DOCUMENTS_DIR] stringByAppendingPathComponent:SETTINGS_PLIST];
    NSMutableDictionary *saveDict = [NSMutableDictionary alloc];
    [saveDict setValue:[NSString stringWithFormat:@"%@", @(_fadeSetting)] forKey:KEY_FADE_SETTING];
    [saveDict setValue:[NSString stringWithFormat:@"%@", @(_masterVolume)] forKey:KEY_MASTER_VOLUME];
    [saveDict setValue:[NSString stringWithFormat:@"%@", @(_playlistIndex)] forKey:KEY_PLAYLIST_INDEX];
    [saveDict setValue:[NSString stringWithFormat:@"%@", @(_repeatsShuffle)] forKey:KEY_REPEATS_SHUFFLE];
    [saveDict setValue:[NSString stringWithFormat:@"%@", @(_shuffleSetting)] forKey:KEY_SHUFFLE_SETTING];
    [saveDict setValue:[NSString stringWithFormat:@"%@", @(_timeShuffle)] forKey:KEY_TIME_SHUFFLE];
    
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
