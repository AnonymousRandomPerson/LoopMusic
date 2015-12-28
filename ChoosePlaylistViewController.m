//
//  ChoosePlaylistViewController.m
//  LoopMusic
//
//  Created by Cheng Hann Gan on 12/26/15.
//  Copyright © 2015 Cheng Hann Gan. All rights reserved.
//

#import "ChoosePlaylistViewController.h"

@interface ChoosePlaylistViewController ()

@end

@implementation ChoosePlaylistViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    items = [self getPlaylistList];
    if (![[items objectAtIndex:0] isEqualToString:@"All tracks"])
    {
        [items removeObject:@"All tracks"];
        [items insertObject:@"All tracks" atIndex:0];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    [self dismissViewControllerAnimated:true completion:nil];
}

-(void)selectItem:(NSString *)item
{
    [self openDB];
    playlistIndex = [self getIntegerDB:[NSString stringWithFormat:@"SELECT id FROM Playlists WHERE name = \"%@\"", item]];
    sqlite3_close(trackData);
    [presenter updatePlaylistSongs];
    [presenter updatePlaylistName:item];
}

@end