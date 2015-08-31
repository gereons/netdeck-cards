//
//  DetailViewManager.m
//  Net Deck
//
//  Created by Gereon Steffens on 15.03.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "DetailViewManager.h"

@interface DetailViewManager ()

@end

@implementation DetailViewManager

// -------------------------------------------------------------------------------
//	setDetailViewController:
//  Custom implementation of the setter for the detailViewController property.
// -------------------------------------------------------------------------------
- (void)setDetailViewController:(UIViewController<SubstitutableDetailViewController> *)detailViewController
{
    _detailViewController = detailViewController;
    
    // Update the split view controller's view controllers array.
    // This causes the new detail view controller to be displayed.
    UIViewController *navigationViewController = [self.splitViewController.viewControllers objectAtIndex:0];
    NSArray *viewControllers = [[NSArray alloc] initWithObjects:navigationViewController, _detailViewController, nil];
    self.splitViewController.viewControllers = viewControllers;
}

#pragma mark -
#pragma mark UISplitViewDelegate

// -------------------------------------------------------------------------------
//	splitViewController:shouldHideViewController:inOrientation:
// -------------------------------------------------------------------------------
- (BOOL)splitViewController:(UISplitViewController *)svc 
   shouldHideViewController:(UIViewController *)vc 
              inOrientation:(UIInterfaceOrientation)orientation
{
    return UIInterfaceOrientationIsPortrait(orientation);
}

@end

@implementation SubstitutableNavigationController

@end
