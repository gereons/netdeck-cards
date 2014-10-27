//
//  DeckDiffViewController.h
//  NRDB
//
//  Created by Gereon Steffens on 13.07.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

@class Deck;

@interface DeckDiffViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>

@property IBOutlet UILabel* titleLabel;
@property IBOutlet UILabel* deck1Name;
@property IBOutlet UILabel* deck2Name;

@property IBOutlet UITableView* tableView;
@property IBOutlet UIButton* closeButton;
@property IBOutlet UIButton* reverseButton;
@property IBOutlet UISegmentedControl* diffModeControl;

-(IBAction)close:(id)sender;
-(IBAction)reverse:(id)sender;
-(IBAction)diffMode:(id)sender;

+(void) showForDecks:(Deck*)deck1 deck2:(Deck*)deck2 inViewController:(UIViewController*)vc;

@end
