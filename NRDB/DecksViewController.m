//
//  DecksViewController.m
//  NRDB
//
//  Created by Gereon Steffens on 13.04.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "DecksViewController.h"

#import <SDCAlertView.h>

#import "NRActionSheet.h"
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
@property NRDeckSortType sortType;

@end

@implementation DecksViewController

static NSDictionary* sortStr;
static NSDictionary* sideStr;

// filterState, sortType and filterType look like normal properties, but are backed
// by statics so that whenever we switch between views of subclasses, the filters
// remain intact
static NRDeckState _filterState = NRDeckStateNone;
static NRDeckSortType _sortType = NRDeckSortA_Z;
static NRFilterType _filterType = NRFilterAll;

-(NRFilterType) filterType { return _filterType; }
-(void) setFilterType:(NRFilterType)filterType { _filterType = filterType; }
-(NRDeckSortType) sortType { return _sortType; }
-(void) setSortType:(NRDeckSortType)sortType { _sortType = sortType; }
-(NRDeckState) filterState { return _filterState; }
-(void) setFilterState:(NRDeckState)filterState { _filterState = filterState; }

+(void) initialize
{
    sortStr = @{ @(NRDeckSortDate): l10n(@"Date"), @(NRDeckSortFaction): l10n(@"Faction"), @(NRDeckSortA_Z): l10n(@"A-Z") };
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
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.rowHeight = 44;
    [self.tableView registerNib:[UINib nibWithNibName:@"DeckCell" bundle:nil] forCellReuseIdentifier:@"deckCell"];
    
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
    self.searchBar.selectedScopeButtonIndex = self.searchScope;
    
    CGFloat height = self.filterText.length == 0 ? self.searchBar.frame.size.height : 0;
    [self.tableView setContentOffset:CGPointMake(0,height) animated:NO];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self updateDecks];
}

-(void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    
    [settings setObject:@(self.filterType) forKey:DECK_FILTER_TYPE];
    [settings setObject:@(self.filterState) forKey:DECK_FILTER_STATE];
    [settings setObject:@(self.sortType) forKey:DECK_FILTER_SORT];
    
    [settings synchronize];
}

#pragma mark action sheet

-(void) dismissPopup
{
    [self.popup dismissWithClickedButtonIndex:self.popup.cancelButtonIndex animated:NO];
    self.popup = nil;
}

-(void) changeSort:(id)sender
{
    if (self.popup)
    {
        [self dismissPopup];
        return;
    }
    
    self.popup = [[NRActionSheet alloc] initWithTitle:nil
                                             delegate:nil
                                    cancelButtonTitle:@""
                               destructiveButtonTitle:nil
                                    otherButtonTitles:l10n(@"Date"), l10n(@"Faction"), l10n(@"A-Z"), nil];

    [self.popup showFromBarButtonItem:sender animated:NO action:^(NSInteger buttonIndex) {
        switch (buttonIndex)
        {
            case 0:
                self.sortType = NRDeckSortDate;
                break;
            case 1:
                self.sortType = NRDeckSortFaction;
                break;
            case 2:
                self.sortType = NRDeckSortA_Z;
                break;
        }
        self.popup = nil;
        [self updateDecks];
    }];
}

-(void) changeSideFilter:(id)sender
{
    if (self.popup)
    {
        [self dismissPopup];
        return;
    }

    self.popup = [[NRActionSheet alloc] initWithTitle:nil
                                             delegate:nil
                                    cancelButtonTitle:@""
                               destructiveButtonTitle:nil
                                    otherButtonTitles:l10n(@"Both"), l10n(@"Runner"), l10n(@"Corp"), nil];

    [self.popup showFromBarButtonItem:sender animated:NO action:^(NSInteger buttonIndex) {
        switch (buttonIndex)
        {
            case 0:
                self.filterType = NRFilterAll;
                break;
            case 1:
                self.filterType = NRFilterRunner;
                break;
            case 2:
                self.filterType = NRFilterCorp;
                break;
        }
        self.popup = nil;
        [self updateDecks];
    }];
}

-(void) changeStateFilter:(id)sender
{
    if (self.popup)
    {
        [self dismissPopup];
        return;
    }
    
    self.popup = [[NRActionSheet alloc] initWithTitle:nil
                                             delegate:nil
                                    cancelButtonTitle:@""
                               destructiveButtonTitle:nil
                                    otherButtonTitles:l10n(@"All"), l10n(@"Active"), l10n(@"Testing"), l10n(@"Retired"), nil];

    [self.popup showFromBarButtonItem:sender animated:NO action:^(NSInteger buttonIndex) {
        switch (buttonIndex)
        {
            case 0:
                self.filterState = NRDeckStateNone;
                break;
            case 1:
                self.filterState = NRDeckStateActive;
                break;
            case 2:
                self.filterState = NRDeckStateTesting;
                break;
            case 3:
                self.filterState = NRDeckStateRetired;
                break;
        }
        self.popup = nil;
        [self updateDecks];
    }];
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
    
    if (self.sortType != NRDeckSortDate)
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
        case NRDeckSortA_Z:
            decks = [decks sortedArrayUsingComparator:^NSComparisonResult(Deck* d1, Deck* d2) {
                return [[d1.name lowercaseString] compare:[d2.name lowercaseString]];
            }];
            break;
        case NRDeckSortDate:
            decks = [decks sortedArrayUsingComparator:^NSComparisonResult(Deck* d1, Deck* d2) {
                NSComparisonResult cmp = [d2.lastModified compare:d1.lastModified];
                if (cmp == NSOrderedSame)
                {
                    return [[d1.name lowercaseString] compare:[d2.name lowercaseString]];
                }
                return cmp;
            }];
            break;
        case NRDeckSortFaction:
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
    if (self.sortType == NRDeckSortDate)
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

@end
