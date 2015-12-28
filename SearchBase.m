//
//  SearchBase.m
//  LoopMusic
//
//  Created by Cheng Hann Gan on 12/26/15.
//  Copyright © 2015 Cheng Hann Gan. All rights reserved.
//

#import "SearchBase.h"

@interface SearchBase ()

@end

@implementation SearchBase

- (void)viewDidLoad
{
    NSTimer *loadTimer = [NSTimer scheduledTimerWithTimeInterval:.1
                                                          target:self
                                                        selector:@selector(loadPresenter:)
                                                        userInfo:nil
                                                         repeats:NO];
}

-(void)loadPresenter:(NSTimer*)loadTimer
{
    presenter = (LoopMusicViewController*)self.presentingViewController;
    while (presenter.presentingViewController)
    {
        presenter = (LoopMusicViewController*)presenter.presentingViewController;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView)
    {
        return [searchedItems count];
    }
    else
    {
        return [items count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *simpleTableIdentifier = @"SongList";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    
    if (tableView == self.searchDisplayController.searchResultsTableView)
    {
        cell.textLabel.text = [searchedItems objectAtIndex:indexPath.row];
    }
    else
    {
        cell.textLabel.text = [items objectAtIndex:indexPath.row];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.searchDisplayController.active)
    {
        [self selectItem: searchedItems[indexPath.row]];
    }
    else
    {
        [self selectItem: items[indexPath.row]];
    }
}

-(void)selectItem:(NSString*)item
{
}

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
    NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"SELF contains[c] %@", searchText];
    searchedItems = [[NSMutableArray alloc] initWithArray:[items filteredArrayUsingPredicate:resultPredicate]];
}

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString
                               scope:[[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end


