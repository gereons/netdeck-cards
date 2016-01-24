//
//  DeckDiffCell.m
//  Net Deck
//
//  Created by Gereon Steffens on 13.07.14.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

#import "DeckDiffCell.h"
#import "DeckDiffViewController.h"
#import "CardImageViewPopover.h"

@implementation DeckDiffCell

- (void)awakeFromNib
{
    UITapGestureRecognizer* tap1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(popupCard1:)];
    [self.deck1Card addGestureRecognizer:tap1];
    self.deck1Card.userInteractionEnabled = YES;
    self.deck1Card.font = [UIFont md_systemFontOfSize:15];
    
    UITapGestureRecognizer* tap2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(popupCard2:)];
    [self.deck2Card addGestureRecognizer:tap2];
    self.deck2Card.userInteractionEnabled = YES;
    self.deck2Card.font = [UIFont md_systemFontOfSize:15];
}

-(void) popupCard1:(UITapGestureRecognizer*)sender
{
    if (self.card1)
    {
        UITableView* tableView = self.vc.tableView;
        NSIndexPath* idx = [tableView indexPathForRowAtPoint:[sender locationInView:tableView]];
        CGRect rect = [tableView rectForRowAtIndexPath:idx];
        rect.size.width = 330;
        [CardImageViewPopover showForCard:self.card1 fromRect:rect inViewController:self.vc subView:tableView];
    }
}

-(void) popupCard2:(id)sender
{
    if (self.card2)
    {
        UITableView* tableView = self.vc.tableView;
        NSIndexPath* idx = [tableView indexPathForRowAtPoint:[sender locationInView:tableView]];
        CGRect rect = [tableView rectForRowAtIndexPath:idx];
        rect.origin.x = 400;
        rect.size.width = 310;
        [CardImageViewPopover showForCard:self.card2 fromRect:rect inViewController:self.vc subView:tableView];
    }
}

@end
