//
//  AboutViewController.h
//  Net Deck
//
//  Created by Gereon Steffens on 25.03.13.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

#import <MessageUI/MessageUI.h>

@interface AboutViewController : UIViewController<UIWebViewDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) IBOutlet UIWebView* webView;

@end
