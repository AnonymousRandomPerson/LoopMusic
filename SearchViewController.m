//
//  SearchViewController.m
//  LoopMusic
//
//  Created by Cheng Hann Gan on 5/30/14.
//  Copyright (c) 2014 Cheng Hann Gan. All rights reserved.
//

#import "SearchViewController.h"

@interface SearchViewController ()

@end

@implementation SearchViewController

/// The last search query the user entered.
static NSString* lastSearch;
/// The last scroll position the user was at.
static CGPoint lastPosition;

- (void)viewDidLoad
{
    [super viewDidLoad];
    items = [self getSongList];
    [self restoreSearch:lastSearch
                       :lastPosition];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    [self dismissViewControllerAnimated:true completion:nil];
}

- (IBAction)back:(id)sender
{
    [self savePosition];
    [super back:sender];
}

- (void)selectItem:(NSString *)item
{
    [self savePosition];
    
    [presenter chooseSong:item];
}

/*!
 * Saves the current position of the search.
 * @return
 */
- (void)savePosition
{
    lastSearch = self.searchDisplayController.searchBar.text;
    lastPosition = table.contentOffset;
}

@end
