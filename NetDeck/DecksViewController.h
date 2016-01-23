//
//  DecksViewController.h
//  Net Deck
//
//  Created by Gereon Steffens on 13.04.14.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

@interface DecksViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UITextFieldDelegate>

@property IBOutlet UITableView* tableView;
@property IBOutlet UISearchBar* searchBar;

@property UIBarButtonItem* stateFilterButton;
@property UIBarButtonItem* sideFilterButton;
@property UIBarButtonItem* sortButton;

@property UIAlertController* popup;
@property NSArray<NSMutableArray<Deck*>*>* decks;

@property NRFilter filterType;

-(id) initWithCardFilter:(Card*)card;

-(void) updateDecks;

@end
