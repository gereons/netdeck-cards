//
//  IphoneStartViewController.h
//  NRDB
//
//  Created by Gereon Steffens on 09.08.15.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IphoneStartViewController : UINavigationController<UITableViewDataSource, UITableViewDelegate>

@property IBOutlet UITableView* tableView;

-(IBAction)createNewDeck:(id)sender;

@end
