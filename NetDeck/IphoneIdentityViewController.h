//
//  IphoneIdentityViewController.h
//  Net Deck
//
//  Created by Gereon Steffens on 18.08.15.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

@interface IphoneIdentityViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>

@property IBOutlet UITableView* tableView;
@property IBOutlet UIBarButtonItem* okButton;
@property IBOutlet UIBarButtonItem* cancelButton;

@property IBOutlet UIToolbar* toolbar;

-(IBAction)okClicked:(id)sender;
-(IBAction)cancelClicked:(id)sender;

@property NSInteger role; // actually NRRole
@property Deck* deck;

@end
