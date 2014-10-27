//
//  DeckDiffCell.h
//  NRDB
//
//  Created by Gereon Steffens on 13.07.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

@class Card;

@interface DeckDiffCell : UITableViewCell

@property (weak) UITableView* tableView;
@property Card* card1;
@property Card* card2;

@property IBOutlet UILabel* deck1Card;
@property IBOutlet UILabel* deck2Card;
@property IBOutlet UILabel* diff;

@end
