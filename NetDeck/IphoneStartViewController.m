//
//  IphoneStartViewController.m
//  Net Deck
//
//  Created by Gereon Steffens on 09.08.15.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

#import "UIAlertAction+NetDeck.h"
#import "IphoneStartViewController.h"
#import "DeckManager.h"
#import "Deck.h"
#import "ImageCache.h"
#import "NRDB.h"
#import "CardUpdateCheck.h"
#import "Notifications.h"
#import "CardManager.h"
#import "EditDeckViewController.h"
#import "IphoneIdentityViewController.h"
#import "SettingsViewController.h"
#import "SettingsKeys.h"
#import "ImportDecksViewController.h"
#import "BrowserViewController.h"

@interface IphoneStartViewController ()

@property NSMutableArray* runnerDecks;
@property NSMutableArray* corpDecks;

@property NSArray* decks;
@property SettingsViewController* settings;

@property UIBarButtonItem* addButton;
@property UIBarButtonItem* importButton;

@property UIBarButtonItem* settingsButton;
@property UIBarButtonItem* sortButton;

@property NRDeckListSort deckListSort;
@property NSString* filterText;

@end

@implementation IphoneStartViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.delegate = self;
    self.title = @"Net Deck";
    self.tableViewController.title = @"Net Deck";
    
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(loadCards:) name:LOAD_CARDS object:nil];
    [nc addObserver:self selector:@selector(importDeckFromClipboard:) name:IMPORT_DECK object:nil];
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[ImageCache hexTile]];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.backgroundColor = [UIColor clearColor];
    
    self.searchBar.delegate = self;
    
    BOOL cardsAvailable = [CardManager cardsAvailable];
    self.addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(createNewDeck:)];
    self.addButton.enabled = cardsAvailable;
    self.importButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"702-import"] style:UIBarButtonItemStylePlain target:self action:@selector(importDecks:)];
    self.importButton.enabled = cardsAvailable;

    UINavigationItem* topItem = self.navigationBar.topItem;
    topItem.rightBarButtonItems = @[ self.addButton, self.importButton ];
    
    self.settingsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"740-gear"] style:UIBarButtonItemStylePlain target:self action:@selector(openSettings:)];
    self.sortButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"890-sort-ascending-toolbar"] style:UIBarButtonItemStylePlain target:self action:@selector(changeSort:)];
    self.sortButton.enabled = cardsAvailable;
    
    topItem.rightBarButtonItems = @[ self.addButton, self.importButton ];
    topItem.leftBarButtonItems = @[ self.settingsButton, self.sortButton ];
    
    self.deckListSort = [[NSUserDefaults standardUserDefaults] integerForKey:DECK_FILTER_SORT];
    
    [CardUpdateCheck checkCardsAvailable];
    
    if ([CardManager cardsAvailable] && [CardSets setsAvailable])
    {
        [self initializeDecks];
    }
    
    self.tableView.contentInset = UIEdgeInsetsZero; // wtf is this needed since iOS9?
    
    [self.tableView setContentOffset:CGPointMake(0, self.searchBar.frame.size.height) animated:NO];
}

-(void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// this is my poor man's replacement for viewWillAppear - I can't figure out why this isn't called when this view is
// back on top :(
-(void) navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if (viewController != self.tableViewController)
    {
        return;
    }
    
    NSAssert(navigationController.viewControllers.count == 1, @"nav oops");
    if ([CardManager cardsAvailable] && [CardSets setsAvailable])
    {
        [self initializeDecks];
    }
    
    [self.tableView reloadData];
}

-(void) initializeDecks
{
    self.runnerDecks = [DeckManager decksForRole:NRRoleRunner];
    self.corpDecks = [DeckManager decksForRole:NRRoleCorp];

    if (self.deckListSort != NRDeckListSortDate)
    {
        self.runnerDecks = [self sortDecks:self.runnerDecks];
        self.corpDecks = [self sortDecks:self.corpDecks];
        self.decks = @[ self.runnerDecks, self.corpDecks ];
    }
    else
    {
        NSMutableArray* arr = [NSMutableArray arrayWithArray:self.runnerDecks];
        [arr addObjectsFromArray:self.corpDecks];
        self.runnerDecks = [self sortDecks:arr];
        self.corpDecks = [NSMutableArray array];
        self.decks = @[ self.runnerDecks ];
    }
    
    if (self.filterText.length > 0)
    {
        NSPredicate* namePredicate = [NSPredicate predicateWithFormat:@"name CONTAINS[cd] %@", self.filterText];
        
        [self.runnerDecks filterUsingPredicate:namePredicate];
        [self.corpDecks filterUsingPredicate:namePredicate];
    }
    
    BOOL cardsAvailable = [CardManager cardsAvailable];
    self.addButton.enabled = cardsAvailable;
    self.importButton.enabled = cardsAvailable;
    self.sortButton.enabled = cardsAvailable;
    
    NSMutableArray* allDecks = [NSMutableArray arrayWithArray:self.runnerDecks];
    [allDecks addObjectsFromArray:self.corpDecks];
    [[NRDB sharedInstance] updateDeckMap:allDecks];
}

-(void) loadCards:(id)notification
{
    [self initializeDecks];
    [self.tableView reloadData];
}

#pragma mark - import deck

-(void)importDeckFromClipboard:(NSNotification*) notification
{
    NSDictionary* userInfo = notification.userInfo;
    Deck* deck = [userInfo objectForKey:@"deck"];
    
    [deck saveToDisk];
    
    EditDeckViewController* edit = [[EditDeckViewController alloc] initWithNibName:@"EditDeckViewController" bundle:nil];
    edit.deck = deck;
    
    if (self.viewControllers.count > 1)
    {
        [self popToRootViewControllerAnimated:NO];
    }
    [self pushViewController:edit animated:YES];
}

#pragma mark - add new deck

-(void) createNewDeck:(id)sender
{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:l10n(@"New Deck")
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alert addAction:[UIAlertAction actionWithTitle:l10n(@"New Runner Deck") handler:^(UIAlertAction *action) {
        [self addNewDeck:NRRoleRunner];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:l10n(@"New Corp Deck") handler:^(UIAlertAction *action) {
        [self addNewDeck:NRRoleCorp];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:l10n(@"Cancel") handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

-(void) addNewDeck:(NRRole)role
{
    IphoneIdentityViewController* idvc = [[IphoneIdentityViewController alloc] initWithNibName:@"IphoneIdentityViewController" bundle:nil];
    idvc.role = role;
    [self pushViewController:idvc animated:YES];
}

#pragma mark - import

-(void) importDecks:(id)sender
{
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    BOOL useNrdb = [settings boolForKey:USE_NRDB];
    BOOL useDropbox = [settings boolForKey:USE_DROPBOX];
    
    if (useNrdb && useDropbox)
    {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:l10n(@"Import Decks")
                                                                       message:nil
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:l10n(@"From Dropbox") handler:^(UIAlertAction *action) {
            [self importDecksFrom:NRImportSourceDropbox];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:l10n(@"From NetrunnerDB.com") handler:^(UIAlertAction *action) {
            [self importDecksFrom:NRImportSourceNetrunnerDb];
        }]];
        [alert addAction:[UIAlertAction cancelAction:nil]];
        
        [self presentViewController:alert animated:NO completion:nil];
    }
    else if (useNrdb)
    {
        [self importDecksFrom:NRImportSourceNetrunnerDb];
    }
    else if (useDropbox)
    {
        [self importDecksFrom:NRImportSourceDropbox];
    }
    else
    {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:l10n(@"Import Decks")
                                                                       message:l10n(@"Connect to your Dropbox and/or NetrunnerDB.com account first.")
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:l10n(@"OK") handler:nil]];
        
        [self presentViewController:alert animated:NO completion:nil];
    }
}

-(void) importDecksFrom:(NRImportSource)importSource
{
    ImportDecksViewController* import = [[ImportDecksViewController alloc] init];
    import.source = importSource;
    [self pushViewController:import animated:YES];
}

#pragma mark - sort

-(void) changeSort:(id)sender
{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:l10n(@"Sort by") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alert addAction:[UIAlertAction actionWithTitle:l10n(@"Date") handler:^(UIAlertAction *action) {
        [self changeSortType:NRDeckListSortDate];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:l10n(@"Faction") handler:^(UIAlertAction *action) {
        [self changeSortType:NRDeckListSortFaction];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:l10n(@"A-Z") handler:^(UIAlertAction *action) {
        [self changeSortType:NRDeckListSortA_Z];
    }]];
    [alert addAction:[UIAlertAction cancelAction:nil]];
    
    [self presentViewController:alert animated:NO completion:nil];
}

-(void) changeSortType:(NRDeckListSort)sort
{
    [[NSUserDefaults standardUserDefaults] setInteger:sort forKey:DECK_FILTER_SORT];
    self.deckListSort = sort;
    
    [self initializeDecks];
    [self.tableView reloadData];
}

-(NSMutableArray*) sortDecks:(NSArray*)decks
{
    switch (self.deckListSort)
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

#pragma mark - settings

-(void) openSettings:(id)sender
{
    self.settings = [[SettingsViewController alloc] init];
    [self pushViewController:self.settings.iask animated:YES];
}

#pragma mark - browser

-(void) titleButtonTapped:(id)sender
{
    BrowserViewController* browser = [[BrowserViewController alloc] initWithNibName:@"BrowserViewController" bundle:nil];
    [self pushViewController:browser animated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.decks.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray* arr = self.decks[section];
    return arr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString* cellIdentifier = @"deckCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    NSArray* decks = self.decks[indexPath.section];
    Deck* deck = decks[indexPath.row];
    
    cell.textLabel.text = deck.name;
    
    if (deck.identity)
    {
        cell.detailTextLabel.text = deck.identity.name;
        cell.detailTextLabel.textColor = deck.identity.factionColor;
    }
    else
    {
        cell.detailTextLabel.text = @"no Identity";
        cell.detailTextLabel.textColor = [UIColor blackColor];
    }
    
    return cell;
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Deck* deck = [self.decks objectAtIndexPath:indexPath];
    
    EditDeckViewController* edit = [[EditDeckViewController alloc] initWithNibName:@"EditDeckViewController" bundle:nil];
    edit.deck = deck;
    
    [self pushViewController:edit animated:YES];
}

-(NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (self.decks.count == 1)
    {
        return nil;
    }
    return section == 0 ? l10n(@"Runner") : l10n(@"Corp");
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        NSMutableArray* decks = self.decks[indexPath.section];
        Deck* deck = decks[indexPath.row];
        
        [decks removeObjectAtIndex:indexPath.row];
        [[NRDB sharedInstance] deleteDeck:deck.netrunnerDbId];
        [DeckManager removeFile:deck.filename];
        
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationLeft];
        [self.tableView endUpdates];
    }
}

#pragma mark search bar

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    self.filterText = searchText;
    [self initializeDecks];
    [self.tableView reloadData];
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

@end
