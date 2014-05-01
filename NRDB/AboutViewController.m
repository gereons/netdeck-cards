//
//  AboutViewController.m
//  NRDB
//
//  Created by Gereon Steffens on 25.03.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "AboutViewController.h"
#import <StoreKit/StoreKit.h>
#import <MessageUI/MessageUI.h>

@interface AboutViewController ()
@property SKStoreProductViewController* storeViewController;
@property MFMailComposeViewController *mailer;
@property UIActionSheet* popup;
@end

@implementation AboutViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationController.navigationBar.topItem.title = l10n(@"About");
    self.webView.delegate = self;
        
    NSURL* url= [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"About" ofType:@"html"] isDirectory:NO];
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
#if defined(DEBUG) || defined(ADHOC)
    // CFBundleVersion contains the git describe output
    NSString* version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
#else
    // CFBundleShortVersionString contains the main version
    NSString* version = [@"v" stringByAppendingString:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
#endif
    
    NSString* title = [NSString stringWithFormat:l10n(@"About Net Deck %@"), version];
    self.navigationController.navigationBar.topItem.title = title;
    
    UINavigationItem* topItem = self.navigationController.navigationBar.topItem;
    topItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Feedback" style:UIBarButtonItemStyleBordered target:self action:@selector(leaveFeedback:)];
}

-(void) leaveFeedback:(id)sender
{
    /*
    if (self.popup)
    {
        [self.popup dismissWithClickedButtonIndex:self.popup.cancelButtonIndex animated:NO];
        self.popup = nil;
    }
    else
    {
        self.popup = [[UIActionSheet alloc] initWithTitle:l10n(@"How do you feel about Net Deck?")
                                                 delegate:self
                                        cancelButtonTitle:@""
                                   destructiveButtonTitle:nil
                                        otherButtonTitles:l10n(@"Happy"), l10n(@"Confused"), l10n(@"Unhappy"), nil];
        
        [self.popup showFromBarButtonItem:sender animated:NO];
    }
    */
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:nil
                                                    message:l10n(@"We'd love to know how we can make Net Deck even better - and would really appreciate if you left a review on the App Store.")
                                                   delegate:self
                                          cancelButtonTitle:l10n(@"Cancel")
                                          otherButtonTitles:l10n(@"Write a Review"), l10n(@"Contact Developers"), nil];
    [alert show];
}

#pragma mark action sheet

/*
-(void) actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    NSString *msg, *btn1, *btn2, *btn3;
    
    self.popup = nil;
    if (buttonIndex == actionSheet.cancelButtonIndex)
    {
        return;
    }
    
    switch (buttonIndex)
    {
        case 0: // happy
            msg = l10n(@"We'd love to know how we can make Net Deck even better - and would really appreciate if you left a review on the App Store.");
            btn1 = l10n(@"Write a Review");
            btn2 = l10n(@"Contact Developers");
            // btn3 = l10n(@"Tell your Friends");
            break;
        case 1: // confused
            msg = l10n(@"If you're unsure about how to use Net Deck, why not contact the developers?");
            btn1 = l10n(@"Contact");
            break;
        case 2: // unhappy
            msg = l10n(@"Go die in a fire.");
            btn1 = l10n(@"Contact");
            break;
    }
    
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:nil
                                                    message:msg
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                         otherButtonTitles:btn1, btn2, btn3, nil];
    alert.tag = buttonIndex;
    [alert show];
}
*/

#pragma mark alert view

-(void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex)
    {
        case 1:
            [self rateApp];
            break;
        case 2:
            [self sendEmail];
            break;
    }
}

-(void) rateApp
{
    self.storeViewController = [[SKStoreProductViewController alloc] init];
    
    NSNumber *appId = @(865963530);
    
    [self.storeViewController loadProductWithParameters:@{SKStoreProductParameterITunesItemIdentifier:appId} completionBlock:nil];
    self.storeViewController.delegate = self;
    
    [self presentViewController:self.storeViewController animated:NO completion:nil];
}

-(void) sendEmail
{
    self.mailer = [[MFMailComposeViewController alloc] init];
    
    self.mailer.mailComposeDelegate = self;
    [self.mailer setToRecipients:@[ @"netdeck@steffens.org" ]];
    [self.mailer setSubject:l10n(@"Net Deck Feedback")];
    [self presentViewController:self.mailer animated:NO completion:nil];
}

#pragma mark store kit

- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController
{
    [self.storeViewController dismissViewControllerAnimated:NO completion:nil];
    self.storeViewController = nil;
}

#pragma mark mail compose

-(void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    [self.mailer dismissViewControllerAnimated:NO completion:nil];
    self.mailer = nil;
}

#pragma mark webview
-(BOOL) webView:(UIWebView *)inWeb shouldStartLoadWithRequest:(NSURLRequest *)inRequest navigationType:(UIWebViewNavigationType)inType
{
    if (inType == UIWebViewNavigationTypeLinkClicked)
    {
        NSString* scheme = [inRequest URL].scheme;
        if ([scheme isEqualToString:@"mailto"])
        {
            [self sendEmail];
        }
        else if ([scheme isEqualToString:@"itms-apps"])
        {
            [self rateApp];
        }
        else
        {
            [[UIApplication sharedApplication] openURL:[inRequest URL]];
        }
        return NO;
    }
    
    return YES;
}

@end
