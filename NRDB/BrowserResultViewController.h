//
//  BrowserResultViewController.h
//  NRDB
//
//  Created by Gereon Steffens on 03.08.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DetailViewManager.h"

@class CardList;

@interface BrowserResultViewController : UIViewController <SubstitutableDetailViewController, UITabBarControllerDelegate, UITableViewDataSource>

@property IBOutlet UITableView* tableView;

-(void)updateDisplay:(CardList*)cardList;

@end
