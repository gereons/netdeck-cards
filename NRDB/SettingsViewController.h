//
//  SettingsViewController.h
//  NRDB
//
//  Created by Gereon Steffens on 27.03.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DetailViewManager.h"
#import "IASKAppSettingsViewController.h"

@interface SettingsViewController : UIViewController<IASKSettingsDelegate, SubstitutableDetailViewController>

@end
