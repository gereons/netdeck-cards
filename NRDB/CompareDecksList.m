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
@property NSMutableArray* names;

@property UIBarButtonItem* diffButton;
@property UIToolbar* toolbar;
@property UILabel* footerLabel;

@property NRRole selectedRole;

@end

@implementation CompareDecksList

-(void) viewDidLoad
{
    [super viewDidLoad];
    self.decksToDiff = [NSMutableArray array];
    self.names = [NSMutableArray array];
    self.selectedRole = NRRoleNone;
    
    self.diffButton = [[UIBarButtonItem alloc] initWithTitle:l10n(@"Compare") style:UIBarButtonItemStylePlain target:self action:@selector(diffDecks:)];
    self.diffButton.enabled = NO;
    
    UINavigationItem* topItem = self.navigationController.navigationBar.topItem;
    topItem.rightBarButtonItems = @[ self.diffButton ];

    // add toolbar as footer
    self.toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 728, 703, 40)];
    self.footerLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 683, 40)];
    self.footerLabel.font = [UIFont systemFontOfSize:15];
    [self.toolbar addSubview:self.footerLabel];
    self.footerLabel.text = l10n(@"Select two decks to compare them");
    self.footerLabel.userInteractionEnabled = YES;
    UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(footerClicked:)];
    [self.footerLabel addGestureRecognizer:tap];
    [self.view addSubview:self.toolbar];
    
    // adjust tableview
    UIEdgeInsets insets = self.tableView.contentInset;
    insets.bottom = 40;
    self.tableView.contentInset = insets;
}

-(void) diffDecks:(id)sender
{
    NSAssert(self.decksToDiff.count == 2, @"count must be 2");
    
    Deck* deck1 = [DeckManager loadDeckFromPath:self.decksToDiff[0]];
    Deck* deck2 = [DeckManager loadDeckFromPath:self.decksToDiff[1]];
    
    if (deck1.role != deck2.role)
    {
        [SDCAlertView alertWithTitle:nil message:l10n(@"Both decks must be for the same side.") buttons:@[ l10n(@"OK")] ];
        return;
    }
    
    [DeckDiffViewController showForDecks:deck1 deck2:deck2 inViewController:self];
}

-(void) footerClicked:(id)sender
{
    if (self.decksToDiff.count == 2)
    {
        [self diffDecks:nil];
    }
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
    
    if (self.selectedRole != deck.role)
    {
        [self.decksToDiff removeAllObjects];
        [self.names removeAllObjects];
    }
    self.selectedRole = deck.role;
    
    if ([self.decksToDiff containsObject:deck.filename])
    {
        [self.decksToDiff removeObject:deck.filename];
        [self.names removeObject:deck.name];
    }
    else
    {
        [self.decksToDiff addObject:deck.filename];
        [self.names addObject:deck.name];
    }
    
    while (self.decksToDiff.count > 2)
    {
        [self.decksToDiff removeObjectAtIndex:0];
        [self.names removeObjectAtIndex:0];
    }
    
    self.diffButton.enabled = self.decksToDiff.count == 2;
    
    switch (self.decksToDiff.count)
    {
        case 0:
            self.footerLabel.text = l10n(@"Select two decks to compare them");
            self.footerLabel.textColor = [UIColor blackColor];
            break;
        case 1:
            self.footerLabel.text = [NSString stringWithFormat:l10n(@"Selected ‘%@’, select one more to compare"), self.names[0]];
            self.footerLabel.textColor = [UIColor blackColor];
            break;
        case 2:
            self.footerLabel.text = [NSString stringWithFormat:l10n(@"Selected ‘%@’ and ‘%@’, tap to compare"), self.names[0], self.names[1]];
            self.footerLabel.textColor = UIColorFromRGB(0x007aff);
            break;
    }
    
    [self.tableView reloadData];
}

@end
