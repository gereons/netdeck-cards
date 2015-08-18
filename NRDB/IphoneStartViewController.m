//
//  IphoneStartViewController.m
//  NRDB
//
//  Created by Gereon Steffens on 09.08.15.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

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

@interface IphoneStartViewController ()

@property NSMutableArray* runnerDecks;
@property NSMutableArray* corpDecks;
@property NSArray* decks;

@end

@implementation IphoneStartViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [CardUpdateCheck checkCardsAvailable];
    
    if ([CardManager cardsAvailable] && [CardSets setsAvailable])
    {
        [self initializeDecks];
    }
    
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(loadCards:) name:LOAD_CARDS object:nil];
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[ImageCache hexTile]];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.backgroundColor = [UIColor clearColor];
}

-(void) initializeDecks
{
    self.runnerDecks = [DeckManager decksForRole:NRRoleRunner];
    self.corpDecks = [DeckManager decksForRole:NRRoleCorp];
    self.decks = @[ self.runnerDecks, self.corpDecks ];
    
    NSMutableArray* allDecks = [NSMutableArray arrayWithArray:self.runnerDecks];
    [allDecks addObjectsFromArray:self.corpDecks];
    [[NRDB sharedInstance] updateDeckMap:allDecks];
}

-(void) loadCards:(id)notification
{
    [self initializeDecks];
    [self.tableView reloadData];
}

#pragma mark - add new deck

-(void) createNewDeck:(id)sender
{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:l10n(@"New Deck")
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"New Runner Deck" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self addNewDeck:NRRoleRunner];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"New Corp Deck" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self addNewDeck:NRRoleCorp];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        // nop
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

-(void) addNewDeck:(NRRole)role
{
    IphoneIdentityViewController* idvc = [[IphoneIdentityViewController alloc] initWithNibName:@"IphoneIdentityViewController" bundle:nil];
    idvc.role = role;
    [self pushViewController:idvc animated:YES];
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
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    NSArray* decks = self.decks[indexPath.section];
    Deck* deck = decks[indexPath.row];
    
    cell.textLabel.text = deck.name;
    
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
