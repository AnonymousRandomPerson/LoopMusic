//
//  DeleteViewController.h
//  LoopMusic
//
//  Created by Cheng Hann Gan on 5/8/15.
//  Copyright (c) 2015 Cheng Hann Gan. All rights reserved.
//

#import "LoopMusicViewController.h"

@interface DeleteViewController : LoopMusicViewController
{
    NSMutableArray *songs;
    NSMutableArray *searchedSongs;
    LoopMusicViewController *presenter;
}

@end
