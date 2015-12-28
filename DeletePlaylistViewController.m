//
//  DeletePlaylistViewController.m
//  LoopMusic
//
//  Created by Cheng Hann Gan on 12/26/15.
//  Copyright © 2015 Cheng Hann Gan. All rights reserved.
//

#import "DeletePlaylistViewController.h"

@interface DeletePlaylistViewController ()

@end

@implementation DeletePlaylistViewController

-(void)viewDidLoad
{
    items = [self getPlaylistList];
    [super viewDidLoad];
    table.allowsMultipleSelection = true;
    self.searchDisplayController.searchResultsTableView.allowsMultipleSelection = true;
    [items removeObject:@"All tracks"];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex)
    {
        [self dismissViewControllerAnimated:true completion:nil];
        [self openDB];
        for (NSString *item in selectedItems)
        {
            NSInteger deleteIndex = [self getIntegerDB:[NSString stringWithFormat:@"SELECT id FROM Playlists WHERE name = \"%@\"", item]];
            if (playlistIndex == deleteIndex)
            {
                playlistIndex = 0;
                [presenter updatePlaylistName:@""];
            }
            [self updateDB:[NSString stringWithFormat:@"DELETE FROM Playlists WHERE name = \"%@\"", item]];
        }
        sqlite3_close(trackData);
    }
}

-(IBAction)deleteButton:(id)sender
{
    NSString* deleteText;
    if (selectedItems.count == 0)
    {
        [self showErrorMessage:@"No playlists selected."];
    }
    else if (selectedItems.count == 1)
    {
        deleteText = [selectedItems objectAtIndex:0];
    }
    else
    {
        deleteText = @"these playlists";
    }
    [self showTwoButtonMessage:@"Delete Playlist" :[NSString stringWithFormat:@"Delete %@?", deleteText] :@"Okay"];
}

@end