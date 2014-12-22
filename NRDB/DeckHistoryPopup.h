//
//  DeckHistoryPopup.h
//  NRDB
//
//  Created by Gereon Steffens on 23.11.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

@class Deck;

@interface DeckHistoryPopup : UIViewController<UITableViewDelegate, UITableViewDataSource>

@property IBOutlet UILabel* titleLabel;
@property IBOutlet UIButton* closeButton;
@property IBOutlet UITableView* tableView;

+(void) showForDeck:(Deck*)deck inViewController:(UIViewController*)vc;

-(IBAction)closeButtonClicked:(id)sender;

@end
