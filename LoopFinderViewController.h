//
//  LoopFinderViewController.h
//  LoopMusic
//
//  Created by Cheng Hann Gan on 6/16/14.
//  Copyright (c) 2014 Cheng Hann Gan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SettingsViewController.h"

@interface LoopFinderViewController : SettingsViewController
{
    IBOutlet UITextField *setCurrentTime;
    IBOutlet UILabel *finderSongName;
    IBOutlet UITextField *finderSetTime;
    IBOutlet UITextField *finderSetTimeEnd;
    IBOutlet UILabel *findTimeText;
}

@property(nonatomic, retain) UITextField *setCurrentTime;
@property(nonatomic, retain) UILabel *finderSongName;
@property(nonatomic, retain) UITextField *finderSetTime;
@property(nonatomic, retain) UITextField *finderSetTimeEnd;

-(IBAction)setCurrentTime:(id)sender;
-(IBAction)finderSetTime:(id)sender;
-(IBAction)finderSetTimeEnd:(id)sender;
-(IBAction)setTimeButton:(id)sender;
-(IBAction)setEndButton:(id)sender;

@end
