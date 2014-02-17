//
//  DeckAnalysisViewController.m
//  NRDB
//
//  Created by Gereon Steffens on 10.02.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "DeckAnalysisViewController.h"
#import "CostStats.h"
#import "StrengthStats.h"
#import "IceTypeStats.h"
#import "CardTypeStats.h"
#import "InfluenceStats.h"
#import "Deck.h"
#import "CardSets.h"

@interface DeckAnalysisViewController ()

@property Deck* deck;
@property NSArray* errors;
@property CostStats* costStats;
@property StrengthStats* strengthStats;
@property IceTypeStats* iceTypeStats;
@property CardTypeStats* cardTypeStats;
@property InfluenceStats* influenceStats;

@end

@implementation DeckAnalysisViewController

+(void) showForDeck:(Deck*)deck inViewController:(UIViewController*)vc
{
    DeckAnalysisViewController* davc = [[DeckAnalysisViewController alloc] initWithDeck:deck];
    
    [vc presentViewController:davc animated:NO completion:nil];
}

- (id)initWithDeck:(Deck*)deck
{
    self = [super initWithNibName:@"DeckAnalysisViewController" bundle:nil];
    if (self) {
        self.deck = deck;
        self.modalPresentationStyle = UIModalPresentationFormSheet;
        
        self.errors = [deck checkValidity];
        self.costStats = [[CostStats alloc] initWithDeck:deck];
        self.strengthStats = [[StrengthStats alloc] initWithDeck:deck];
        self.cardTypeStats = [[CardTypeStats alloc] initWithDeck:deck];
        self.influenceStats = [[InfluenceStats alloc] initWithDeck:deck];
        if (self.deck.role == NRRoleCorp)
        {
            self.iceTypeStats = [[IceTypeStats alloc] initWithDeck:deck];
        }
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

-(void) done:(id)sender
{
    [self dismissViewControllerAnimated:NO completion:nil];
}

#pragma mark tableview

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 6;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section)
    {
        case 0:
            return 44;
        case 1:
            return self.costStats.height;
        case 2:
            return self.strengthStats.height;
        case 3:
            return self.cardTypeStats.height;
        case 4:
            return self.influenceStats.height;
        case 5:
            return self.iceTypeStats.height;
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        case 0:
            return MAX(2, self.errors.count + 1);
        case 1:
        case 2:
        case 3:
        case 4:
        case 5:
            return 1;
    }
    return 0;
}

-(NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section)
    {
        case 0:
            return @"Deck Validity";
        case 1:
            if (self.costStats.height > 0) return @"Cost Distribution";
            break;
        case 2:
            if (self.strengthStats.height > 0) return @"Strength Distribution";
            break;
        case 3:
            if (self.cardTypeStats.height > 0) return @"Card Type Distribution";
            break;
        case 4:
            if (self.influenceStats.height > 0) return @"Influence Distribution";
            break;
        case 5:
            if (self.iceTypeStats.height > 0) return @"Ice Type Distribution";
            break;
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString* cellIdentifier = [NSString stringWithFormat:@"analysisCell%ld", (long)indexPath.section];
    
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    switch (indexPath.section)
    {
        case 0:
            cell.textLabel.font = [UIFont systemFontOfSize:15];
            
            if (self.errors.count > 0)
            {
                if (indexPath.row == self.errors.count)
                {
                    cell.textLabel.text = [NSString stringWithFormat:@"Cards up to %@", [CardSets mostRecentSetUsedInDeck:self.deck]];
                    cell.textLabel.textColor = [UIColor blackColor];
                }
                else
                {
                    cell.textLabel.text = [self.errors objectAtIndex:indexPath.row];
                    cell.textLabel.textColor = [UIColor redColor];
                }
            }
            else
            {
                if (indexPath.row == 0)
                {
                    cell.textLabel.text = @"Deck is valid";
                }
                else
                {
                    cell.textLabel.text = [NSString stringWithFormat:@"Cards up to %@", [CardSets mostRecentSetUsedInDeck:self.deck]];
                }
                
                cell.textLabel.textColor = [UIColor blackColor];
            }
            break;
        case 1:
            [cell.contentView addSubview:self.costStats.hostingView];
            break;
        case 2:
            [cell.contentView addSubview:self.strengthStats.hostingView];
            break;
        case 3:
            [cell.contentView addSubview:self.cardTypeStats.hostingView];
            break;
        case 4:
            [cell.contentView addSubview:self.influenceStats.hostingView];
            break;
        case 5:
            [cell.contentView addSubview:self.iceTypeStats.hostingView];
            break;
    }
    
    return cell;
}


@end
