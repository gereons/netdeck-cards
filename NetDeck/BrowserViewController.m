//
//  BrowserViewController.m
//  NetDeck
//
//  Created by Gereon Steffens on 03.10.15.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

#import "BrowserViewController.h"
#import "CardImageViewController.h"
#import "SmallPipsView.h"
#import "ImageCache.h"

@interface BrowserViewController ()

@property NRRole role;
@property NSString* searchText;
@property CardList* cardList;
@property NSArray<NSArray<Card*>*>* cards;
@property NSArray<NSString*>* sections;

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
    
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(showKeyboard:) name:UIKeyboardWillShowNotification object:nil];
    [nc addObserver:self selector:@selector(hideKeyboard:) name:UIKeyboardWillHideNotification object:nil];
    
    UILongPressGestureRecognizer* longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    [self.tableView addGestureRecognizer:longPress];
    
    self.role = NRRoleNone;
    [self refresh];
}

-(void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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

#pragma mark - long press

-(void) longPress:(UIGestureRecognizer*)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan)
    {
        CGPoint point = [gesture locationInView:self.tableView];
        NSIndexPath* indexPath = [self.tableView indexPathForRowAtPoint:point];
        if (indexPath)
        {
            Card* card = [self.cards objectAtIndexPath:indexPath];
            
            NSString* msg = [NSString stringWithFormat:l10n(@"Open ANCUR page for\n%@?"), card.name];
            
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil message:msg preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:l10n(@"OK") handler:^(UIAlertAction * _Nonnull action) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:card.ancurLink]];
            }]];
            [alert addAction:[UIAlertAction cancelAlertAction:nil]];
            
            [self presentViewController:alert animated:NO completion:nil];
        }
    }
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
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ · %ld Cr", card.factionStr, (long)card.cost];
            break;
            
        case NRCardTypeIdentity:
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ · %ld/%ld", card.factionStr, (long)card.minimumDecksize, (long)card.influenceLimit];
            break;
            
        case NRCardTypeAgenda:
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ · %ld/%ld", card.factionStr, (long)card.advancementCost, (long)card.agendaPoints];
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

#pragma mark - keyboard display

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
