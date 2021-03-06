//
//  DeletePlaylistViewController.m
//  LoopMusic
//
//  Created by Cheng Hann Gan on 12/26/15.
//  Copyright © 2015 Cheng Hann Gan. All rights reserved.
//

#import "DeletePlaylistViewController.h"
#import "SettingsStore.h"

@interface DeletePlaylistViewController ()

@end

@implementation DeletePlaylistViewController

- (void)viewDidLoad
{
    items = [self getPlaylistNameList];
    [super viewDidLoad];
    table.allowsMultipleSelection = true;
    self.searchDisplayController.searchResultsTableView.allowsMultipleSelection = true;
    [items removeObject:@"All tracks"];
}

/*!
 * Sent to the delegate when the user clicks a button on an alert view.
 * @discussion The receiver is automatically dismissed after this method is invoked.
 * @param alertView The alert view containing the button.
 * @param buttonIndex The index of the button that was clicked. The button indices start at 0.
 */
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex)
    {
        [self dismissViewControllerAnimated:true completion:nil];
        [self openDB];
        for (NSString *item in selectedItems)
        {
            /// The ID of the playlist to be deleted.
            NSInteger deleteIndex = [self getIntegerDB:[NSString stringWithFormat:@"SELECT id FROM PlaylistNames WHERE name = \"%@\"", item]];
            [self updateDB:[NSString stringWithFormat:@"DELETE FROM PlaylistNames WHERE id = %ld", (long)deleteIndex]];
            [self updateDB:[NSString stringWithFormat:@"DELETE FROM Playlists WHERE id = %ld", (long)deleteIndex]];
            if (SettingsStore.instance.playlistIndex == deleteIndex)
            {
                SettingsStore.instance.playlistIndex = 0;
                [presenter updatePlaylistName:@""];
            }
        }
        sqlite3_close(trackData);
    }
}

- (IBAction)deleteButton:(id)sender
{
    /// The name of the playlist to be deleted.
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
