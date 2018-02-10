//
//  LooperSettingsTableViewController.m
//  LoopMusic
//
//  Created by Johann Gan on 2/5/18.
//  Copyright © 2018 Cheng Hann Gan. All rights reserved.
//

#import "LooperSettingsTableViewController.h"

@interface LooperSettingsTableViewController ()

@end

@implementation LooperSettingsTableViewController

@synthesize finder, parameterNames;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    parameterNames = [self formParamNamesDict];
    
    // Refresh the parameter displays with their current values upon opening.
    [NSTimer scheduledTimerWithTimeInterval:.1
                                     target:self
                                   selector:@selector(refreshParameterDisplays)
                                   userInfo:nil
                                    repeats:NO];
}

/// Returns the parameter names dictionary. Keys should be NSInteger and values should be NSString *. Reimplement in subclasses.
- (NSDictionary*)formParamNamesDict
{
    return nil;
}

- (IBAction)closeTextField:(id)sender
{
    [sender resignFirstResponder];
}

- (IBAction)updateSetting:(id)sender
{
    [self updateParameterValue:[sender tag] :((UITextField *)sender).text];
    [self updateParameterDisplay:[sender tag]];
}
- (void)updateParameterValue:(NSInteger)tag :(NSString *)value
{
    NSScanner *scan = [NSScanner scannerWithString:value];
    double doubleVal;
    if ([scan scanDouble:&doubleVal] && [scan isAtEnd])
    {
        [finder setValue:[NSNumber numberWithDouble:doubleVal] forKey:parameterNames[[NSNumber numberWithInteger:tag]]];
    }
}
- (void)updateParameterDisplay:(NSInteger)tag
{
    [[self.view viewWithTag:tag] setText:[(NSNumber *)[finder valueForKey:parameterNames[[NSNumber numberWithInteger:tag]]] stringValue]];
}
- (void)refreshParameterDisplays
{
    for (NSNumber * tag in parameterNames)
    {
        [self updateParameterDisplay:[tag integerValue]];
    }
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
