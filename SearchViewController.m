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

@synthesize back;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    // Do any additional setup after loading the view.
    //open database
    stringTemp = [[NSBundle mainBundle] pathForResource:@"Tracks" ofType:@"db"];
    dbPath = [stringTemp UTF8String];
    // Get the documents directory
    database = nil;
    dirPaths = NSSearchPathForDirectoriesInDomains
    (NSDocumentDirectory, NSUserDomainMask, YES);
    docsDir = dirPaths[0];
    // Build the path to the database file
    databasePath = [[NSString alloc] initWithString:[docsDir stringByAppendingPathComponent: @"Tracks.db"]];
    dbPath2 = [databasePath UTF8String];
    sqlite3_open(dbPath2, &trackData);
    NSString *querySQL = [NSString stringWithFormat:@"SELECT max(id) FROM Tracks"];
    const char *query_stmt = [querySQL UTF8String];
    sqlite3_prepare_v2(trackData, query_stmt, -1, &statement, NULL);
    sqlite3_step(statement);
    totalSongs = [[[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 0)] integerValue];
    sqlite3_finalize(statement);
    sqlite3_close(trackData);
    NSString *songListName;
    sqlite3_open(dbPath2, &trackData);
    for (NSInteger i = 1; i<=totalSongs; i++)
    {
        querySQL = [NSString stringWithFormat:@"SELECT name FROM Tracks WHERE id=\"%li\"", (long)i];
        query_stmt = [querySQL UTF8String];
        sqlite3_prepare_v2(trackData, query_stmt, -1, &statement, NULL);
        if (sqlite3_step(statement) == SQLITE_ROW)
        {
            songListName = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 0)];
        }
        if (i==1)
        {
            songs = [NSMutableArray arrayWithObjects:songListName,nil];
        }
        else
        {
            [songs addObject:songListName];
        }
        sqlite3_finalize(statement);
    }
    sqlite3_close(trackData);
    [songs sortUsingSelector:@selector(compare:)];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return [searchedSongs count];
        
    } else {
        return [songs count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *simpleTableIdentifier = @"SongList";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        cell.textLabel.text = [searchedSongs objectAtIndex:indexPath.row];
    } else {
        cell.textLabel.text = [songs objectAtIndex:indexPath.row];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.searchDisplayController.active) {
        [(LoopMusicViewController*)self.presentingViewController chooseSong:searchedSongs[indexPath.row]];
    } else {
        [(LoopMusicViewController*)self.presentingViewController chooseSong:songs[indexPath.row]];
    }
    [self dismissViewControllerAnimated:true completion:nil];
}

-(IBAction)back:(id)sender
{
    [self dismissViewControllerAnimated:true completion:nil];
}

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
    NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"SELF contains[c] %@", searchText];
    searchedSongs = [[NSMutableArray alloc] initWithArray:[songs filteredArrayUsingPredicate:resultPredicate]];
}

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString
                               scope:[[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar
                                                     selectedScopeButtonIndex]]];
    
    return YES;
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
