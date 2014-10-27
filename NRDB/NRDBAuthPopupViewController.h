//
//  NRDBAuthPopupViewController.h
//  NRDB
//
//  Created by Gereon Steffens on 05.07.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

@interface NRDBAuthPopupViewController : UIViewController <UIWebViewDelegate>

@property IBOutlet UIWebView* webView;
@property IBOutlet UIButton* cancelButton;
@property IBOutlet UIActivityIndicatorView* activityIndicator;

-(IBAction)cancel:(id)sender;

+(void) showInViewController:(UIViewController*)vc;
+(void) handleOpenURL:(NSURL*)url;

@end
