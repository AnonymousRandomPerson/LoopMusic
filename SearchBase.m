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
    /// Timer to load the main screen of the app.
    [NSTimer scheduledTimerWithTimeInterval:.1
                                     target:self
                                   selector:@selector(loadPresenter:)
                                   userInfo:nil
                                    repeats:NO];
}

/*!
 * Loads the main screen of the app.
 * @param loadTimer The timer that called this function.
 */
- (void)loadPresenter:(NSTimer*)loadTimer
{
    presenter = (LoopMusicViewController*)self.presentingViewController;
    while (presenter.presentingViewController)
    {
        presenter = (LoopMusicViewController*)presenter.presentingViewController;
    }
}

/*!
 * Tells the data source to return the number of rows in a given section of a table view.
 * @param tableView The table-view object requesting this information.
 * @param section An index number identifying a section in tableView.
 * @return The number of rows in section.
 */
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

/*!
 * Asks the data source for a cell to insert in a particular location of the table view.
 * @discussion The returned UITableViewCell object is frequently one that the application reuses for performance reasons. You should fetch a previously created cell object that is marked for reuse by sending a dequeueReusableCellWithIdentifier: message to tableView. Various attributes of a table cell are set automatically based on whether the cell is a separator and on information the data source provides, such as for accessory views and editing controls.
 * @param tableView A table-view object requesting the cell.
 * @param indexPath An index path locating a row in tableView.
 * @return An object inheriting from UITableViewCell that the table view can use for the specified row. An assertion is raised if you return nil.
 */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    /// The name of the table.
    static NSString *simpleTableIdentifier = @"SongList";
    
    /// The cell to use for the specified row.
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    
    if (tableView == self.searchDisplayController.searchResultsTableView)
    {
        cell.textLabel.text = [searchedItems objectAtIndex:indexPath.row];
        table = tableView;
    }
    else
    {
        cell.textLabel.text = [items objectAtIndex:indexPath.row];
        if (!self.searchDisplayController.active)
        {
            table = tableView;
        }
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

- (void)selectItem:(NSString*)item
{
}

/*!
 * Filters the list of items according to the search query.
 * @param searchText The search query to filter the list with.
 * @param scope The scope of the search query.
 */
- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
    /// The predicate to filter the list with.
    NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"SELF contains[c] %@", searchText];
    searchedItems = [[NSMutableArray alloc] initWithArray:[items filteredArrayUsingPredicate:resultPredicate]];
}

/*!
 * Asks the delegate if the table view should be reloaded for a given search string.
 * @discussion If you don’t implement this method, then the results table is reloaded as soon as the search string changes.
 
 You might implement this method if you want to perform an asynchronous search. You would initiate the search in this method, then return NO. You would reload the table when you have results.
 * @param controller The search display controller for which the receiver is the delegate.
 * @param searchString The string in the search bar.
 * @return YES if the display controller should reload the data in its table view, otherwise NO.
 */
- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString
                               scope:[self getScope]];
    return YES;
}

/*!
 * Gets the scope of the search.
 * @return The scope of the search.
 */
- (NSString*)getScope
{
    return [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]];
}

- (void)restoreSearch:(NSString *)lastSearch :(CGPoint)lastPosition
{
    if (lastSearch != nil && ![lastSearch isEqualToString:@""])
    {
        self.searchDisplayController.active = true;
        self.searchDisplayController.searchBar.text = lastSearch;
        table = self.searchDisplayController.searchResultsTableView;
    }
    [table setContentOffset:lastPosition];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end


