//
//  NRActionSheet.m
//  NRDB
//
//  Created by Gereon Steffens on 19.07.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "NRActionSheet.h"

@interface NRActionSheet ()

@property (nonatomic, copy) NRActionSheetBlock dismissalBlock;

@end

@implementation NRActionSheet

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    self.dismissalBlock(buttonIndex);
}

-(void) showFromBarButtonItem:(UIBarButtonItem *)item animated:(BOOL)animated action:(NRActionSheetBlock)action
{
    self.dismissalBlock = action;
    self.delegate = self;
    [self showFromBarButtonItem:item animated:animated];
}

-(void) showFromRect:(CGRect)rect inView:(UIView *)view animated:(BOOL)animated action:(NRActionSheetBlock)action
{
    self.dismissalBlock = action;
    self.delegate = self;
    [self showFromRect:rect inView:view animated:animated];
}

@end
