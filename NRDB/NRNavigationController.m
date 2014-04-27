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

@end

@implementation NRNavigationController

-(void) viewDidLoad
{
    [super viewDidLoad];

    // disable swipe gesture
    self.interactivePopGestureRecognizer.enabled = NO;
    
    // TODO: figure out how to handle and intercept swipe gesture correctly
    // [self.interactivePopGestureRecognizer addTarget:self action:@selector(handlePopGesture:)];
}

/*
- (void)handlePopGesture:(UIGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateEnded)
    {
        NSLog(@"pop view");
        [self popViewControllerAnimated:NO];
    }
}
*/

-(BOOL) navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item
{
    if (self.regularPop)
    {
        self.regularPop = NO;
        return YES;
    }
    if (self.alertViewClicked)
    {
        self.alertViewClicked = NO;
        return YES;
    }
    
    BOOL unsavedChanges = self.deckListViewController.deckChanged;
    if (unsavedChanges)
    {
        UIAlertView* alert = [[UIAlertView alloc]
                          initWithTitle:nil
                          message:l10n(@"There are unsaved changes")
                          delegate:self
                          cancelButtonTitle:l10n(@"Cancel")
                          otherButtonTitles:l10n(@"Discard"), l10n(@"Save"), nil];
        [alert show];
        
        return NO;
    }
    else
    {
        self.regularPop = YES;
        [self popViewControllerAnimated:NO];
        return NO;
    }
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
