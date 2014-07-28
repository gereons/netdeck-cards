//
//  IdentitySelectionViewController.h
//  NRDB
//
//  Created by Gereon Steffens on 26.12.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Card;

@interface IdentitySelectionViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource>

+(void) showForRole:(NRRole)role inViewController:(UIViewController*)vc withIdentity:(Card*)card;

@property IBOutlet UITableView* tableView;
@property IBOutlet UICollectionView* collectionView;
@property IBOutlet UIButton* okButton;
@property IBOutlet UIButton* cancelButton;
@property IBOutlet UILabel* titleLabel;

@property IBOutlet UISegmentedControl* modeSelector;
@property IBOutlet UISegmentedControl* factionSelector;

-(IBAction)okClicked:(id)sender;
-(IBAction)cancelClicked:(id)sender;
-(IBAction)viewModeChange:(id)sender;
-(IBAction)factionChange:(id)sender;

@end
