//
//  NRDBAuthPopupViewController.m
//  NRDB
//
//  Created by Gereon Steffens on 05.07.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "NRDBAuthPopupViewController.h"
#import "NRDBAuth.h"
#import "NRDB.h"
#import "SettingsKeys.h"

@interface NRDBAuthPopupViewController ()

@end

@implementation NRDBAuthPopupViewController

static NRDBAuthPopupViewController* popup;

+(void) showInViewController:(UIViewController*)vc
{
    popup = [[NRDBAuthPopupViewController alloc] initWithNibName:@"NRDBAuthPopupViewController" bundle:nil];
    
    [vc presentViewController:popup animated:NO completion:nil];
    popup.view.superview.bounds = CGRectMake(0, 0, 800, 478);
}

+(void) handleOpenURL:(NSURL *)url
{
    if (!popup)
    {
        return;
    }
    
    NSLog(@"netdeck url %@", url);
    
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
                [popup cancel:nil];
            }];
            break;
        }
    }
    
    if (!codeFound)
    {
        NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
        [settings removeObjectForKey:NRDB_REFRESH_TOKEN];
        [settings removeObjectForKey:NRDB_ACCESS_TOKEN];
        [settings setObject:@(NO) forKey:USE_NRDB];
        
        [popup cancel:nil];
    }
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
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
    NSURL* url= [NSURL URLWithString:@CODE_URL];
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

-(void) cancel:(id)sender
{
    [self dismissViewControllerAnimated:NO completion:nil];
    popup = nil;
}

#pragma mark webview

-(void) webViewDidFinishLoad:(UIWebView *)webView
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self.activityIndicator stopAnimating];
}

@end
