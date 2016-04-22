//
//  DeckListViewController.h
//  Net Deck
//
//  Created by Gereon Steffens on 08.12.13.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

#import "DetailViewManager.h"
#import "DecklistCollectionView.h"

@interface DeckListViewController : UIViewController <SubstitutableDetailViewController, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIPrintInteractionControllerDelegate>

@property IBOutlet UITableView* tableView;
@property IBOutlet DecklistCollectionView* collectionView;

@property IBOutlet UILabel* footerLabel;
@property IBOutlet UILabel* deckNameLabel;
@property IBOutlet UILabel* lastSetLabel;

@property IBOutlet UIToolbar* toolBar;
@property IBOutlet UIButton* drawButton;
@property IBOutlet UIButton* analysisButton;
@property IBOutlet UIButton* notesButton;
@property IBOutlet UIButton* historyButton;

@property IBOutlet NSLayoutConstraint *toolbarBottomMargin;

@property NRRole role;
@property (nonatomic) Deck* deck;

-(void) addCard:(Card*)card;
-(void) loadDeckFromFile:(NSString*) filename;
-(void) selectIdentity:(id)sender;

-(IBAction)analysisClicked:(id)sender;
-(IBAction)drawSimulatorClicked:(id)sender;
-(IBAction)notesButtonClicked:(id)sender;
-(IBAction)historyButtonClicked:(id)sender;

@end
