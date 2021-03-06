//
//  DeleteViewController.m
//  LoopMusic
//
//  Created by Cheng Hann Gan on 5/8/15.
//  Copyright (c) 2015 Cheng Hann Gan. All rights reserved.
//

#import "DeleteViewController.h"
#import "SettingsStore.h"

@interface DeleteViewController ()

@end

@implementation DeleteViewController

- (void)viewDidLoad
{
    items = [self getTotalSongList];
    [super viewDidLoad];
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
            /// The ID of the track to be deleted.
            NSInteger deleteIndex = 0;
            
            deleteIndex = [self getIntegerDB:[NSString stringWithFormat:@"SELECT id FROM Tracks WHERE name = \"%@\"", item]];
            [self updateDB:[NSString stringWithFormat:@"DELETE FROM Playlists WHERE track = %ld", (long)deleteIndex]];
            [self updateDB:[NSString stringWithFormat:@"DELETE FROM Tracks WHERE name = \"%@\"", item]];
            [presenter decrementTotalSongs];
        }
        sqlite3_close(trackData);
        [presenter updatePlaylistSongs];
    }
}

- (IBAction)deleteButton:(id)sender
{
    /// The name of the track to be deleted.
    NSString* deleteText;
    if (selectedItems.count == 0)
    {
        [self showErrorMessage:@"No tracks selected."];
    }
    else if (selectedItems.count == 1)
    {
        deleteText = [selectedItems objectAtIndex:0];
    }
    else
    {
        deleteText = @"these tracks";
    }
    [self showTwoButtonMessage:@"Delete Track" :[NSString stringWithFormat:@"Delete %@?", deleteText] :@"Okay"];
}

@end
