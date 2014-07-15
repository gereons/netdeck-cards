//
//  CompareDecksList.m
//  NRDB
//
//  Created by Gereon Steffens on 15.07.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <SDCAlertView.h>

#import "CompareDecksList.h"
#import "DeckCell.h"
#import "Deck.h"
#import "DeckDiffViewController.h"
#import "DeckManager.h"

@interface CompareDecksList ()

@property NSMutableArray* decksToDiff;

@property UIBarButtonItem* diffButton;

@end

@implementation CompareDecksList

-(void) viewDidLoad
{
    [super viewDidLoad];
    self.decksToDiff = [NSMutableArray array];
    
    self.diffButton = [[UIBarButtonItem alloc] initWithTitle:l10n(@"Compare") style:UIBarButtonItemStylePlain target:self action:@selector(diffDecks:)];
    self.diffButton.enabled = NO;
    
    UINavigationItem* topItem = self.navigationController.navigationBar.topItem;
    topItem.rightBarButtonItems = @[ self.diffButton ];
}

-(void) diffDecks:(id)sender
{
    NSAssert(_decksToDiff.count == 2, @"count must be 2");
    
    Deck* deck1 = [DeckManager loadDeckFromPath:_decksToDiff[0]];
    Deck* deck2 = [DeckManager loadDeckFromPath:_decksToDiff[1]];
    
    if (deck1.role != deck2.role)
    {
        [SDCAlertView alertWithTitle:nil message:l10n(@"Both decks must be for the same side.") buttons:@[ l10n(@"OK")]];
        return;
    }
    
    [DeckDiffViewController showForDecks:deck1 deck2:deck2 inViewController:self];
}

#pragma mark table view

-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DeckCell* cell = (DeckCell*)[super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    NSArray* decks = self.decks[indexPath.section];
    Deck* deck = decks[indexPath.row];
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    if ([self.decksToDiff containsObject:deck.filename])
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    
    return cell;
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray* decks = self.decks[indexPath.section];
    Deck* deck = decks[indexPath.row];
    
    if ([self.decksToDiff containsObject:deck.filename])
    {
        [self.decksToDiff removeObject:deck.filename];
    }
    else
    {
        [self.decksToDiff addObject:deck.filename];
    }
    
    while (self.decksToDiff.count > 2)
    {
        [self.decksToDiff removeObjectAtIndex:0];
    }
    
    self.diffButton.enabled = self.decksToDiff.count == 2;
    
    [self.tableView reloadData];
}

@end
