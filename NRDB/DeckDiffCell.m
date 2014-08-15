//
//  DeckDiffCell.m
//  NRDB
//
//  Created by Gereon Steffens on 13.07.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "DeckDiffCell.h"
#import "CardImageViewPopover.h"

@implementation DeckDiffCell

- (void)awakeFromNib
{
    UITapGestureRecognizer* tap1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(popupCard1:)];
    [self.deck1Card addGestureRecognizer:tap1];
    self.deck1Card.userInteractionEnabled = YES;
    
    UITapGestureRecognizer* tap2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(popupCard2:)];
    [self.deck2Card addGestureRecognizer:tap2];
    self.deck2Card.userInteractionEnabled = YES;
}

-(void) popupCard1:(UITapGestureRecognizer*)sender
{
    if (self.card1)
    {
        NSIndexPath* idx = [self.tableView indexPathForRowAtPoint:[sender locationInView:self.tableView]];
        CGRect rect = [self.tableView rectForRowAtIndexPath:idx];
        rect.size.width = 330;
        [CardImageViewPopover showForCard:self.card1 fromRect:rect inView:self.tableView];
    }
}

-(void) popupCard2:(id)sender
{
    if (self.card2)
    {
        NSIndexPath* idx = [self.tableView indexPathForRowAtPoint:[sender locationInView:self.tableView]];
        CGRect rect = [self.tableView rectForRowAtIndexPath:idx];
        rect.origin.x = 400;
        rect.size.width = 310;
        [CardImageViewPopover showForCard:self.card2 fromRect:rect inView:self.tableView];
    }
}

@end
