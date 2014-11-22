//
//  CardCell.m
//  NRDB
//
//  Created by Gereon Steffens on 27.01.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "CardCell.h"
#import "CardCounter.h"
#import "Deck.h"
#import "Notifications.h"
#import "DeckListViewController.h"

@implementation CardCell

-(void) copiesChanged:(UIStepper*)sender
{
    int copies = sender.value;
    int diff = ABS((int)self.cardCounter.count - copies);
    if (copies < self.cardCounter.count)
    {
        [self.deck removeCard:self.cardCounter.card copies:diff];
    }
    else
    {
        [self.deck addCard:self.cardCounter.card copies:diff];
    }
    self.cardCounter.count = copies;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:DECK_CHANGED object:self];
}

-(void) awakeFromNib
{
    [self.identityButton setTitle:l10n(@"Switch Identity") forState:UIControlStateNormal];
}

-(void) selectIdentity:(id)sender
{
    [self.delegate selectIdentity:sender];
}

@end
