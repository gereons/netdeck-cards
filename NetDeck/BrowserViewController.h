//
//  BrowserViewController.h
//  NetDeck
//
//  Created by Gereon Steffens on 03.10.15.
//  Copyright © 2015 Gereon Steffens. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BrowserViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>

@property IBOutlet UITableView* tableView;
@property IBOutlet UISearchBar* searchBar;

@end
