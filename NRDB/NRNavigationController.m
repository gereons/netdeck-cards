//
//  NRNavigationController.m
//  NRDB
//
//  Created by Gereon Steffens on 30.01.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <SDCAlertView.h>

#import "NRNavigationController.h"
#import "DeckListViewController.h"

@interface NRNavigationController ()

@property BOOL alertViewClicked;
@property BOOL regularPop;
@property BOOL swipePop;
@property BOOL popToRoot;

@property BOOL alertShowing;

@end

@implementation NRNavigationController

-(void) viewDidLoad
{
    [super viewDidLoad];

    self.interactivePopGestureRecognizer.delegate = self;
    [self.interactivePopGestureRecognizer addTarget:self action:@selector(handlePopGesture:)];
}

-(NSArray*) popToRootViewControllerAnimated:(BOOL)animated
{
    self.popToRoot = YES;
    return [super popToRootViewControllerAnimated:animated];
}

#pragma mark gesture recognizer

- (void)handlePopGesture:(UIGestureRecognizer *)gesture
{
    // NSLog(@"handle gesture, state=%d", gesture.state);
    if (gesture.state == UIGestureRecognizerStateEnded)
    {
        // NSLog(@"end swipe, pop");
        [self popViewControllerAnimated:NO];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([touch.view isKindOfClass:[UISlider class]])
    {
        // prevent recognizing touches on the filter sliders
        return NO;
    }
    return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer == self.interactivePopGestureRecognizer)
    {
        if (self.deckListViewController.deckChanged && !self.alertShowing)
        {
            [self showAlert];
            self.swipePop = NO;
            return NO;
        }
    }
    self.swipePop = YES;
    // NSLog(@"swipe start ok");
    return YES;
}

#pragma mark nav bar delegate

-(BOOL) navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item
{
    // NSLog(@"should pop: %d %d %d %d", self.popToRoot, self.swipePop, self.regularPop, self.alertViewClicked);
    
    if (self.popToRoot)
    {
        // NSLog(@"pop to root");
        self.popToRoot = NO;
        return YES;
    }
    
    if (self.swipePop)
    {
        // NSLog(@"should pop1: YES");
        self.swipePop = NO;
        return YES;
    }
    if (self.regularPop)
    {
        // NSLog(@"should pop2: YES");
        self.regularPop = NO;
        return YES;
    }
    if (self.alertViewClicked)
    {
        // NSLog(@"should pop3: YES");
        self.alertViewClicked = NO;
        return YES;
    }
    
    if (self.deckListViewController.deckChanged)
    {
        // NSLog(@"should pop4: NO");
        if (!self.alertShowing) {
            [self showAlert];
        }
        return NO;
    }
    else
    {
        // NSLog(@"should pop5: NO, pop self");
        self.regularPop = YES;
        [self popViewControllerAnimated:NO];
        return NO;
    }
}

-(void) showAlert
{
    self.alertShowing = YES;
    SDCAlertView* alert = [SDCAlertView alertWithTitle:nil
                                               message:l10n(@"There are unsaved changes")
                                               buttons:@[l10n(@"Cancel"), l10n(@"Discard"), l10n(@"Save")]];
    
    alert.didDismissHandler = ^(NSInteger buttonIndex) {
        self.alertShowing = NO;
        
        if (buttonIndex == 0) // cancel
        {
            return;
        }
        
        if (buttonIndex == 2) // save
        {
            [self.deckListViewController saveDeckManually:YES withHud:NO];
        }
        self.alertViewClicked = YES;
        // NSLog(@"pop from alert");
        [self popViewControllerAnimated:NO];
    };
}

@end
