//
//  AboutViewController.m
//  Net Deck
//
//  Created by Gereon Steffens on 25.03.13.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

@import SDCAlertView;

#import "AboutViewController.h"
#import "AppDelegate.h"

@interface AboutViewController ()
@property MFMailComposeViewController *mailer;
@property UIBarButtonItem* backButton;
@end

@implementation AboutViewController

- (id)init
{
    return [self initWithNibName:@"AboutView" bundle:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
}

-(void) dealloc
{
    self.webView.delegate = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.topItem.title = l10n(@"About");
    
    self.backButton = [[UIBarButtonItem alloc] initWithTitle:@"◁" style:UIBarButtonItemStylePlain target:self action:@selector(goBack:)];
    
    self.webView.delegate = self;
    self.webView.dataDetectorTypes = UIDataDetectorTypeNone;
        
    NSURL* url= [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"About" ofType:@"html"] isDirectory:NO];
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    NSString* title = [NSString stringWithFormat:l10n(@"About Net Deck %@"), [AppDelegate appVersion]];
    if (IS_IPHONE)
    {
        title = [NSString stringWithFormat:l10n(@"Net Deck %@"), [AppDelegate appVersion]];
    }
    self.navigationController.navigationBar.topItem.title = title;
    
    UINavigationItem* topItem = self.navigationController.navigationBar.topItem;
    topItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Feedback" style:UIBarButtonItemStylePlain target:self action:@selector(leaveFeedback:)];
}

#pragma mark buttons

-(void) goBack:(id)sender
{
    [self.webView goBack];
    self.navigationController.navigationBar.topItem.leftBarButtonItem = nil;
}

-(void) leaveFeedback:(id)sender
{
    NSString* msg = l10n(@"We'd love to know how we can make Net Deck even better - and would really appreciate if you left a review on the App Store.");
    
    SDCAlertView* alert = [SDCAlertView alertWithTitle:nil
                                               message:msg
                                               buttons:@[l10n(@"Cancel"), l10n(@"Write a Review"), l10n(@"Contact Developers")]];
    alert.didDismissHandler = ^(NSInteger buttonIndex) {
        switch (buttonIndex)
        {
            case 1:
                [self rateApp];
                break;
            case 2:
                [self sendEmail];
                break;
        }
    };
}

-(void) rateApp
{
    NSString* appURL = [NSString stringWithFormat:@"itms-apps://itunes.apple.com/%@/app/id%@",
                        [[NSLocale preferredLanguages] objectAtIndex:0],
                        @"865963530"];
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:appURL]];
}

-(void) sendEmail
{
    self.mailer = [[MFMailComposeViewController alloc] init];
    
    if (self.mailer) // see crashlytics #57
    {
        self.mailer.mailComposeDelegate = self;
        [self.mailer setToRecipients:@[ @"netdeck@steffens.org" ]];
        NSMutableString* subject = [NSMutableString stringWithString:l10n(@"Net Deck Feedback ")];
        [subject appendString:[AppDelegate appVersion]];
        [self.mailer setSubject:subject];
        [self presentViewController:self.mailer animated:NO completion:nil];
    }
}

#pragma mark mail compose

-(void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    [self.mailer dismissViewControllerAnimated:NO completion:nil];
    self.mailer = nil;
}

#pragma mark webview

-(BOOL) webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)type
{
    if (type == UIWebViewNavigationTypeLinkClicked)
    {
        NSString* scheme = [request URL].scheme;
        if ([scheme isEqualToString:@"mailto"])
        {
            [self sendEmail];
        }
        else if ([scheme isEqualToString:@"itms-apps"])
        {
            [self rateApp];
        }
        else if ([scheme isEqualToString:@"file"])
        {
            NSString* path = [[NSBundle mainBundle] pathForResource:@"Acknowledgements" ofType:@"html"];
            
            NSURL* url = [NSURL fileURLWithPath:path isDirectory:NO];
            [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
            self.navigationController.navigationBar.topItem.leftBarButtonItem = self.backButton;
            return YES;
        }
        else
        {
            [[UIApplication sharedApplication] openURL:[request URL]];
        }
        return NO;
    }
    
    return YES;
}

@end
