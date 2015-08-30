//
//  DrawSimulatorViewController.h
//  Net Deck
//
//  Created by Gereon Steffens on 15.02.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "DrawSimulatorCollectionView.h"

@class Deck;

@interface DrawSimulatorViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property IBOutlet UISegmentedControl* viewModeControl;
@property IBOutlet UILabel* titleLabel;
@property IBOutlet UITableView* tableView;
@property IBOutlet DrawSimulatorCollectionView* collectionView;
@property IBOutlet UILabel* drawnLabel;
@property IBOutlet UILabel* oddsLabel;

@property IBOutlet UIButton* clearButton;
@property IBOutlet UIButton* doneButton;
@property IBOutlet UISegmentedControl* selector;

-(IBAction)done:(id)sender;
-(IBAction)clear:(id)sender;
-(IBAction)draw:(id)sender;
-(IBAction)viewModeChange:(id)sender;

+(void) showForDeck:(Deck*)deck inViewController:(UIViewController*)vc;
@end
