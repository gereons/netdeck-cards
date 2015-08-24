//
//  ListCardsViewController.m
//  NRDB
//
//  Created by Gereon Steffens on 10.08.15.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

#import "ListCardsViewController.h"
#import "CardImageViewController.h"
#import "ImageCache.h"
#import "EditDeckCell.h"
#import "Deck.h"
#import "TableData.h"
#import "CardList.h"
#import "Faction.h"
#import "CardType.h"

@interface ListCardsViewController ()

@property NSArray* cards;
@property NSArray* sections;

@property CardList* cardList;
@property NSString* filterText;

@end

@implementation ListCardsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[ImageCache hexTile]];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.backgroundColor = [UIColor clearColor];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"EditDeckCell" bundle:nil] forCellReuseIdentifier:@"cardCell"];
    
    self.cardList = [[CardList alloc] initForRole:self.deck.role];
    
    if (self.deck.role == NRRoleCorp && self.deck.identity != nil)
    {
        [self.cardList preFilterForCorp:self.deck.identity];
    }
    
    TableData* data = [self.cardList dataForTableView];
    
    self.cards = data.values;
    self.sections = data.sections;
    
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(showKeyboard:) name:UIKeyboardWillShowNotification object:nil];
    [nc addObserver:self selector:@selector(hideKeyboard:) name:UIKeyboardWillHideNotification object:nil];
}

-(void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void) countChanged:(UIStepper*)stepper
{
    NSInteger section = stepper.tag / 1000;
    NSInteger row = stepper.tag - (section*1000);
    
    NSArray* arr = self.cards[section];
    Card* card = arr[row];
    
    NSInteger count = 0;
    CardCounter* cc = [self.deck findCard:card];
    if (cc)
    {
        count = cc.count;
    }
    
    NSInteger copies = stepper.value;
    NSInteger diff = ABS(count - copies);
    if (copies < count)
    {
        [self.deck addCard:card copies:-diff];
    }
    else
    {
        [self.deck addCard:card copies:diff];
    }
    
    [self.tableView reloadData];
}

-(void) updateCards
{
    [self.cardList filterByName:self.filterText];
    TableData* data = [self.cardList dataForTableView];
    
    self.cards = data.values;
    self.sections = data.sections;
    [self.tableView reloadData];
}

#pragma mark search bar

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    self.filterText = searchText;
    [self updateCards];
}

-(void) searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    searchBar.showsCancelButton = NO;
    self.tableView.tableHeaderView = self.searchBar;
}

-(void) searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    searchBar.showsCancelButton = YES;
    self.tableView.tableHeaderView = self.searchBar;
}

-(void) searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

-(void) searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    UITextField* textField = [self.searchBar valueForKey:@"searchField"];
    if (textField == nil || ![textField isKindOfClass:[UITextField class]])
    {
        return;
    }
    
    [textField setSelectedTextRange:[textField textRangeFromPosition:textField.beginningOfDocument toPosition:textField.endOfDocument]];

    Card* card = [self.cards objectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    if (card)
    {
        [self.deck addCard:card copies:1];
        [self.tableView reloadData];
    }
}

#pragma mark - tableview

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray* arr = self.cards[section];
    return arr.count;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.sections.count;
}

-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.sections[section];
}

-(void) tableView:(UITableView *)tableView willDisplayCell:(EditDeckCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = [UIColor whiteColor];
    
    Card* card = [self.cards objectAtIndexPath:indexPath];
    CardCounter* cc = [self.deck findCard:card];
    
    if (cc.count > 0)
    {
        cell.nameLabel.font = [UIFont boldSystemFontOfSize:17];
    }
    else
    {
        cell.nameLabel.font = [UIFont systemFontOfSize:17];
    }
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    EditDeckCell* cell = [tableView dequeueReusableCellWithIdentifier:@"cardCell" forIndexPath:indexPath];
    
    cell.stepper.tag = indexPath.section * 1000 + indexPath.row;
    [cell.stepper addTarget:self action:@selector(countChanged:) forControlEvents:UIControlEventValueChanged];
    
    Card* card = [self.cards objectAtIndexPath:indexPath];
    CardCounter* cc = [self.deck findCard:card];
    
    cell.stepper.minimumValue = 0;
    cell.stepper.maximumValue = card.maxPerDeck;
    cell.stepper.value = cc.count;
    cell.stepper.hidden = NO;
    cell.idButton.hidden = YES;
    
    if (cc)
    {
        if (card.unique)
        {
            cell.nameLabel.text = [NSString stringWithFormat:@"%lu× %@ •", (unsigned long)cc.count, card.name];
        }
        else
        {
            cell.nameLabel.text = [NSString stringWithFormat:@"%lu× %@", (unsigned long)cc.count, card.name];
        }
    }
    else
    {
        if (card.unique)
        {
            cell.nameLabel.text = [NSString stringWithFormat:@"%@ •", card.name];
        }
        else
        {
            cell.nameLabel.text = [NSString stringWithFormat:@"%@", card.name];
        }
    }
    
    
    NSString* factionName = [Faction name:card.faction];
    NSString* typeName = [CardType name:card.type];
    
    NSString* subtype = card.subtype;
    if (subtype)
    {
        cell.typeLabel.text = [NSString stringWithFormat:@"%@ · %@: %@", factionName, typeName, card.subtype];
    }
    else
    {
        cell.typeLabel.text = [NSString stringWithFormat:@"%@ · %@", factionName, typeName];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Card* card = [self.cards objectAtIndexPath:indexPath];
    
    CardImageViewController* img = [[CardImageViewController alloc] initWithNibName:@"CardImageViewController" bundle:nil];
    img.cards = [self.cardList allCards];
    img.selectedCard = card;
    
    [self.navigationController pushViewController:img animated:YES];
}

#pragma mark - keyboard

-(void) showKeyboard:(NSNotification*)notification
{
    CGRect kbRect = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    float kbHeight = kbRect.size.height;
    
    UIEdgeInsets inset = self.tableView.contentInset;
    inset.bottom = kbHeight;
    self.tableView.contentInset = inset;
    self.tableView.scrollIndicatorInsets = inset;
}

-(void) hideKeyboard:(id)notification
{
    UIEdgeInsets inset = self.tableView.contentInset;
    inset.bottom = 0;
    self.tableView.contentInset = inset;
    self.tableView.scrollIndicatorInsets = inset;
}

@end
