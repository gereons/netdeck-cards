//
//  DeckListViewController.h
//  NRDB
//
//  Created by Gereon Steffens on 08.12.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

#import "DetailViewManager.h"

@class Card, Deck;

@interface DeckListViewController : UIViewController <SubstitutableDetailViewController, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UIActionSheetDelegate, UIPrintInteractionControllerDelegate, UITextFieldDelegate, MFMailComposeViewControllerDelegate>

@property IBOutlet UITableView* tableView;
@property IBOutlet UICollectionView* collectionView;

@property IBOutlet UIToolbar* toolBar;
@property IBOutlet UILabel* footerLabel;
@property IBOutlet UILabel* deckNameLabel;
@property IBOutlet UILabel* lastSetLabel;
@property IBOutlet UIButton* drawButton;
@property IBOutlet UIButton* analysisButton;
@property IBOutlet UIButton* nrdbButton;

@property BOOL deckChanged;
@property NRRole role;
@property Deck* deck;

-(void) addCard:(Card*)card;
-(void) loadDeckFromFile:(NSString*) filename;
-(void) saveDeck:(id)sender;
-(void) selectIdentity:(id)sender;

-(IBAction)analysisClicked:(id)sender;
-(IBAction)drawSimulatorClicked:(id)sender;
-(IBAction)nrdbButtonClicked:(id)sender;

@end
