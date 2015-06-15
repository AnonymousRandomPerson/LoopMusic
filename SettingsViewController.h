//
//  SettingsViewController.h
//  LoopMusic
//
//  Created by Cheng Hann Gan on 5/24/14.
//  Copyright (c) 2014 Cheng Hann Gan. All rights reserved.
//

#import "LoopMusicViewController.h"

@interface SettingsViewController : LoopMusicViewController <MPMediaPickerControllerDelegate> {
    IBOutlet UIButton *back;
    IBOutlet UITextField *volumeAdjust;
    IBOutlet UITextField *setTime;
    IBOutlet UITextField *setTimeEnd;
    IBOutlet UITextField *shuffleTime;
    IBOutlet UITextField *shuffleRepeats;
    IBOutlet UISegmentedControl *shuffle;
    IBOutlet UISwitch *enabledSwitch;
    LoopMusicViewController *presenter;
}

@property(nonatomic, retain) UIButton *back;
@property(nonatomic, retain) UITextField *volumeAdjust;
@property(nonatomic, retain) UITextField *setTime;
@property(nonatomic, retain) UITextField *setTimeEnd;
@property(nonatomic, retain) UITextField *shuffleTime;
@property(nonatomic, retain) UITextField *shuffleRepeats;
@property(nonatomic, retain) UISegmentedControl *shuffle;
@property(nonatomic, retain) UISwitch *enabledSwitch;

-(IBAction)setVolume:(id)sender;
-(IBAction)setTime:(id)sender;
-(IBAction)setTimeEnd:(id)sender;
-(IBAction)shuffleTime:(id)sender;
-(IBAction)shuffleRepeats:(id)sender;
-(IBAction)close:(id)sender;
-(IBAction)shuffleChange:(id)sender;
-(IBAction)loopFinder:(id)sender;
-(IBAction)enabledSwitch:(id)sender;
-(void)returned;

@end
