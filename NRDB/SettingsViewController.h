//
//  SettingsViewController.h
//  NRDB
//
//  Created by Gereon Steffens on 27.03.13.
//  Copyright (c) 2013 Gereon Steffens. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DetailViewManager.h"
#import "IASKAppSettingsViewController.h"

@interface SettingsViewController : UIViewController<IASKSettingsDelegate, SubstitutableDetailViewController, UIAlertViewDelegate>

+(void) downloadData:(void (^)())block;

@end
