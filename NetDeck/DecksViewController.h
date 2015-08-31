//
//  DecksViewController.h
//  Net Deck
//
//  Created by Gereon Steffens on 13.04.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

@class Card, Deck;

@interface DecksViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UITextFieldDelegate>

@property IBOutlet UITableView* tableView;
@property IBOutlet UISearchBar* searchBar;

@property UIBarButtonItem* stateFilterButton;
@property UIBarButtonItem* sideFilterButton;
@property UIBarButtonItem* sortButton;

@property UIAlertController* popup;
@property NSArray* decks;

@property NRFilter filterType;

-(id) initWithCardFilter:(Card*)card;

-(void) updateDecks;

@end
