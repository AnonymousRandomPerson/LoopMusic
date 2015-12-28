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

-(void)unselectItem:(NSString *)item
{
    [selectedItems removeObject:item];
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([selectedItems containsObject:cell.textLabel.text])
    {
        [cell setSelected:true];
        [tableView selectRowAtIndexPath:indexPath
                               animated:false
                         scrollPosition:UITableViewScrollPositionTop];
    }
}

@end