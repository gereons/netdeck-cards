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
    [self initCards];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

-(void) initCards
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
    
    self.drawnLabel.text = @"";
}

-(void) done:(id)sender
{
    [self dismissViewControllerAnimated:NO completion:nil];
}

-(void) clear:(id)sender
{
    [self initCards];
    [self.tableView reloadData];
}

-(void) draw:(UISegmentedControl*)sender
{
    NSInteger numCards = sender.selectedSegmentIndex + 1;
    BOOL scrollDown = YES;
    if (numCards == 6)
    {
        numCards = 9;
    }
    else if (numCards == 7)
    {
        numCards = self.deck.size;
        scrollDown = NO;
    }
    
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
    self.drawnLabel.text = [NSString stringWithFormat:@"%ld %@ drawn", (unsigned long)drawn, drawn == 1 ? @"Card" : @"Cards" ];
    
    [self.tableView reloadData];
    if (scrollDown)
    {
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:self.draw.count-1 inSection:0];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
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
        [cell.contentView addSubview:button];
        
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
