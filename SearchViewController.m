//
//  SearchViewController.m
//  LoopMusic
//
//  Created by Cheng Hann Gan on 5/30/14.
//  Copyright (c) 2014 Cheng Hann Gan. All rights reserved.
//

#import "SearchViewController.h"

@interface SearchViewController ()

@end

@implementation SearchViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    items = [self getSongList];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    [self dismissViewControllerAnimated:true completion:nil];
}

-(void)selectItem:(NSString *)item
{
    [presenter chooseSong:item];
}

@end
