//
//  ModifyPlaylistViewController.m
//  LoopMusic
//
//  Created by Cheng Hann Gan on 12/26/15.
//  Copyright © 2015 Cheng Hann Gan. All rights reserved.
//

#import "ModifyPlaylistViewController.h"

@interface ModifyPlaylistViewController ()

@end

@implementation ModifyPlaylistViewController

- (void)viewDidLoad
{
    items = [self getTotalSongList];
    selectedItems = [self getSongList];
    [super viewDidLoad];
}

- (IBAction)confirmButton:(id)sender
{
    [self dismissViewControllerAnimated:true completion:nil];
    [self openDB];
    [self updateDB:[NSString stringWithFormat:@"DELETE FROM Playlists WHERE id = %ld", (long)playlistIndex]];
    for (NSString *item in selectedItems)
    {
        /// The ID of the track in the current iteration.
        NSInteger trackIndex = [self getIntegerDB:[NSString stringWithFormat:@"SELECT id FROM Tracks WHERE name = \"%@\"", item]];
        if (trackIndex)
        {
            [self updateDB:[NSString stringWithFormat:@"INSERT INTO Playlists (id, track) VALUES (%ld, %ld)", (long)playlistIndex, trackIndex]];
        }
    }
    sqlite3_close(trackData);
    [presenter updatePlaylistSongs];
}

@end
