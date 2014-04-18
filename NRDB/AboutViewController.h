//
//  AboutViewController.h
//  NRDB
//
//  Created by Gereon Steffens on 25.03.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DetailViewManager.h"
#import <StoreKit/StoreKit.h>
#import <MessageUI/MessageUI.h>

@interface AboutViewController : UIViewController<SubstitutableDetailViewController, UIWebViewDelegate, UIActionSheetDelegate, SKStoreProductViewControllerDelegate, UIAlertViewDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) IBOutlet UIWebView* webView;

@end
