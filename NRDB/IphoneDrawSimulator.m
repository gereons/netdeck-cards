//
//  IphoneDrawSimulator.m
//  NRDB
//
//  Created by Gereon Steffens on 23.08.15.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

#import "IphoneDrawSimulator.h"
#import "ImageCache.h"
#import "Deck.h"
#import "Hypergeometric.h"

@interface IphoneDrawSimulator ()

@property NSMutableArray* draw;
@property NSMutableArray* cards;

@end

@implementation IphoneDrawSimulator

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[ImageCache hexTile]];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.backgroundColor = [UIColor clearColor];
    
    self.title = l10n(@"Draw Simulator");
    
    [self.drawControl setTitle:l10n(@"All") forSegmentAtIndex:6];
    [self.drawControl setTitle:l10n(@"Clear") forSegmentAtIndex:7];
    
    [self initCards:YES];
}

-(void) drawValueChanged:(UISegmentedControl*)sender
{
    // segments are: 0=1, 1=2, 2=3, 3=4, 4=5, 5=9, 6=All, 7=Clear
    NSInteger numCards;
    switch (sender.selectedSegmentIndex)
    {
        case 5:
            numCards = 9;
            break;
        case 6:
            numCards = self.deck.size;
            break;
        case 7:
            [self initCards:NO];
            [self.tableView reloadData];
            return;
        default:
            numCards = sender.selectedSegmentIndex + 1;
            break;
    }
    
    [self drawCards:numCards];
}

-(void) initCards:(BOOL)drawInitialHand
{
    self.draw = [NSMutableArray array];
    self.cards = [NSMutableArray array];
    
    for (CardCounter* cc in self.deck.cards)
    {
        for (int c=0; c<cc.count; ++c)
        {
            [self.cards addObject:cc.card];
        }
    }
    NSAssert(self.cards.count == self.deck.size, @"size mismatch");
    
    // shuffle using Knuth-Fisher-Yates
    for (NSUInteger i = self.cards.count - 1; i; --i)
    {
        NSUInteger n = arc4random_uniform((u_int32_t)(i + 1));
        [self.cards exchangeObjectAtIndex:n withObjectAtIndex:i];
    }
    
    self.oddsLabel.text = @" ";

    if (drawInitialHand)
    {
        int handSize = 5;
        if ([self.deck.identity.code isEqualToString:ANDROMEDA])
        {
            handSize = 9;
        }
        [self drawCards:handSize];
    }
}

-(void) drawCards:(NSInteger)numCards
{
    for (int i=0; i<numCards; ++i)
    {
        if (self.cards.count > 0)
        {
            Card* card = [self.cards objectAtIndex:0];
            [self.cards removeObjectAtIndex:0];
            [self.draw addObject:card];
        }
    }
    
    [self.tableView reloadData];
    
    // scroll down if not all cards were drawn
    if (numCards != self.deck.size && self.draw.count > 0)
    {
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:self.draw.count-1 inSection:0];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
    }
    
    // calculate drawing odds
    NSString* odds = [NSString localizedStringWithFormat:l10n(@"Odds for a card: 1×%.1f%%  2×%.1f%%  3×%.1f%%"),
                      [self oddsFor:1], [self oddsFor:2], [self oddsFor:3] ];
    self.oddsLabel.text = odds;
}

-(double) oddsFor:(int)cardsInDeck
{
    return 100.0 * [Hypergeometric getProbabilityFor:1 cardsInDeck:self.deck.size desiredCardsInDeck:cardsInDeck cardsDrawn:self.draw.count];
}

#pragma mark - table view

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.draw.count;
}

-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* cellIdentifier = @"drawCell";
    
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    Card* card = self.draw[indexPath.row];
    cell.textLabel.text = card.name;
    
    return cell;
}

@end
