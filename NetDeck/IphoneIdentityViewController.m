//
//  IphoneIdentityViewController.m
//  Net Deck
//
//  Created by Gereon Steffens on 18.08.15.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

#import "NRNavigationController.h"
#import "IphoneIdentityViewController.h"
#import "EditDeckViewController.h"
#import "ImageCache.h"
#import "CardManager.h"
#import "Deck.h"
#import "Faction.h"
#import "SettingsKeys.h"
#import "CardSets.h"

@interface IphoneIdentityViewController ()

@property Card* selectedIdentity;
@property NSIndexPath* selectedIndexPath;
@property NSMutableArray* identities;
@property NSArray* factionNames;

@end

@implementation IphoneIdentityViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor colorWithPatternImage:[ImageCache hexTile]];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.backgroundColor = [UIColor clearColor];
    
    UITapGestureRecognizer* tableTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
    tableTap.numberOfTapsRequired = 2;
    [self.tableView addGestureRecognizer:tableTap];
    
    self.title = l10n(@"Choose Identity");
    
    self.okButton.enabled = self.deck != nil;
    
    self.selectedIdentity = self.deck.identity;
    
    [self initIdentities];
}

- (void)initIdentities
{
    NSMutableArray* factions = [[Faction factionsForRole:self.role] mutableCopy];
    // remove entries for "none" and "neutral"
    [factions removeObject:[Faction name:NRFactionNone]];
    
    // move 'neutral' to the end
    NSString* neutral = [Faction name:NRFactionNeutral];
    [factions removeObject:neutral];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:USE_DRAFT_IDS])
    {
        [factions addObject:neutral];
    }

    self.identities = [NSMutableArray array];
    self.factionNames = [NSArray arrayWithArray:factions];
    
    self.selectedIndexPath = nil;
    NSSet* disabledSetCodes = [CardSets disabledSetCodes];
    
    NSArray* identities = [CardManager identitiesForRole:self.role];
    for (int i=0; i<factions.count; ++i)
    {
        [self.identities addObject:[NSMutableArray array]];
        
        for (int j=0; j<identities.count; ++j)
        {
            Card* card = identities[j];
            if ([disabledSetCodes containsObject:card.setCode])
            {
                continue;
            }
            
            if ([[factions objectAtIndex:i] isEqualToString:card.factionStr])
            {
                NSMutableArray* arr = self.identities[i];
                [arr addObject:card];
                
                if ([self.selectedIdentity isEqual:card])
                {
                    self.selectedIndexPath = [NSIndexPath indexPathForRow:arr.count-1 inSection:i];
                }
            }
        }
    }
    
    NSAssert(self.identities.count == self.factionNames.count, @"count mismatch");
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.selectedIndexPath)
    {
        [self.tableView selectRowAtIndexPath:self.selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
    }
}

-(void) doubleTap:(UITapGestureRecognizer*)gesture
{
    if (UIGestureRecognizerStateEnded != gesture.state)
    {
        return;
    }
    [self okClicked:nil];
}

-(void) okClicked:(id)sender
{
    if (self.deck)
    {
        [self.deck addCard:self.selectedIdentity copies:1];
        // don't call [self.navController popViewControllerAnimated:YES] here - this will pop two VCs
        // instead, call the nav bar delegate from NRNavigationController to do
        UINavigationBar* navBar = self.navigationController.navigationBar;
        UINavigationItem* navItem = self.navigationController.navigationItem;
        [navBar.delegate navigationBar:navBar shouldPopItem:navItem];
    }
    else
    {
        Deck* deck = [[Deck alloc] init];
        deck.role = self.role;
        if (self.selectedIdentity)
        {
            [deck addCard:self.selectedIdentity copies:1];
        }
        
        NSInteger seq = [[NSUserDefaults standardUserDefaults] integerForKey:FILE_SEQ] + 1;
        deck.name = [NSString stringWithFormat:@"Deck #%ld", (long)seq];

        EditDeckViewController* edit = [[EditDeckViewController alloc] initWithNibName:@"EditDeckViewController" bundle:nil];
        NRNavigationController* nc = (NRNavigationController*)self.navigationController;
        nc.deckEditor = edit;
        edit.deck = deck;
        
        NSMutableArray* vcs = self.navigationController.viewControllers.mutableCopy;
        [vcs removeLastObject];
        [vcs addObject:edit];
        [self.navigationController setViewControllers:vcs animated:YES];
    }
}

#pragma mark - tableview

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray* arr = self.identities[section];
    return arr.count;
}

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.identities.count;
}

-(NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.factionNames[section];
}

-(void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.textLabel.font = [UIFont systemFontOfSize:17];
    cell.backgroundColor = [UIColor whiteColor];
    if ([indexPath compare:self.selectedIndexPath] == NSOrderedSame)
    {
        cell.textLabel.font = [UIFont boldSystemFontOfSize:17];
        cell.backgroundColor = [UIColor colorWithWhite:.97 alpha:1];
    }
}

-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* cellIdentifier = @"idCell";
    
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    Card* card = [self.identities objectAtIndexPath:indexPath];
    cell.textLabel.text = card.name;
    cell.textLabel.textColor = card.factionColor;
 
    if (self.role == NRRoleRunner)
    {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%d/%d - %d Link", card.minimumDecksize, card.influenceLimit, card.baseLink];
    }
    else
    {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%d/%d", card.minimumDecksize, card.influenceLimit];
    }
    
    return cell;
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Card* card = [self.identities objectAtIndexPath:indexPath];
    self.selectedIdentity = card;
    
    NSMutableArray* reload = [NSMutableArray array];
    [reload addObject:indexPath];
    if (self.selectedIndexPath)
    {
        [reload addObject:self.selectedIndexPath];
    }
    self.selectedIndexPath = indexPath;
    [self.tableView reloadRowsAtIndexPaths:reload withRowAnimation:UITableViewRowAnimationNone];
    
    self.okButton.enabled = YES;
}


@end
