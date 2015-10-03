//
//  BrowserViewController.m
//  NetDeck
//
//  Created by Gereon Steffens on 03.10.15.
//  Copyright © 2015 Gereon Steffens. All rights reserved.
//

#import "BrowserViewController.h"
#import "CardImageViewController.h"
#import "SmallPipsView.h"
#import "ImageCache.h"
#import "CardList.h"
#import "Card.h"

@interface BrowserViewController ()

@property NRRole role;
@property NSString* searchText;
@property CardList* cardList;
@property NSArray* cards;
@property NSArray* sections;

@end

@implementation BrowserViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = l10n(@"Browser");
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[ImageCache hexTile]];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.backgroundColor = [UIColor clearColor];
    
    self.searchBar.scopeButtonTitles = @[ l10n(@"Both"), l10n(@"Runner"), l10n(@"Corp") ];
    self.searchBar.showsCancelButton = NO;
    
    self.role = NRRoleNone;
    [self refresh];
}

-(void) refresh
{
    self.cardList = [CardList browserInitForRole:self.role];
    if (self.searchText.length > 0)
    {
        [self.cardList filterByName:self.searchText];
    }
    TableData* data = [self.cardList dataForTableView];
    self.cards = data.values;
    self.sections = data.sections;
    
    [self.tableView reloadData];
}

#pragma mark - table view

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.sections.count;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray* arr = self.cards[section];
    return arr.count;
}

-(NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSArray* arr = self.cards[section];
    
    return [NSString stringWithFormat:@"%@ (%ld)", self.sections[section], (long)arr.count];
}

-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* cellIdentifier = @"browserCell";
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        SmallPipsView* pips = [SmallPipsView createWithFrame:CGRectMake(0,0,38,38)];
        cell.accessoryView = pips;
    }
    
    Card* card = [self.cards objectAtIndexPath:indexPath];
    cell.textLabel.text = card.name;
    
    switch (card.type)
    {
        default:
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %d Cr.", card.factionStr, card.cost];
            break;
            
        case NRCardTypeIdentity:
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %d/%d", card.factionStr, card.minimumDecksize, card.influenceLimit];
            break;
            
        case NRCardTypeAgenda:
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %d/%d", card.factionStr, card.advancementCost, card.agendaPoints];
            break;
    }
    
    SmallPipsView* pips = (SmallPipsView*) cell.accessoryView;
    pips.value = card.influence;
    pips.color = card.factionColor;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Card* card = [self.cards objectAtIndexPath:indexPath];
    
    CardImageViewController* img = [[CardImageViewController alloc] initWithNibName:@"CardImageViewController" bundle:nil];
    
    // flatten our 2d cards array into a single list
    NSMutableArray* cards = [NSMutableArray array];
    for (NSArray* c in self.cards)
    {
        [cards addObjectsFromArray:c];
    }
    img.cards = cards;
    img.selectedCard = card;
    
    [self.navigationController pushViewController:img animated:YES];
}

#pragma mark - search bar

-(void) searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope
{
    self.role = selectedScope - 1;
    [self refresh];
}

-(void) searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    self.searchText = searchText;
    [self refresh];
}

-(void) searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    self.searchBar.showsCancelButton = YES;
}

-(void) searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    self.searchBar.showsCancelButton = NO;
    [self.searchBar resignFirstResponder];
}

@end
