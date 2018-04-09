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

-(NSString *)formStringTuple:(NSArray *)array
{
    // Assumes array is not empty
    return [NSString stringWithFormat:@"(\"%@\")", [array componentsJoinedByString:@"\", \""]];
}
-(NSString *)formIntTuple:(NSArray *)array
{
    return [NSString stringWithFormat:@"(%@)", [array componentsJoinedByString:@", "]];
}
-(NSString *)formIntTupleList:(NSInteger)first :(NSArray *)secondsArray
{
    // Forms (first, second[0]), (first, second[1]), ...
    // Assumes secondsArray is not empty
    return [NSString stringWithFormat:@"(%ld, %@)", first, [secondsArray componentsJoinedByString:[NSString stringWithFormat:@"), (%ld, ", first]]];
}

- (IBAction)confirmButton:(id)sender
{
    [self dismissViewControllerAnimated:true completion:nil];
    [self openDB];
    
    // Remove stuff
    NSArray *trackIndices;
    if (recentlyUnselectedItems.count > 0)
    {
        trackIndices = [self getMultiIntegerDB:[NSString stringWithFormat:@"SELECT id FROM Tracks WHERE name in %@ AND id != 0", [self formStringTuple:recentlyUnselectedItems]]];
        [self updateDB:[NSString stringWithFormat:@"DELETE FROM Playlists WHERE id = %ld AND track in %@", (long)playlistIndex, [self formIntTuple:trackIndices]]];
    }
    
    // Add stuff
    if (recentlySelectedItems.count > 0)
    {
        trackIndices = [self getMultiIntegerDB:[NSString stringWithFormat:@"SELECT id FROM Tracks WHERE name in %@ AND id != 0", [self formStringTuple:recentlySelectedItems]]];
        [self updateDB:[NSString stringWithFormat:@"INSERT INTO Playlists (id, track) VALUES %@", [self formIntTupleList:playlistIndex :trackIndices]]];
    }
    
    sqlite3_close(trackData);
    [presenter updatePlaylistSongs];
}

@end
