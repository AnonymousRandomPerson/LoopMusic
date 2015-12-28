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
    NSString *selectedItem;
}

-(IBAction)deleteButton:(id)sender;

@end

#endif
