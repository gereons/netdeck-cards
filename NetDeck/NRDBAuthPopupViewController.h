//
//  NRDBAuthPopupViewController.h
//  Net Deck
//
//  Created by Gereon Steffens on 05.07.14.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

@interface NRDBAuthPopupViewController : UIViewController <UIWebViewDelegate>

@property IBOutlet UIWebView* webView;
@property IBOutlet UIButton* cancelButton;
@property IBOutlet UIActivityIndicatorView* activityIndicator;

-(IBAction)cancel:(id)sender;

+(void) showInViewController:(UIViewController*)vc;
+(void) pushOn:(UINavigationController*)navController;
+(void) handleOpenURL:(NSURL*)url;

@end
