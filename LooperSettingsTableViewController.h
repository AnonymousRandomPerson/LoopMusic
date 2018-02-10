//
//  LooperSettingsTableViewController.h
//  LoopMusic
//
//  Created by Johann Gan on 2/5/18.
//  Copyright © 2018 Cheng Hann Gan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LoopFinderAuto.h"


/// Abstract class for looper settings table views.
@interface LooperSettingsTableViewController : UITableViewController
{
}
/// The looper to change the settings of.
@property (strong, nonatomic) LoopFinderAuto *finder;
/// Maps from tag number (NSInteger) to parameter names (NSString *)
@property (strong, nonatomic) NSDictionary *parameterNames;


/*!
 * Updates all of the parameter displays.
 * @return
 */
- (void)refreshParameterDisplays;

- (IBAction)closeTextField:(id)sender;
- (IBAction)updateSetting:(id)sender;

@end
