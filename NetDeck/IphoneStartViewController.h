//
//  IphoneStartViewController.h
//  Net Deck
//
//  Created by Gereon Steffens on 09.08.15.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

@import DZNEmptyDataSet;

@interface IphoneStartViewController : UINavigationController<UITableViewDataSource, UITableViewDelegate, UINavigationControllerDelegate, UISearchBarDelegate, DZNEmptyDataSetDelegate, DZNEmptyDataSetSource>

@property IBOutlet UITableViewController* tableViewController;
@property IBOutlet UITableView* tableView;

@property IBOutlet UIButton* titleButton;

@property IBOutlet UISearchBar* searchBar;

-(IBAction)titleButtonTapped:(id)sender;

// support for 3d touch shortcuts
-(void) addNewDeck:(NSInteger)role; // actually NRRole
-(void) openBrowser;

@end
