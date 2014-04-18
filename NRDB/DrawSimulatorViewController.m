//
//  DrawSimulatorViewController.m
//  NRDB
//
//  Created by Gereon Steffens on 15.02.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "DrawSimulatorViewController.h"
#import "Deck.h"
#import "CardImageViewPopover.h"
#import "Hypergeometric.h"

@interface DrawSimulatorViewController ()
@property Deck* deck;
@property NSMutableArray* cards;
@property NSMutableArray* draw;
@end

@implementation DrawSimulatorViewController

+(void) showForDeck:(Deck*)deck inViewController:(UIViewController*)vc
{
    DrawSimulatorViewController* davc = [[DrawSimulatorViewController alloc] initWithDeck:deck];
    
    [vc presentViewController:davc animated:NO completion:nil];
}

- (id)initWithDeck:(Deck*)deck
{
    TF_CHECKPOINT(@"draw simulator");
    
    self = [super initWithNibName:@"DrawSimulatorViewController" bundle:nil];
    if (self)
    {
        self.deck = deck;
        self.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initCards:YES];
    
    self.titleLabel.text = l10n(@"Draw Simulator");
    [self.clearButton setTitle:l10n(@"Clear") forState:UIControlStateNormal];
    [self.doneButton setTitle:l10n(@"Done") forState:UIControlStateNormal];
    
    [self.selector setTitle:l10n(@"All") forSegmentAtIndex:6];
    self.selector.apportionsSegmentWidthsByContent = YES;
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
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
    
    // shuffle the cards using Fisher-Yates
    u_int32_t count = (u_int32_t)self.cards.count;
    for (int i = 0; i < count; ++i)
    {
        // Select a random element between i and end of array to swap with.
        u_int32_t n = arc4random_uniform(count - i) + i;
        [self.cards exchangeObjectAtIndex:i withObjectAtIndex:n];
    }
    
    self.oddsLabel.text = @"";
    self.drawnLabel.text = @"";
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

-(void) done:(id)sender
{
    [self dismissViewControllerAnimated:NO completion:nil];
}

-(void) clear:(id)sender
{
    [self initCards:NO];
    [self.tableView reloadData];
}

-(void) draw:(UISegmentedControl*)sender
{
    // segments are: 0=1, 1=2, 2=3, 3=4, 4=5, 5=9, 6=All
    NSInteger numCards;
    switch (sender.selectedSegmentIndex)
    {
        case 5:
            numCards = 9;
            break;
        case 6:
            numCards = self.deck.size;
            break;
        default:
            numCards = sender.selectedSegmentIndex + 1;
            break;
    }
    
    [self drawCards:numCards];
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
    
    NSUInteger drawn = self.draw.count;
    self.drawnLabel.text = [NSString stringWithFormat:l10n(@"%ld %@ drawn"), (unsigned long)drawn, drawn == 1 ? l10n(@"Card") : l10n(@"Cards") ];
    
    [self.tableView reloadData];
    
    // scroll down if not all cards were drawn
    if (numCards != self.deck.size && self.draw.count > 0)
    {
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:self.draw.count-1 inSection:0];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
    }
    
    // calculate drawing odds
    NSString* odds = [NSString localizedStringWithFormat:l10n(@"Odds to draw a card: 1×%.1f%%  2×%.1f%%  3×%.1f%%"),
                      [self oddsFor:1], [self oddsFor:2], [self oddsFor:3] ];
    self.oddsLabel.text = odds;
}

-(double) oddsFor:(int)cardsInDeck
{
    return 100.0 * [Hypergeometric getProbabilityFor:1 cardsInDeck:self.deck.size desiredCardsInDeck:cardsInDeck cardsDrawn:self.draw.count];
}

#pragma mark tableview

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
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
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        UIButton* button = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        button.frame = CGRectMake(470, 5, 30, 30);
        cell.accessoryView = button;
        
        [button addTarget:self action:@selector(showImage:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    Card* card = [self.draw objectAtIndex:indexPath.row];
    cell.textLabel.text = card.name;
    
    return cell;
}

#pragma mark card popup

-(void) showImage:(UIButton*)sender
{
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    
    Card *card = [self.draw objectAtIndex:indexPath.row];
    
    CGRect rect = sender.frame;
    rect.origin.y = [self.tableView rectForRowAtIndexPath:indexPath].origin.y + 3;

    [CardImageViewPopover showForCard:card fromRect:rect inView:self.tableView];
}


@end
