//
//  SearchBase.h
//  LoopMusic
//
//  Created by Cheng Hann Gan on 12/26/15.
//  Copyright © 2015 Cheng Hann Gan. All rights reserved.
//

#ifndef SearchBase_h
#define SearchBase_h

#import "LoopMusicViewController.h"

@interface SearchBase : LoopMusicViewController
{
    /// All items in the search list.
    NSMutableArray *items;
    /// Items that match the search query.
    NSMutableArray *searchedItems;
    /// The main screen of the app.
    LoopMusicViewController *presenter;
    
    /// The table displaying the item list.
    IBOutlet UITableView *table;
}

/*!
 * Tells the delegate that the specified row is now selected.
 * @discussion The delegate handles selections in this method. One of the things it can do is exclusively assign the check-mark image (UITableViewCellAccessoryCheckmark) to one row in a section (radio-list style). This method isn’t called when the editing property of the table is set to YES (that is, the table view is in editing mode). See "Managing Selections" in Table View Programming Guide for iOS for further information (and code examples) related to this method.
 * @param tableView A table-view object informing the delegate about the new row selection.
 * @param indexPath An index path locating the new selected row in tableView.
 * @return
 */
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
/*!
 * Processes the selection of an item in the list.
 * @param The name of the item that was selected.
 * @return
 */
- (void)selectItem:(NSString *)item;

/*!
 * Restores the previous search query when this screen was last used.
 * @param lastSearch The previous search string.
 * @param lastPosition The previous search position.
 * @return
 */
- (void)restoreSearch:(NSString *)lastSearch :(CGPoint)lastPosition;

@end

#endif
