//
//  ListCardsViewController.h
//  Net Deck
//
//  Created by Gereon Steffens on 10.08.15.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

@interface ListCardsViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>

@property IBOutlet UITableView* tableView;
@property IBOutlet UISearchBar* searchBar;

@property IBOutlet UILabel* statusLabel;
@property IBOutlet UIToolbar* toolBar;

@property Deck* deck;

@end
