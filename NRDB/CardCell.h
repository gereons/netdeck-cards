//
//  CardCell.h
//  NRDB
//
//  Created by Gereon Steffens on 27.01.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Deck, CardCounter, DeckListViewController;

@interface CardCell : UITableViewCell {
    @protected
    CardCounter* _cardCounter;
}

@property Deck* deck;
@property (weak) DeckListViewController* delegate;

@property (nonatomic) CardCounter* cardCounter;
@property IBOutlet UIButton* identityButton;

-(IBAction)selectIdentity:(id)sender;

-(IBAction)copiesChanged:(id)sender;

@end
