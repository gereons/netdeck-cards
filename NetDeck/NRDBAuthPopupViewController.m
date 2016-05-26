//
//  NRDBAuthPopupViewController.m
//  Net Deck
//
//  Created by Gereon Steffens on 05.07.14.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

#import "NRDBAuthPopupViewController.h"

@interface NRDBAuthPopupViewController ()

@property UINavigationController* navController;

@end

@implementation NRDBAuthPopupViewController

static NRDBAuthPopupViewController* popup;

+(void) showInViewController:(UIViewController*)vc
{
    NSAssert(Device.isIpad, @"ipad only");
    popup = [[NRDBAuthPopupViewController alloc] initWithNibName:@"NRDBAuthPopupViewController" bundle:nil];
    
    [vc presentViewController:popup animated:NO completion:nil];
    popup.preferredContentSize = CGSizeMake(850, 466);
}

+(void) pushOn:(UINavigationController *)navController
{
    NSAssert(Device.isIphone, @"iphone only");
    popup = [[NRDBAuthPopupViewController alloc] initWithNibName:@"NRDBAuthPopupViewController" bundle:nil];
    popup.navController = navController;
    
    [navController pushViewController:popup animated:YES];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self && Device.isIpad)
    {
        self.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.webView.delegate = self;
    self.webView.dataDetectorTypes = UIDataDetectorTypeNone;
    
    // NSLog(@"%@", @CODE_URL);
    NSURL* url= [NSURL URLWithString:NRDB.AUTH_URL];
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [self.cancelButton setTitle:l10n(@"Cancel") forState:UIControlStateNormal];
}

#pragma mark buttons

-(void) cancel:(id)sender
{
    [NRDB clearSettings];
    [self dismiss];
}

-(void) dismiss
{
    // NSLog(@"nrdb popup dismiss");
    if (self.navController)
    {
        NSAssert(Device.isIphone, @"not on iphone");
        [self.navController popViewControllerAnimated:YES];
        self.navController = nil;
    }
    else
    {
        NSAssert(Device.isIpad, @"not on ipad");
        [self dismissViewControllerAnimated:NO completion:nil];
    }
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    popup = nil;
}

#pragma mark url handler 

+(void) handleOpenURL:(NSURL *)url
{
    if (!popup)
    {
        return;
    }
    
    // NSLog(@"netdeck url %@", url);
    BOOL codeFound = NO;
    
    NSString* query = [url query];
    NSArray* params = [query componentsSeparatedByString:@"&"];
    for (NSString* param in params)
    {
        NSArray* kv = [param componentsSeparatedByString:@"="];
        NSString* key = kv[0];
        if ([key isEqualToString:@"code"])
        {
            NSString* code = kv[1];
            codeFound = YES;
            [[NRDB sharedInstance] authorizeWithCode:code completion:^(BOOL ok) {
                [popup dismiss];
                [[NRDB sharedInstance] startAuthorizationRefresh];
            }];
            break;
        }
    }
    
    if (!codeFound)
    {
        [popup cancel:nil];
    }
}

#pragma mark webview

-(void) webViewDidFinishLoad:(UIWebView *)webView
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self.activityIndicator stopAnimating];
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    [self.webView endEditing:YES];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [self.activityIndicator startAnimating];

    return YES;
}

- (BOOL)disablesAutomaticKeyboardDismissal
{
    return NO;
}

@end
