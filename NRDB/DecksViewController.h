//
//  DecksViewController.h
//  NRDB
//
//  Created by Gereon Steffens on 13.04.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DecksViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate, UISearchBarDelegate>

@property IBOutlet UITableView* tableView;
@property IBOutlet UISearchBar* searchBar;

@end
