//
//  IphoneStartViewController.h
//  NRDB
//
//  Created by Gereon Steffens on 09.08.15.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

#import "NRNavigationController.h"

@interface IphoneStartViewController : NRNavigationController<UITableViewDataSource, UITableViewDelegate, UINavigationControllerDelegate>

@property IBOutlet UITableViewController* tableViewController;
@property IBOutlet UITableView* tableView;

-(IBAction)createNewDeck:(id)sender;
-(IBAction)openSettings:(id)sender;

@end
