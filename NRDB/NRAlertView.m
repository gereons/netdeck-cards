//
//  NRAlertView.m
//  NRDB
//
//  Created by Gereon Steffens on 03.09.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "NRAlertView.h"

@interface NRAlertView()

@property (nonatomic, copy) NRAlertViewBlock dismissalBlock;

@end

@implementation NRAlertView

-(void) showWithDismissHandler:(NRAlertViewBlock)action
{
    NSAssert(self.delegate == nil, @"delegate set");
    
    self.delegate = self;
    self.dismissalBlock = action;
    [self show];
}

-(void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    self.dismissalBlock(buttonIndex);
}

@end
