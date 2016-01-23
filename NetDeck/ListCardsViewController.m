//
//  ListCardsViewController.m
//  Net Deck
//
//  Created by Gereon Steffens on 10.08.15.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

#import "ListCardsViewController.h"
#import "CardImageViewController.h"
#import "FilterViewController.h"
#import "ImageCache.h"
#import "EditDeckCell.h"

@interface ListCardsViewController ()

@property NSArray* cards;
@property NSArray* sections;

@property CardList* cardList;
@property NSString* filterText;

@property FilterViewController* filterViewController;

@end

static NSString* kSearchFieldValue = @"searchField";
static NSString* kCancelButton = @"cancelButton";

@implementation ListCardsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = l10n(@"Cards");
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[ImageCache hexTile]];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.backgroundColor = [UIColor clearColor];
    
    self.statusLabel.font = [UIFont md_systemFontOfSize:13];
    self.statusLabel.text = @"";

    // needed to make the 1 pixel separator show - wtf is this needed here but not elsewhere?
    [self.view bringSubviewToFront:self.toolBar];
    [self.view bringSubviewToFront:self.statusLabel];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"EditDeckCell" bundle:nil] forCellReuseIdentifier:@"cardCell"];
    
    self.cardList = [[CardList alloc] initForRole:self.deck.role];
    
    if (self.deck.identity != nil)
    {
        if (self.deck.role == NRRoleCorp) {
            [self.cardList preFilterForCorp:self.deck.identity];
        } else if (self.deck.role == NRRoleRunner) {
            [self.cardList preFilterForRunner:self.deck.identity];
        }
    }
    
    TableData* data = [self.cardList dataForTableView];
    self.cards = data.values;
    self.sections = data.sections;
    
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(showKeyboard:) name:UIKeyboardWillShowNotification object:nil];
    [nc addObserver:self selector:@selector(hideKeyboard:) name:UIKeyboardWillHideNotification object:nil];
    
    UITextField* textField = [self.searchBar valueForKey:kSearchFieldValue];
    if (textField != nil && [textField isKindOfClass:[UITextField class]])
    {
        textField.returnKeyType = UIReturnKeyDone;
    }
    
    [self updateFooter];
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
 
    TableData* data = [self.cardList dataForTableView];
    
    self.cards = data.values;
    self.sections = data.sections;
    
    [self.tableView reloadData];
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSAssert(self.navigationController.viewControllers.count == 3, @"nav oops");
    
    UINavigationItem* topItem = self.navigationController.navigationBar.topItem;
    
    UIBarButtonItem* filterButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"798-filter-toolbar"] style:UIBarButtonItemStylePlain target:self action:@selector(showFilters:)];
    topItem.rightBarButtonItem = filterButton;
}

-(void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // only clear filter when we're being popped from the nav stack
    if (self.isMovingFromParentViewController) {
        self.searchBar.text = @"";
        self.filterText = nil;
        [self.cardList clearFilters];
    }
}

-(void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void) showFilters:(id)sender
{
    if (!self.filterViewController)
    {
        self.filterViewController = [[FilterViewController alloc] initWithNibName:@"FilterViewController" bundle:nil];
    }
    self.filterViewController.role = self.deck.role;
    self.filterViewController.identity = self.deck.identity;
    self.filterViewController.cardList = self.cardList;
    
    // protect against pushing the same controller twice (crashlytics #103)
    if (self.navigationController.topViewController != self.filterViewController)
    {
        [self.navigationController pushViewController:self.filterViewController animated:YES];
    }
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
    
    [self selectTextInSearchBar];
    [self.tableView reloadData];
    
    [self updateFooter];
}

-(void) updateCards
{
    [self.cardList filterByName:self.filterText];
    TableData* data = [self.cardList dataForTableView];
    
    self.cards = data.values;
    self.sections = data.sections;
    [self.tableView reloadData];
    
    [self updateFooter];
}

-(void) updateFooter
{
    NSMutableString* footer = [NSMutableString string];
    [footer appendString:[NSString stringWithFormat:@"%ld %@", (long)self.deck.size, self.deck.size == 1 ? l10n(@"Card") : l10n(@"Cards")]];
    NSString* inf = self.deck.role == NRRoleCorp ? l10n(@"Inf") : l10n(@"Influence");
    if (self.deck.identity && !self.deck.isDraft)
    {
        [footer appendString:[NSString stringWithFormat:@" · %ld/%ld %@", (long)self.deck.influence, (long)self.deck.influenceLimit, inf]];
    }
    else
    {
        [footer appendString:[NSString stringWithFormat:@" · %ld %@", (long)self.deck.influence, inf]];
    }
    
    if (self.deck.role == NRRoleCorp)
    {
        [footer appendString:[NSString stringWithFormat:@" · %ld %@", (long)self.deck.agendaPoints, l10n(@"AP")]];
    }
    
    [footer appendString:@"\n"];
    
    NSArray* reasons = [self.deck checkValidity];
    if (reasons.count > 0)
    {
        [footer appendString:reasons[0]];
    }
    
    self.statusLabel.text = footer;
    self.statusLabel.textColor = reasons.count == 0 ? [UIColor darkGrayColor] : [UIColor redColor];
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
    UIButton* cancelBtn = [self.searchBar valueForKey:kCancelButton];
    if (cancelBtn) {
        [cancelBtn setTitle:l10n(@"Done") forState:UIControlStateNormal];
    }
    self.tableView.tableHeaderView = self.searchBar;
}

-(void) searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

-(void) searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self selectTextInSearchBar];
    
    if (self.cards.count > 0)
    {
        Card* card = [self.cards objectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        if (card)
        {
            [self.deck addCard:card copies:1];
            [self.tableView reloadData];
            
            [self updateFooter];
        }
    }
}

-(void) selectTextInSearchBar
{
    UITextField* textField = [self.searchBar valueForKey:kSearchFieldValue];
    if (textField == nil || ![textField isKindOfClass:[UITextField class]])
    {
        return;
    }
    
    [textField setSelectedTextRange:[textField textRangeFromPosition:textField.beginningOfDocument toPosition:textField.endOfDocument]];
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
    NSArray* arr = self.cards[section];
    return [NSString stringWithFormat:@"%@ (%ld)", self.sections[section], (long)arr.count];
}

-(void) tableView:(UITableView *)tableView willDisplayCell:(EditDeckCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = [UIColor whiteColor];
    
    Card* card = [self.cards objectAtIndexPath:indexPath];
    CardCounter* cc = [self.deck findCard:card];
    
    if (cc.count > 0)
    {
        cell.nameLabel.font = [UIFont md_mediumSystemFontOfSize:16];
    }
    else
    {
        cell.nameLabel.font = [UIFont md_systemFontOfSize:16];
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
    
    
    NSString* type = [Faction name:card.faction];;
    
    NSInteger influence = [self.deck influenceFor:cc];
    if (cc.count == 0 && self.deck.identity.faction != card.faction)
    {
        influence = card.influence;
    }
    
    if (influence > 0)
    {
        cell.influenceLabel.text = [NSString stringWithFormat:@"%ld", (long)influence];
        cell.influenceLabel.textColor = card.factionColor;
    }
    else
    {
        cell.influenceLabel.text = @"";
    }
    
    if (card.isMostWanted) {
        cell.mwlLabel.text = [NSString stringWithFormat:@"%ld", (long)MIN(-1, -cc.count)];
    }
    cell.mwlLabel.hidden = !card.isMostWanted;
    
    NSString* subtype = card.subtype;
    if (subtype)
    {
        // type = [type stringByAppendingString:influenceStr];
        type = [type stringByAppendingString:@" · "];
        type = [type stringByAppendingString:card.subtype];
        cell.typeLabel.text = type;
    }
    else
    {
        // type = [type stringByAppendingString:influenceStr];
        cell.typeLabel.text = type;
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
