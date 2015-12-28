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
    NSString *selectedItem;
}

-(IBAction)deleteButton:(id)sender;

@end
