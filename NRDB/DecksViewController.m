//
//  DecksViewController.m
//  NRDB
//
//  Created by Gereon Steffens on 13.04.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <SDCAlertView.h>

#import "DecksViewController.h"
#import "UIAlertAction+NRDB.h"
#import "DeckCell.h"
#import "DeckManager.h"
#import "Deck.h"
#import "ImageCache.h"
#import "Faction.h"
#import "SettingsKeys.h"
#import "DeckState.h"
#import "NRDB.h"

@interface DecksViewController ()

@property NSMutableArray* runnerDecks;
@property NSMutableArray* corpDecks;
@property NSDateFormatter *dateFormatter;

@property NRDeckSearchScope searchScope;
@property NSString* filterText;

@property NRDeckState filterState;
@property NRDeckListSort sortType;

@end

@implementation DecksViewController

static NSDictionary* sortStr;
static NSDictionary* sideStr;

// filterState, sortType and filterType look like normal properties, but are backed
// by statics so that whenever we switch between views of subclasses, the filters
// remain intact
static NRDeckState _filterState = NRDeckStateNone;
static NRDeckListSort _sortType = NRDeckListSortA_Z;
static NRFilter _filterType = NRFilterAll;

-(NRFilter) filterType { return _filterType; }
-(void) setFilterType:(NRFilter)filterType { _filterType = filterType; }
-(NRDeckListSort) sortType { return _sortType; }
-(void) setSortType:(NRDeckListSort)sortType { _sortType = sortType; }
-(NRDeckState) filterState { return _filterState; }
-(void) setFilterState:(NRDeckState)filterState { _filterState = filterState; }

+(void) initialize
{
    sortStr = @{ @(NRDeckListSortDate): l10n(@"Date"), @(NRDeckListSortFaction): l10n(@"Faction"), @(NRDeckListSortA_Z): l10n(@"A-Z") };
    sideStr = @{ @(NRFilterAll): l10n(@"Both"), @(NRFilterRunner): l10n(@"Runner"), @(NRFilterCorp): l10n(@"Corp") };
}

- (id) init
{
    if ((self = [self initWithNibName:@"DecksViewController" bundle:nil]))
    {
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [self.dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
        
        NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
        
        self.filterType = [settings integerForKey:DECK_FILTER_TYPE];
        self.filterState = [settings integerForKey:DECK_FILTER_STATE];
        self.sortType = [settings integerForKey:DECK_FILTER_SORT];
    }
    return self;
}

- (id) initWithCardFilter:(Card*)card
{
    if ((self = [self init]))
    {
        self.filterText = card.name;
        self.searchScope = card.type == NRCardTypeIdentity ? NRDeckSearchIdentity : NRDeckSearchCard;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.parentViewController.view.backgroundColor = [UIColor colorWithPatternImage:[ImageCache hexTile]];
    
    UINavigationItem* topItem = self.navigationController.navigationBar.topItem;
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:l10n(@"Decks")
                                      style:UIBarButtonItemStylePlain
                                     target:nil
                                     action:nil];
    
    self.sortButton = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:@"%@ ▾", sortStr[@(self.sortType)]]
                                                       style:UIBarButtonItemStylePlain
                                                      target:self
                                                      action:@selector(changeSort:)];
    self.sortButton.possibleTitles = [NSSet setWithArray:@[
                                                           [NSString stringWithFormat:@"%@ ▾", l10n(@"Date")],
                                                           [NSString stringWithFormat:@"%@ ▾", l10n(@"Faction")],
                                                           [NSString stringWithFormat:@"%@ ▾", l10n(@"A-Z")],
                                                           ]];
    
    self.sideFilterButton = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:@"%@ ▾", sideStr[@(self.filterType)]]
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(changeSideFilter:)];
    self.sideFilterButton.possibleTitles = [NSSet setWithArray:@[
                                                           [NSString stringWithFormat:@"%@ ▾", l10n(@"Both")],
                                                           [NSString stringWithFormat:@"%@ ▾", l10n(@"Runner")],
                                                           [NSString stringWithFormat:@"%@ ▾", l10n(@"Corp")],
                                                           ]];
    
    self.stateFilterButton = [[UIBarButtonItem alloc] initWithTitle:[DeckState buttonLabelFor:self.filterState]
                                                              style:UIBarButtonItemStylePlain
                                                             target:self
                                                             action:@selector(changeStateFilter:)];
    
    self.stateFilterButton.possibleTitles = [NSSet setWithArray:@[
                                                                 [DeckState buttonLabelFor:NRDeckStateNone],
                                                                 [DeckState buttonLabelFor:NRDeckStateActive],
                                                                 [DeckState buttonLabelFor:NRDeckStateTesting],
                                                                 [DeckState buttonLabelFor:NRDeckStateRetired],
                                                                 ]];
    
    topItem.leftBarButtonItems = @[
          self.sortButton,
          self.sideFilterButton,
          self.stateFilterButton
    ];
    
    self.searchBar.placeholder = l10n(@"Search for decks, identities or cards");
    if (self.filterText.length > 0)
    {
        self.searchBar.text = self.filterText;
    }
    self.searchBar.scopeButtonTitles = @[ l10n(@"All"), l10n(@"Name"), l10n(@"Identity"), l10n(@"Card") ];
    self.searchBar.showsScopeBar = NO;
    self.searchBar.showsCancelButton = NO;
    self.searchBar.selectedScopeButtonIndex = self.searchScope;
    // needed on iOS8
    [self.searchBar sizeToFit];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.rowHeight = 44;
    [self.tableView registerNib:[UINib nibWithNibName:@"DeckCell" bundle:nil] forCellReuseIdentifier:@"deckCell"];
    
    [self.tableView setContentOffset:CGPointMake(0, self.searchBar.frame.size.height) animated:NO];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self updateDecks];
    
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(willShowKeyboard:) name:UIKeyboardWillShowNotification object:nil];
    [nc addObserver:self selector:@selector(willHideKeyboard:) name:UIKeyboardWillHideNotification object:nil];
}

-(void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    
    [settings setObject:@(self.filterType) forKey:DECK_FILTER_TYPE];
    [settings setObject:@(self.filterState) forKey:DECK_FILTER_STATE];
    [settings setObject:@(self.sortType) forKey:DECK_FILTER_SORT];
    
    [settings synchronize];
}

#pragma mark action sheet

-(void) dismissPopup
{
    [self.popup dismissViewControllerAnimated:NO completion:nil];
    self.popup = nil;
}

-(void) changeSort:(id)sender
{
    if (self.popup)
    {
        [self dismissPopup];
        return;
    }
    
    self.popup = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [self.popup addAction:[UIAlertAction actionWithTitle:l10n(@"Date") handler:^(UIAlertAction *action) {
        [self changeSortType:NRDeckListSortDate];
    }]];
    [self.popup addAction:[UIAlertAction actionWithTitle:l10n(@"Faction") handler:^(UIAlertAction *action) {
        [self changeSortType:NRDeckListSortFaction];
    }]];
    [self.popup addAction:[UIAlertAction actionWithTitle:l10n(@"A-Z") handler:^(UIAlertAction *action) {
        [self changeSortType:NRDeckListSortA_Z];
    }]];
    [self.popup addAction:[UIAlertAction cancelAction:^(UIAlertAction *action) {
        self.popup = nil;
    }]];
    
    UIPopoverPresentationController* popover = self.popup.popoverPresentationController;
    popover.barButtonItem = sender;
    popover.sourceView = self.view;
    popover.permittedArrowDirections = UIPopoverArrowDirectionAny;
    
    [self presentViewController:self.popup animated:NO completion:nil];
}

-(void) changeSortType:(NRDeckListSort)sortType
{
    self.sortType = sortType;
    self.popup = nil;
    [self updateDecks];
}

-(void) changeSideFilter:(id)sender
{
    if (self.popup)
    {
        [self dismissPopup];
        return;
    }

    self.popup = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [self.popup addAction:[UIAlertAction actionWithTitle:l10n(@"Both") handler:^(UIAlertAction *action) {
        [self changeSide:NRFilterAll];
    }]];
    [self.popup addAction:[UIAlertAction actionWithTitle:l10n(@"Runner") handler:^(UIAlertAction *action) {
        [self changeSide:NRFilterRunner];
    }]];
    [self.popup addAction:[UIAlertAction actionWithTitle:l10n(@"Corp") handler:^(UIAlertAction *action) {
        [self changeSide:NRFilterCorp];
    }]];
    [self.popup addAction:[UIAlertAction cancelAction:^(UIAlertAction *action) {
        self.popup = nil;
    }]];
    
    UIPopoverPresentationController* popover = self.popup.popoverPresentationController;
    popover.barButtonItem = sender;
    popover.sourceView = self.view;
    popover.permittedArrowDirections = UIPopoverArrowDirectionAny;
    
    [self presentViewController:self.popup animated:NO completion:nil];
}

-(void) changeSide:(NRFilter)filterType
{
    self.filterType = filterType;
    self.popup = nil;
    [self updateDecks];
}

-(void) changeStateFilter:(id)sender
{
    if (self.popup)
    {
        [self dismissPopup];
        return;
    }
    
    self.popup = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [self.popup addAction:[UIAlertAction actionWithTitle:l10n(@"All") handler:^(UIAlertAction *action) {
        [self changeState:NRDeckStateNone];
    }]];
    [self.popup addAction:[UIAlertAction actionWithTitle:l10n(@"Active") handler:^(UIAlertAction *action) {
        [self changeState:NRDeckStateActive];
    }]];
    [self.popup addAction:[UIAlertAction actionWithTitle:l10n(@"Testing") handler:^(UIAlertAction *action) {
        [self changeState:NRDeckStateTesting];
    }]];
    [self.popup addAction:[UIAlertAction actionWithTitle:l10n(@"Retired") handler:^(UIAlertAction *action) {
        [self changeState:NRDeckStateRetired];
    }]];
    [self.popup addAction:[UIAlertAction cancelAction:^(UIAlertAction *action) {
        self.popup = nil;
    }]];
    
    UIPopoverPresentationController* popover = self.popup.popoverPresentationController;
    popover.barButtonItem = sender;
    popover.sourceView = self.view;
    popover.permittedArrowDirections = UIPopoverArrowDirectionAny;
    
    [self presentViewController:self.popup animated:NO completion:nil];
}

-(void) changeState:(NRDeckState)filterState
{
    self.filterState = filterState;
    self.popup = nil;
    [self updateDecks];
}

-(void) updateDecks
{
    [self.sortButton setTitle:[NSString stringWithFormat:@"%@ ▾", sortStr[@(self.sortType)]]];
    [self.sideFilterButton setTitle:[NSString stringWithFormat:@"%@ ▾", sideStr[@(self.filterType)]]];
    [self.stateFilterButton setTitle:[DeckState buttonLabelFor:self.filterState]];

    NSArray* runnerDecks = (self.filterType == NRFilterRunner || self.filterType == NRFilterAll) ? [DeckManager decksForRole:NRRoleRunner] : [NSArray array];
    NSArray* corpDecks = (self.filterType == NRFilterCorp || self.filterType == NRFilterAll) ? [DeckManager decksForRole:NRRoleCorp] : [NSArray array];
    
    NSMutableArray* allDecks = [NSMutableArray arrayWithArray:runnerDecks];
    [allDecks addObjectsFromArray:corpDecks];
    [[NRDB sharedInstance] updateDeckMap:allDecks];

    
#if DEBUG
    [self checkDecks:self.runnerDecks];
    [self checkDecks:self.corpDecks];
#endif
    
    if (self.sortType != NRDeckListSortDate)
    {
        self.runnerDecks = [self sortDecks:runnerDecks];
        self.corpDecks = [self sortDecks:corpDecks];
    }
    else
    {
        NSMutableArray* arr = [NSMutableArray arrayWithArray:runnerDecks];
        [arr addObjectsFromArray:corpDecks];
        self.runnerDecks = [self sortDecks:arr];
        self.corpDecks = [NSMutableArray array];
    }

    if (self.filterText.length > 0)
    {
        NSPredicate* namePredicate = [NSPredicate predicateWithFormat:@"name CONTAINS[cd] %@", self.filterText];
        NSPredicate* identityPredicate = [NSPredicate predicateWithFormat:@"identity.name CONTAINS[cd] %@", self.filterText];
        NSPredicate* cardPredicate = [NSPredicate predicateWithFormat:@"ANY cards.card.name CONTAINS[cd] %@", self.filterText];
        
        NSPredicate* predicate;
        switch (self.searchScope)
        {
            case NRDeckSearchAll:
                predicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[ namePredicate, identityPredicate, cardPredicate ]];
                break;
            case NRDeckSearchName:
                predicate = namePredicate;
                break;
            case NRDeckSearchIdentity:
                predicate = identityPredicate;
                break;
            case NRDeckSearchCard:
                predicate = cardPredicate;
                break;
        }
        
        [self.runnerDecks filterUsingPredicate:predicate];
        [self.corpDecks filterUsingPredicate:predicate];
    }
    
    if (self.filterState != NRDeckStateNone)
    {
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"state == %d", self.filterState];
        [self.runnerDecks filterUsingPredicate:predicate];
        [self.corpDecks filterUsingPredicate:predicate];
    }
    
    self.decks = @[ self.runnerDecks, self.corpDecks ];
    
    [self.tableView reloadData];
}

-(void) checkDecks:(NSArray*)decks
{
    for (Deck* deck in decks)
    {
        if (deck.identity)
        {
            if (deck.role != deck.identity.role)
            {
                NSString* msg = [NSString stringWithFormat:@"deck role mismatch %@ %ld != %ld %@",
                                 deck.name, (long)deck.role, (long)deck.identity.role, deck.identity.name];
                [SDCAlertView alertWithTitle:nil message:msg buttons:@[@"Oops"]];
            }
        }
    }
}

-(NSMutableArray*) sortDecks:(NSArray*)decks
{
    switch (self.sortType)
    {
        case NRDeckListSortA_Z:
            decks = [decks sortedArrayUsingComparator:^NSComparisonResult(Deck* d1, Deck* d2) {
                return [[d1.name lowercaseString] compare:[d2.name lowercaseString]];
            }];
            break;
        case NRDeckListSortDate:
            decks = [decks sortedArrayUsingComparator:^NSComparisonResult(Deck* d1, Deck* d2) {
                NSComparisonResult cmp = [d2.lastModified compare:d1.lastModified];
                if (cmp == NSOrderedSame)
                {
                    return [[d1.name lowercaseString] compare:[d2.name lowercaseString]];
                }
                return cmp;
            }];
            break;
        case NRDeckListSortFaction:
            decks = [decks sortedArrayUsingComparator:^NSComparisonResult(Deck* d1, Deck* d2) {
                NSString* faction1 = [Faction name:d1.identity.faction];
                NSString* faction2 = [Faction name:d2.identity.faction];
                NSComparisonResult cmp = [faction1 compare:faction2];
                if (cmp == NSOrderedSame)
                {
                    cmp = [[d1.identity.name lowercaseString] compare:[d2.identity.name lowercaseString]];
                    if (cmp == NSOrderedSame)
                    {
                        return [[d1.name lowercaseString] compare:[d2.name lowercaseString]];
                    }
                    return cmp;
                }
                return cmp;
            }];
            break;
    }
    
    return [decks mutableCopy];
}

#pragma mark search bar

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    self.filterText = searchText;
    [self updateDecks];
}

-(void) searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope
{
    self.searchScope = selectedScope;
    [self updateDecks];
}

-(void) searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    searchBar.showsCancelButton = NO;
    searchBar.showsScopeBar = NO;
    [searchBar sizeToFit];
    self.tableView.tableHeaderView = self.searchBar;
}

-(void) searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    searchBar.showsCancelButton = YES;
    searchBar.showsScopeBar = YES;
    [searchBar sizeToFit];
    self.tableView.tableHeaderView = self.searchBar;
}

-(void) searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

#pragma mark tableview

-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DeckCell* cell = [tableView dequeueReusableCellWithIdentifier:@"deckCell" forIndexPath:indexPath];
    
    NSArray* decks = self.decks[indexPath.section];
    Deck* deck = decks[indexPath.row];
    cell.nameLabel.text = deck.name;
    
    if (deck.identity)
    {
        cell.identityLabel.text = deck.identity.name;
        cell.identityLabel.textColor = [deck.identity factionColor];
    }
    else
    {
        cell.identityLabel.text = l10n(@"No Identity");
        cell.identityLabel.textColor = [UIColor darkGrayColor];
    }
    
    NSString* summary;
    if (deck.role == NRRoleRunner)
    {
        summary = [NSString stringWithFormat:l10n(@"%d Cards · %d Influence"), deck.size, deck.influence];
    }
    else
    {
        summary = [NSString stringWithFormat:l10n(@"%d Cards · %d Influence · %d AP"), deck.size, deck.influence, deck.agendaPoints];
    }
    cell.summaryLabel.text = summary;
    BOOL valid = [deck checkValidity].count == 0;
    cell.summaryLabel.textColor = valid ? [UIColor blackColor] : [UIColor redColor];
    
    NSString* state = [DeckState labelFor:deck.state];
    NSString* date = [self.dateFormatter stringFromDate:deck.lastModified];
    cell.dateLabel.text = [NSString stringWithFormat:@"%@ · %@", state, date];
    
    cell.nrdbIcon.hidden = deck.netrunnerDbId == nil;
    cell.infoButton.hidden = YES;
    
    return cell;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        case 0: return self.runnerDecks.count;
        case 1: return self.corpDecks.count;
    }
    return 0;
}

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

-(NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (self.sortType == NRDeckListSortDate)
    {
        return nil;
    }
    switch (section)
    {
        case 0: return self.runnerDecks.count > 0 ? l10n(@"Runner") : nil;
        case 1: return self.corpDecks.count > 0 ? l10n(@"Corp") : nil;
    }
    return nil;
}

#pragma mark keyboard show/hide

-(void) willShowKeyboard:(NSNotification*)sender
{
    CGRect kbRect = [[sender.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    float kbHeight = kbRect.size.height;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(64.0, 0.0, kbHeight, 0.0);
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;
}

-(void) willHideKeyboard:(NSNotification*)sender
{
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(64, 0, 0, 0);
    
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;
}

@end
