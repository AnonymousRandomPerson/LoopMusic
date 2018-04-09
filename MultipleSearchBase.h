//
//  MultipleSearchBase.h
//  LoopMusic
//
//  Created by Cheng Hann Gan on 12/27/15.
//  Copyright © 2015 Cheng Hann Gan. All rights reserved.
//

#ifndef MultipleSearchBase_h
#define MultipleSearchBase_h

#import "SearchBase.h"

@interface MultipleSearchBase : SearchBase
{
    /// The selected items in the list.
    NSMutableArray *selectedItems;
    
    /// Items selected since the instance was created
    NSMutableArray *recentlySelectedItems;
    
    /// Items unselected since the instance was created that were selected at creation
    NSMutableArray *recentlyUnselectedItems;
}

@end

#endif
