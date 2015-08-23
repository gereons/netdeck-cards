//
//  IphoneStartViewController.m
//  NRDB
//
//  Created by Gereon Steffens on 09.08.15.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

#import "UIAlertAction+NRDB.h"
#import "IphoneStartViewController.h"
#import "DeckManager.h"
#import "Deck.h"
#import "ImageCache.h"
#import "NRDB.h"
#import "CardUpdateCheck.h"
#import "Notifications.h"
#import "CardManager.h"
#import "CardSets.h"
#import "EditDeckViewController.h"
#import "IphoneIdentityViewController.h"
#import "SettingsViewController.h"
#import "SettingsKeys.h"
#import "ImportDecksViewController.h"

@interface IphoneStartViewController ()

@property NSMutableArray* runnerDecks;
@property NSMutableArray* corpDecks;
@property NSArray* decks;
@property SettingsViewController* settings;

@property UIBarButtonItem* addButton;
@property UIBarButtonItem* importButton;

@end

@implementation IphoneStartViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.delegate = self;
    
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(loadCards:) name:LOAD_CARDS object:nil];
    [nc addObserver:self selector:@selector(importDeckFromClipboard:) name:IMPORT_DECK object:nil];
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[ImageCache hexTile]];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.backgroundColor = [UIColor clearColor];
    
    self.addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(createNewDeck:)];
    self.addButton.enabled = NO;
    self.importButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"702-import"] style:UIBarButtonItemStylePlain target:self action:@selector(importDecks:)];
    self.importButton.enabled = NO;
    
    self.navigationBar.topItem.rightBarButtonItems = @[ self.addButton, self.importButton ];
    
    [CardUpdateCheck checkCardsAvailable];
    
    if ([CardManager cardsAvailable] && [CardSets setsAvailable])
    {
        [self initializeDecks];
    }
}

-(void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// this is a poor man's replacement for viewWillAppear - I can't figure out why this isn't called when this view is
// back on top :(
-(void) navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if (viewController != self.tableViewController)
    {
        return;
    }
    
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
    self.decks = @[ self.runnerDecks, self.corpDecks ];
    
    self.addButton.enabled = YES;
    self.importButton.enabled = YES;
    
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
    
    self.deckEditor = edit;
    
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

#pragma mark - settings

-(void) openSettings:(id)sender
{
    self.settings = [[SettingsViewController alloc] init];
    [self pushViewController:self.settings.iask animated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return section == 0 ? self.runnerDecks.count : self.corpDecks.count;
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
    
    self.deckEditor = edit;
    [self pushViewController:edit animated:YES];
}

-(NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
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

@end
