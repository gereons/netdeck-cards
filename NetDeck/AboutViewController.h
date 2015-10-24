//
//  AboutViewController.h
//  Net Deck
//
//  Created by Gereon Steffens on 25.03.13.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

#import "DetailViewManager.h"
#import <MessageUI/MessageUI.h>

@interface AboutViewController : UIViewController<SubstitutableDetailViewController, UIWebViewDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) IBOutlet UIWebView* webView;

@end
