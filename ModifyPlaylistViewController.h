//
//  ModifyPlaylistViewController.h
//  LoopMusic
//
//  Created by Cheng Hann Gan on 12/26/15.
//  Copyright © 2015 Cheng Hann Gan. All rights reserved.
//

#ifndef ModifyPlaylistViewController_h
#define ModifyPlaylistViewController_h

#import "MultipleSearchBase.h"

@interface ModifyPlaylistViewController : MultipleSearchBase

/*!
 * Modifies the current playlist.
 * @param sender The object that called this function.
 */
- (IBAction)confirmButton:(id)sender;

@end

#endif
