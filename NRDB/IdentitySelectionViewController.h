//
//  IdentitySelectionViewController.h
//  NRDB
//
//  Created by Gereon Steffens on 26.12.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Card;

@interface IdentitySelectionViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

+(void) showForRole:(NRRole)role inViewController:(UIViewController*)vc withIdentity:(Card*)card;

@property IBOutlet UITableView* tableView;
@property IBOutlet UIButton* okButton;
@property IBOutlet UIButton* cancelButton;

-(IBAction)okClicked:(id)sender;
-(IBAction)cancelClicked:(id)sender;

@end
