//
//  DeckHistoryPopup.h
//  Net Deck
//
//  Created by Gereon Steffens on 23.11.14.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

@interface DeckHistoryPopup : UIViewController<UITableViewDelegate, UITableViewDataSource>

@property IBOutlet UILabel* titleLabel;
@property IBOutlet UIButton* closeButton;
@property IBOutlet UITableView* tableView;

+(void) showForDeck:(Deck*)deck inViewController:(UIViewController*)vc;

-(IBAction)closeButtonClicked:(id)sender;

@end
