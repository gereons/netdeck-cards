//
//  CardCell.h
//  Net Deck
//
//  Created by Gereon Steffens on 27.01.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

@class Deck, CardCounter, DeckListViewController;

@interface CardCell : UITableViewCell

@property Deck* deck;
@property (weak) DeckListViewController* delegate;

@property (nonatomic) CardCounter* cardCounter;
@property IBOutlet UIButton* identityButton;

-(IBAction)selectIdentity:(id)sender;

-(IBAction)copiesChanged:(id)sender;

@end
