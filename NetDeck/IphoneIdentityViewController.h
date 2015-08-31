//
//  IphoneIdentityViewController.h
//  Net Deck
//
//  Created by Gereon Steffens on 18.08.15.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

@class Deck;

@interface IphoneIdentityViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>

@property IBOutlet UITableView* tableView;
@property IBOutlet UIBarButtonItem* okButton;

-(IBAction)okClicked:(id)sender;

@property NRRole role;
@property Deck* deck;

@end
