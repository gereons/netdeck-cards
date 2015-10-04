//
//  IphoneStartViewController.h
//  Net Deck
//
//  Created by Gereon Steffens on 09.08.15.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

#import "NRNavigationController.h"

@interface IphoneStartViewController : NRNavigationController<UITableViewDataSource, UITableViewDelegate, UINavigationControllerDelegate, UISearchBarDelegate>

@property IBOutlet UITableViewController* tableViewController;
@property IBOutlet UITableView* tableView;

@property IBOutlet UIButton* titleButton;

@property IBOutlet UISearchBar* searchBar;

-(IBAction)createNewDeck:(id)sender;
-(IBAction)openSettings:(id)sender;
-(IBAction)titleButtonTapped:(id)sender;

@end
