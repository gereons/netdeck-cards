//
//  NRNavigationController.m
//  NRDB
//
//  Created by Gereon Steffens on 30.01.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "NRNavigationController.h"
#import "DeckListViewController.h"

@interface NRNavigationController ()

@property BOOL alertViewClicked;
@property BOOL regularPop;
@property BOOL swipePop;

@end

@implementation NRNavigationController

-(void) viewDidLoad
{
    [super viewDidLoad];

    self.interactivePopGestureRecognizer.delegate = self;
    
    [self.interactivePopGestureRecognizer addTarget:self action:@selector(handlePopGesture:)];
}

- (void)handlePopGesture:(UIGestureRecognizer *)gesture
{
    // NSLog(@"handle gesture, state=%d", gesture.state);
    if (gesture.state == UIGestureRecognizerStateEnded)
    {
        // NSLog(@"end swipe, pop");
        [self popViewControllerAnimated:NO];
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer == self.interactivePopGestureRecognizer)
    {
        if (self.deckListViewController.deckChanged)
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

-(BOOL) navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item
{
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
        [self showAlert];
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
    UIAlertView* alert = [[UIAlertView alloc]
                          initWithTitle:nil
                          message:l10n(@"There are unsaved changes")
                          delegate:self
                          cancelButtonTitle:l10n(@"Cancel")
                          otherButtonTitles:l10n(@"Discard"), l10n(@"Save"), nil];
    [alert show];
}

-(void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.cancelButtonIndex)
    {
        return;
    }
    
    if (buttonIndex == 2)
    {
        [self.deckListViewController saveDeck:nil];
    }
    self.alertViewClicked = YES;
    [self popViewControllerAnimated:NO];
}

@end
