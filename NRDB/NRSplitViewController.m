//
//  NRSplitViewController.m
//  NRDB
//
//  Created by Gereon Steffens on 08.12.13.
//  Copyright (c) 2013 Gereon Steffens. All rights reserved.
//

#import "NRSplitViewController.h"

@interface NRSplitViewController ()

@end

@implementation NRSplitViewController

- (void)viewDidLayoutSubviews
{
    const CGFloat kMasterViewWidth = 320.0;
    
    UIViewController *masterViewController = [self.viewControllers objectAtIndex:0];
    UIViewController *detailViewController = [self.viewControllers objectAtIndex:1];
    
    // Adjust the width of the master view
    CGRect masterViewFrame = masterViewController.view.frame;
    CGFloat deltaX = masterViewFrame.size.width - kMasterViewWidth;
    masterViewFrame.size.width -= deltaX;
    masterViewController.view.frame = masterViewFrame;
    
    // Adjust the width of the detail view
    CGRect detailViewFrame = detailViewController.view.frame;
    detailViewFrame.origin.x -= deltaX;
    detailViewFrame.size.width += deltaX;
    detailViewController.view.frame = detailViewFrame;
    
    [masterViewController.view setNeedsLayout];
    [detailViewController.view setNeedsLayout];
}

@end
