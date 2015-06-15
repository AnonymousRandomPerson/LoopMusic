//
//  SearchViewController.h
//  LoopMusic
//
//  Created by Cheng Hann Gan on 5/30/14.
//  Copyright (c) 2014 Cheng Hann Gan. All rights reserved.
//

#import "LoopMusicViewController.h"
extern const char *dbPath;

@interface SearchViewController : LoopMusicViewController <UITableViewDelegate, UITableViewDataSource>
{
    IBOutlet UIButton *back;
    NSMutableArray *songs;
    NSMutableArray *searchedSongs;
}

@property(nonatomic, retain) UIButton *back;

@end