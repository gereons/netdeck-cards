//
//  ImportDecksViewController.h
//  Net Deck
//
//  Created by Gereon Steffens on 12.01.14.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

@interface xImportDecksViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>

@property IBOutlet UITableView* tableView;
@property IBOutlet UISearchBar* searchBar;

@property NSInteger source; // actually NRDeckImportSource

@end
