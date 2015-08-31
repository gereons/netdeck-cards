//
//  IdentitySelectionViewController.h
//  Net Deck
//
//  Created by Gereon Steffens on 26.12.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "IdentityCollectionView.h"

@class Card;

@interface IdentitySelectionViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

+(void) showForRole:(NRRole)role inViewController:(UIViewController*)vc withIdentity:(Card*)card;

@property IBOutlet UITableView* tableView;
@property IBOutlet IdentityCollectionView* collectionView;
@property IBOutlet UIButton* okButton;
@property IBOutlet UIButton* cancelButton;
@property IBOutlet UILabel* titleLabel;

@property IBOutlet UISegmentedControl* modeSelector;
@property IBOutlet UISegmentedControl* factionSelector;

@property IBOutlet NSLayoutConstraint* factionSelectorWidth;

-(IBAction)okClicked:(id)sender;
-(IBAction)cancelClicked:(id)sender;
-(IBAction)viewModeChange:(id)sender;
-(IBAction)factionChange:(id)sender;

@end
