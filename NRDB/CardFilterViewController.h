//
//  CardFilterViewController.h
//  NRDB
//
//  Created by Gereon Steffens on 30.05.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Deck, DeckListViewController;

@interface CardFilterViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UICollectionViewDelegateFlowLayout>

@property DeckListViewController* deckListViewController;

@property IBOutlet UITextField* searchField;
@property IBOutlet UIButton* scopeButton;

@property IBOutlet UISlider* costSlider;
@property IBOutlet UILabel* costLabel;

@property IBOutlet UISlider* strengthSlider;
@property IBOutlet UILabel* strengthLabel;

@property IBOutlet UILabel* muLabel;
@property IBOutlet UISlider* muSlider;

@property IBOutlet UILabel* apLabel;
@property IBOutlet UISlider* apSlider;

@property IBOutlet UISlider* influenceSlider;
@property IBOutlet UILabel* influenceLabel;

@property IBOutlet UIButton* typeButton;
@property IBOutlet UIButton* subtypeButton;
@property IBOutlet UIButton* factionButton;
@property IBOutlet UIButton* setButton;

@property IBOutlet UIButton* moreLessButton;
@property IBOutlet UISegmentedControl* viewMode;

@property IBOutlet UIView* searchContainer;
@property IBOutlet UIView* searchSeparator; // the 1px "line" view beneath the search box
@property IBOutlet UIView* sliderContainer;
@property IBOutlet UIView* sliderSeparator; // the 1px "line" view beneath the sliders box
@property IBOutlet UIView* influenceSeparator; // the 1px "line" view beneath the influence slider
@property IBOutlet UIView* buttonContainer;
@property IBOutlet UIView* bottomSeparator; // the 1px "line" view between the filters and the results table

@property IBOutlet UITableView* tableView;
@property IBOutlet UICollectionView* collectionView;

-(IBAction)strengthValueChanged:(id)sender;
-(IBAction)costValueChanged:(id)sender;
-(IBAction)muValueChanged:(id)sender;
-(IBAction)apValueChanged:(id)sender;
-(IBAction)influenceValueChanged:(id)sender;

-(IBAction)typeClicked:(id)sender;
-(IBAction)subtypeClicked:(id)sender;
-(IBAction)factionClicked:(id)sender;
-(IBAction)setClicked:(id)sender;

-(IBAction)moreLessClicked:(id)sender;
-(IBAction)scopeClicked:(id)sender;
-(IBAction)viewModeChanged:(id)sender;

-(id) initWithRole:(NRRole)role;
-(id) initWithRole:(NRRole)role andFile:(NSString*) filename;
-(id) initWithRole:(NRRole)role andDeck:(Deck*) deck;

-(void) filterCallback:(UIButton*)button value:(NSObject*)value;

@end
