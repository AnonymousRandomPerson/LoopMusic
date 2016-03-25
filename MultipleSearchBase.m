//
//  MultipleSearchBase.m
//  LoopMusic
//
//  Created by Cheng Hann Gan on 12/27/15.
//  Copyright © 2015 Cheng Hann Gan. All rights reserved.
//

#import "MultipleSearchBase.h"

@implementation MultipleSearchBase

-(void)viewDidLoad
{
    [super viewDidLoad];
    table.allowsMultipleSelection = true;
    self.searchDisplayController.searchResultsTableView.allowsMultipleSelection = true;
    if (!selectedItems)
    {
        selectedItems = [NSMutableArray arrayWithCapacity:items ? items.count : 8];
    }
}

-(void)selectItem:(NSString *)item
{
    [selectedItems addObject:item];
}

/*!
 * Tells the delegate that the specified row is now deselected.
 * @discussion The delegate handles row deselections in this method. It could, for example, remove the check-mark image (UITableViewCellAccessoryCheckmark) associated with the row.
 * @param tableView A table-view object informing the delegate about the row deselection.
 * @param indexPath An index path locating the deselected row in tableView.
 * @return
 */
-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.searchDisplayController.active)
    {
        [self unselectItem: searchedItems[indexPath.row]];
    }
    else
    {
        [self unselectItem: items[indexPath.row]];
    }
}

/*!
 * Removes an item from the selected items list when it is deselected.
 * @param The name of the item that was deselected.
 * @return
 */
-(void)unselectItem:(NSString *)item
{
    [selectedItems removeObject:item];
}

/*!
 * Tells the delegate the table view is about to draw a cell for a particular row.
 * @param tableView The table-view object informing the delegate of this impending event.
 * @param cell A table-view cell object that tableView is going to use when drawing the row.
 * @param indexPath An index path locating the row in tableView.
 * @return
 */
-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([selectedItems containsObject:cell.textLabel.text])
    {
        [cell setSelected:true];
        [tableView selectRowAtIndexPath:indexPath
                               animated:false
                         scrollPosition:UITableViewScrollPositionNone];
    }
}

@end