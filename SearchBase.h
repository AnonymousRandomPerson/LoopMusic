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
    NSMutableArray *items;
    NSMutableArray *searchedItems;
    LoopMusicViewController *presenter;
    
    IBOutlet UITableView *table;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
-(void)selectItem:(NSString*)item;

@end

#endif
