//
//  BrowserCell.m
//  NRDB
//
//  Created by Gereon Steffens on 08.08.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//


#import "BrowserCell.h"
#import "BrowserResultViewController.h"

@implementation BrowserCell

-(void) moreClicked:(UIButton*)sender
{
    [BrowserResultViewController showPopupForCard:self.card inView:self fromRect:sender.frame];
}


@end
