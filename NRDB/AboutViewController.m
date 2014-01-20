//
//  AboutViewController.m
//  NRDB
//
//  Created by Gereon Steffens on 25.03.13.
//  Copyright (c) 2013 Gereon Steffens. All rights reserved.
//

#import "AboutViewController.h"

@interface AboutViewController ()

@end

@implementation AboutViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationController.navigationBar.topItem.title = NSLocalizedString(@"About", nil);
    self.webView.delegate = self;
    
    self.webView.scrollView.bounces = NO;
    
    NSString* resource = NSLocalizedString(@"About", nil);
    
    NSURL* url= [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:resource ofType:@"html"] isDirectory:NO];
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
}

-(BOOL) webView:(UIWebView *)inWeb shouldStartLoadWithRequest:(NSURLRequest *)inRequest navigationType:(UIWebViewNavigationType)inType
{
    if (inType == UIWebViewNavigationTypeLinkClicked)
    {
        [[UIApplication sharedApplication] openURL:[inRequest URL]];
        return NO;
    }
    
    return YES;
}
@end
