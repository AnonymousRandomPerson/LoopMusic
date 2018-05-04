//
//  DeleteViewController.h
//  LoopMusic
//
//  Created by Cheng Hann Gan on 5/8/15.
//  Copyright (c) 2015 Cheng Hann Gan. All rights reserved.
//

#import "MultipleSearchBase.h"

@interface DeleteViewController : MultipleSearchBase
{
    /// The currently selected track.
    NSString *selectedItem;
}

/*!
 * Displays a confirmation dialogue before deleting the selected track.
 * @param sender The object that called this function.
 */
- (IBAction)deleteButton:(id)sender;

@end
