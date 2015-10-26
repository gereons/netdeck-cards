//
//  EditDeckViewController.h
//  Net Deck
//
//  Created by Gereon Steffens on 09.08.15.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

#import "NRDeckEditor.h"

@class Deck;

@interface EditDeckViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, NRDeckEditor>

@property IBOutlet UITableView* tableView;
@property IBOutlet UILabel* statusLabel;
@property IBOutlet UIToolbar* toolBar;

@property IBOutlet UIBarButtonItem* drawButton;
@property IBOutlet UIBarButtonItem* nrdbButton;
@property IBOutlet UIBarButtonItem* addButton;

@property Deck* deck;

-(IBAction)drawClicked:(id)sender;
-(IBAction)nrdbButtonClicked:(id)sender;
-(IBAction)showCardList:(id)sender;

@end
