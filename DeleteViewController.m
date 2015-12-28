//
//  DeleteViewController.m
//  LoopMusic
//
//  Created by Cheng Hann Gan on 5/8/15.
//  Copyright (c) 2015 Cheng Hann Gan. All rights reserved.
//

#import "DeleteViewController.h"

@interface DeleteViewController ()

@end

@implementation DeleteViewController

- (void)viewDidLoad
{
    items = [self getTotalSongList];
    [super viewDidLoad];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex)
    {
        [self dismissViewControllerAnimated:true completion:nil];
        [self openDB];
        
        for (NSString *item in selectedItems)
        {
            NSInteger deleteIndex = 0;
            
            if (playlistIndex)
            {
                deleteIndex = [self getIntegerDB:[NSString stringWithFormat:@"SELECT id FROM Tracks WHERE name = \"%@\"", item]];
            }
            [self updateDB:[NSString stringWithFormat:@"DELETE FROM Tracks WHERE name = \"%@\"", item]];
            [presenter decrementTotalSongs];
            if (playlistIndex)
            {
                NSArray *splitSongs = [self getSongIndices];
                if (splitSongs)
                {
                    NSString *deleteIndexString = [NSString stringWithFormat:@"%ld", (long)deleteIndex];
                    if ([splitSongs containsObject:deleteIndexString])
                    {
                        [presenter decrementPlaylistSongs];
                    }
                }
            }
        }
        sqlite3_close(trackData);
    }
}

-(IBAction)deleteButton:(id)sender
{
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
    [self showTwoButtonMessage:@"Delete Playlist" :[NSString stringWithFormat:@"Delete %@?", deleteText] :@"Okay"];
}

@end
