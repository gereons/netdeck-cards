//
//  DeckListViewController.h
//  NRDB
//
//  Created by Gereon Steffens on 08.12.13.
//  Copyright (c) 2013 Gereon Steffens. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DetailViewManager.h"

@class Card, Deck;

@interface DeckListViewController : UIViewController <SubstitutableDetailViewController, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UIAlertViewDelegate, UIActionSheetDelegate, UIPrintInteractionControllerDelegate, UITextFieldDelegate>

@property (strong) IBOutlet UITableView* tableView;
@property (strong) IBOutlet UICollectionView* collectionView;

@property (strong) IBOutlet UIToolbar* toolBar;
@property (strong) IBOutlet UILabel* footerLabel;
@property (strong) IBOutlet UILabel* deckNameLabel;

@property BOOL deckChanged;
@property NRRole role;
@property (strong) Deck* deck;

-(void) addCard:(Card*)card;
-(void) loadDeckFromFile:(NSString*) filename;
-(void) saveDeck:(id)sender;

-(IBAction)analysisClicked:(id)sender;

@end
