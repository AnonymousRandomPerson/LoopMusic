//
//  DeletePlaylistViewController.h
//  LoopMusic
//
//  Created by Cheng Hann Gan on 12/26/15.
//  Copyright © 2015 Cheng Hann Gan. All rights reserved.
//

#ifndef DeletePlaylistViewController_h
#define DeletePlaylistViewController_h

#import "MultipleSearchBase.h"

@interface DeletePlaylistViewController : MultipleSearchBase
{
    /// The currently selected playlist.
    NSString *selectedItem;
}

/*!
 * Displays a confirmation dialogue before deleting the selected playlist.
 * @param sender The object that called this function.
 * @return
 */
- (IBAction)deleteButton:(id)sender;

@end

#endif
