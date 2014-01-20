//
//  AboutViewController.h
//  NRDB
//
//  Created by Gereon Steffens on 25.03.13.
//  Copyright (c) 2013 Gereon Steffens. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DetailViewManager.h"

@interface AboutViewController : UIViewController<SubstitutableDetailViewController, UIWebViewDelegate>

@property (nonatomic, strong) IBOutlet UIWebView* webView;

@end
