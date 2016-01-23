//
//  IphoneStartViewController.h
//  Net Deck
//
//  Created by Gereon Steffens on 09.08.15.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

@interface IphoneStartViewController : UINavigationController<UITableViewDataSource, UITableViewDelegate, UINavigationControllerDelegate, UISearchBarDelegate>

@property IBOutlet UITableViewController* tableViewController;
@property IBOutlet UITableView* tableView;

@property IBOutlet UIButton* titleButton;

@property IBOutlet UISearchBar* searchBar;

-(IBAction)createNewDeck:(id)sender;
-(IBAction)openSettings:(id)sender;
-(IBAction)titleButtonTapped:(id)sender;

@end
