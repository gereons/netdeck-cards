//
//  DecksViewController.h
//  NRDB
//
//  Created by Gereon Steffens on 13.04.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@class Deck, NRActionSheet;

@interface DecksViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, MFMailComposeViewControllerDelegate, UITextFieldDelegate>

@property IBOutlet UITableView* tableView;
@property IBOutlet UISearchBar* searchBar;

@property UIBarButtonItem* stateFilterButton;
@property UIBarButtonItem* sideFilterButton;
@property UIBarButtonItem* sortButton;

@property NRActionSheet* popup;
@property NSArray* decks;
@property Deck* deck;

@property NRFilterType filterType;

-(void) updateDecks;

@end
