//
//  DeckAnalysisViewController.m
//  Net Deck
//
//  Created by Gereon Steffens on 10.02.14.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
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
@property BOOL showSets;
@property NSArray* sets;

@property CostStats* costStats;
@property StrengthStats* strengthStats;
@property IceTypeStats* iceTypeStats;
@property CardTypeStats* cardTypeStats;
@property InfluenceStats* influenceStats;
@property UIButton* toggleButton;

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
    if (self)
    {
        self.deck = deck;
        self.modalPresentationStyle = UIModalPresentationFormSheet;
        
        self.errors = [deck checkValidity];
        self.sets = [CardSets setsUsedInDeck:deck];
        self.costStats = [[CostStats alloc] initWithDeck:deck];
        self.strengthStats = [[StrengthStats alloc] initWithDeck:deck];
        self.cardTypeStats = [[CardTypeStats alloc] initWithDeck:deck];
        self.influenceStats = [[InfluenceStats alloc] initWithDeck:deck];
        if (self.deck.role == NRRoleCorp)
        {
            self.iceTypeStats = [[IceTypeStats alloc] initWithDeck:deck];
        }
        
        self.toggleButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.toggleButton.frame = CGRectMake(450, 7, 50, 30);
        [self.toggleButton setImage:[UIImage imageNamed:@"764-arrow-down"] forState:UIControlStateNormal];
        [self.toggleButton addTarget:self action:@selector(toggleSets:) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

-(void) dealloc
{
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.titleLabel.text = l10n(@"Deck Analysis");
    [self.okButton setTitle:l10n(@"Done") forState:UIControlStateNormal];
    
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
            return MAX(2, self.errors.count + 1) + (self.showSets ? self.sets.count : 0);
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
            return l10n(@"Deck Validity");
        case 1:
            if (self.costStats.height > 0) return l10n(@"Cost Distribution");
            break;
        case 2:
            if (self.strengthStats.height > 0) return l10n(@"Strength Distribution");
            break;
        case 3:
            if (self.cardTypeStats.height > 0) return l10n(@"Card Type Distribution");
            break;
        case 4:
            if (self.influenceStats.height > 0) return l10n(@"Influence Distribution");
            break;
        case 5:
            if (self.iceTypeStats.height > 0) return l10n(@"ICE Type Distribution");
            break;
    }
    return nil;
}

- (void)toggleSets:(id)sender
{
    self.showSets = !self.showSets;
    [self.toggleButton setImage:[UIImage imageNamed:self.showSets ? @"763-arrow-up" : @"764-arrow-down"] forState:UIControlStateNormal];
    
    [self.tableView reloadData];
}

-(NSInteger) tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        if (self.errors.count > 0)
        {
            if (indexPath.row > self.errors.count)
            {
                return 1;
            }
        }
        else if (indexPath.row > 1)
        {
            return 1;
        }
    }
    return 0;
}

- (NSIndexPath *)tableView:(UITableView *)tv willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    int decksRow = self.errors.count > 0 ? indexPath.row == self.errors.count : 1;
    if (indexPath.section == 0 && indexPath.row == decksRow)
    {
        return indexPath;
    }
    
    return nil;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    [self toggleSets:nil];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString* cellIdentifier = [NSString stringWithFormat:@"analysisCell%ld", (long)indexPath.section];
    
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    switch (indexPath.section)
    {
        case 0:
            cell.textLabel.font = [UIFont systemFontOfSize:15];
            
            if (self.errors.count > 0)
            {
                if (indexPath.row < self.errors.count)
                {
                    cell.textLabel.text = [self.errors objectAtIndex:indexPath.row];
                    cell.textLabel.textColor = [UIColor redColor];
                }
                else if (indexPath.row == self.errors.count)
                {
                    cell.textLabel.text = [NSString stringWithFormat:l10n(@"Cards up to %@"), [CardSets mostRecentSetUsedInDeck:self.deck]];
                    cell.textLabel.textColor = [UIColor blackColor];
                    [cell.contentView addSubview:self.toggleButton];
                }
                else if (indexPath.row > self.errors.count)
                {
                    cell.textLabel.text = [self.sets objectAtIndex:indexPath.row - self.errors.count - 1];
                    cell.textLabel.textColor = [UIColor blackColor];
                }
            }
            else
            {
                switch (indexPath.row)
                {
                    case 0:
                        cell.textLabel.text = l10n(@"Deck is valid");
                        break;
                    case 1:
                        cell.textLabel.text = [NSString stringWithFormat:l10n(@"Cards up to %@"), [CardSets mostRecentSetUsedInDeck:self.deck]];
                        [cell.contentView addSubview:self.toggleButton];
                        break;
                    default:
                        cell.textLabel.text = [self.sets objectAtIndex:indexPath.row-2];
                        break;
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
