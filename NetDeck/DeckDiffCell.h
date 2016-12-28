//
//  DeckDiffCell.h
//  Net Deck
//
//  Created by Gereon Steffens on 13.07.14.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

@class xDeckDiffViewController;

@interface xDeckDiffCell : UITableViewCell

@property (weak) xDeckDiffViewController* vc;
@property Card* card1;
@property Card* card2;

@property IBOutlet UILabel* deck1Card;
@property IBOutlet UILabel* deck2Card;
@property IBOutlet UILabel* diff;

@end
