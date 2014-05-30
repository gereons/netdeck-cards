//
//  CardFilterViewController.h
//  NRDB
//
//  Created by Gereon Steffens on 30.05.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Deck, DeckListViewController;

@interface CardFilterViewController : UIViewController<UITableViewDataSource, UITableViewDelegate,UITextFieldDelegate>

@property DeckListViewController* deckListViewController;

@property IBOutlet UILabel* searchLabel;
@property IBOutlet UITextField* searchField;
@property IBOutlet UISegmentedControl* searchScope;

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

@property IBOutlet UIView* searchSeparator; // the 1px "line" view beneath the search box
@property IBOutlet UITableView* tableView;


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
-(IBAction)scopeValueChanged:(id)sender;
-(IBAction)viewModeChanged:(id)sender;

-(id) initWithRole:(NRRole)role;
-(id) initWithRole:(NRRole)role andFile:(NSString*) filename;
-(id) initWithRole:(NRRole)role andDeck:(Deck*) deck;

-(void) filterCallback:(UIButton*)button value:(NSObject*)value;

@end
