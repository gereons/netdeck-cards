//
//  ListCardsViewController.h
//  NRDB
//
//  Created by Gereon Steffens on 10.08.15.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

@class Deck;

@interface ListCardsViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>

@property IBOutlet UITableView* tableView;
@property IBOutlet UISearchBar* searchBar;

@property Deck* deck;

@end
