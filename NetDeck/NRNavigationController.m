//
//  NRNavigationController.m
//  Net Deck
//
//  Created by Gereon Steffens on 30.01.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <SDCAlertView.h>

#import "Deck.h"
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
    // NSLog(@"do popToRoot");
    self.popToRoot = YES;
    return [super popToRootViewControllerAnimated:animated];
}

-(UIViewController*) popViewControllerAnimated:(BOOL)animated
{
    // NSInteger before = self.viewControllers.count;
    UIViewController* popped = [super popViewControllerAnimated:animated];
    // NSInteger after = self.viewControllers.count;
    // UIViewController* newTop = self.viewControllers.lastObject;
    // NSLog(@"popViewControllerAnimated: before=%ld, after=%ld, popped off=%@, new top=%@", (long)before, (long)after, popped, newTop);
    return popped;
}

#pragma mark gesture recognizer

- (void)handlePopGesture:(UIGestureRecognizer *)gesture
{
    // TODO: it appears this whole method is completely unnecessary. Needs investigation, see also Crashlytics #109
    
    CGPoint point = [gesture locationInView:self.view];
    CGRect frame = self.view.frame;
    
    // pop if the gesture ended AND the location of the touch release was on the right hand side of the master view
    if (gesture.state == UIGestureRecognizerStateEnded)
    {
        // NSInteger count = self.viewControllers.count;
        // NSString* title = [self.viewControllers.lastObject title];
        // NSLog(@"handle gesture, state=%ld, count=%ld, top=%@, %@", (long)gesture.state, (long)count, title, NSStringFromCGPoint(point));
        if (point.x > frame.size.width/2)
        {
            [self popViewControllerAnimated:IS_IPHONE];
        }
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
        if (self.viewControllers.count < 2)
        {
            // NSLog(@"swipe: nothing to pop");
            return NO;
        }
        
        if (self.deckEditor.deckModified && !self.alertShowing)
        {
            [self showAlert];
            self.swipePop = NO;
            // NSLog(@"swipe start aborted");
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
    // NSLog(@"should pop: toRoot=%d swipe=%d regular=%d alert=%d modified=%d", self.popToRoot, self.swipePop, self.regularPop, self.alertViewClicked, self.deckEditor.deckModified);
    
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
    
    if (self.deckEditor.deckModified)
    {
        // NSLog(@"should pop4: NO");
        if (!self.alertShowing)
        {
            [self showAlert];
        }
        return NO;
    }
    else
    {
        // NSLog(@"should pop5: NO, pop self");
        self.regularPop = YES;
        [self popViewControllerAnimated:IS_IPHONE];
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
            [self.deckEditor saveDeck];
        }
        self.alertViewClicked = YES;
        // NSLog(@"pop from alert");
        [self popViewControllerAnimated:IS_IPHONE];
    };
}

@end
