//
//  EditDeckViewController.h
//  NRDB
//
//  Created by Gereon Steffens on 09.08.15.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

@class Deck;

@interface EditDeckViewController : UIViewController<UITableViewDelegate, UITableViewDataSource>

@property IBOutlet UITableView* tableView;
@property IBOutlet UILabel* statusLabel;
@property IBOutlet UIBarButtonItem* drawButton;
@property IBOutlet UIBarButtonItem* saveButton;

@property Deck* deck;

-(IBAction)drawClicked:(id)sender;
-(IBAction)saveClicked:(id)sender;

@end
