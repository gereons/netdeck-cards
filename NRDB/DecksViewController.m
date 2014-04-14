//
//  DecksViewController.m
//  NRDB
//
//  Created by Gereon Steffens on 13.04.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "DecksViewController.h"
#import "DeckCell.h"
#import "DeckManager.h"
#import "Deck.h"
#import "ImageCache.h"
#import "Faction.h"
#import "Notifications.h"
#import "ImportDecksViewController.h"
#import "SettingsKeys.h"

typedef NS_ENUM(NSInteger, SortType) {
    SortDate, SortFaction, SortA_Z
};
typedef NS_ENUM(NSInteger, FilterType) {
    FilterAll, FilterRunner, FilterCorp
};

@interface DecksViewController ()

@property NRRole role;
@property SortType sortType;
@property NSMutableArray* decks;
@property NSDateFormatter *dateFormatter;
@property UIActionSheet* popup;

@end

@implementation DecksViewController

- (id) init
{
    if ((self = [self initWithNibName:@"DecksViewController" bundle:nil]))
    {
        self.role = NRRoleNone;
        self.sortType = SortA_Z;
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setDateStyle:NSDateFormatterLongStyle];
        [self.dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.parentViewController.view.backgroundColor = [UIColor colorWithPatternImage:[ImageCache hexTile]];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.backgroundColor = [UIColor clearColor];
    [self.tableView registerNib:[UINib nibWithNibName:@"DeckCell" bundle:nil] forCellReuseIdentifier:@"deckCell"];
    
    UINavigationItem* topItem = self.navigationController.navigationBar.topItem;
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:l10n(@"Decks")
                                      style:UIBarButtonItemStylePlain
                                     target:nil
                                     action:nil];
    
    UISegmentedControl* sortControl = [[UISegmentedControl alloc] initWithItems:@[ l10n(@"Date"), l10n(@"Faction"), l10n(@"A-Z") ]];
    sortControl.selectedSegmentIndex = SortA_Z;
    [sortControl addTarget:self action:@selector(sortChanged:) forControlEvents:UIControlEventValueChanged];
    
    UISegmentedControl* filterControl = [[UISegmentedControl alloc] initWithItems:@[ l10n(@"All"), l10n(@"Runner"), l10n(@"Corp") ]];
    filterControl.selectedSegmentIndex = FilterAll;
    [filterControl addTarget:self action:@selector(filterChanged:) forControlEvents:UIControlEventValueChanged];
    
    topItem.leftBarButtonItems = @[
        [[UIBarButtonItem alloc] initWithCustomView:sortControl],
        [[UIBarButtonItem alloc] initWithCustomView:filterControl]
    ];
    
    topItem.rightBarButtonItems = @[
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(newDeck:)],
        [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"702-import"] style:UIBarButtonItemStylePlain target:self action:@selector(importDecks:)],
    ];
    
    // [self updateDecks];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self updateDecks];
}

-(void) sortChanged:(UISegmentedControl*)sender
{
    if (self.popup)
    {
        [self.popup dismissWithClickedButtonIndex:self.popup.cancelButtonIndex animated:NO];
    }
    self.sortType = sender.selectedSegmentIndex;
    [self updateDecks];
}

-(void) filterChanged:(UISegmentedControl*)sender
{
    if (self.popup)
    {
        [self.popup dismissWithClickedButtonIndex:self.popup.cancelButtonIndex animated:NO];
    }
    switch (sender.selectedSegmentIndex) {
        case FilterAll:
            self.role = NRRoleNone;
            break;
        case FilterRunner:
            self.role = NRRoleRunner;
            break;
        case FilterCorp:
            self.role = NRRoleCorp;
            break;
    }
    [self updateDecks];
}

-(void) newDeck:(UIBarButtonItem*)sender
{
    if (self.popup)
    {
        [self.popup dismissWithClickedButtonIndex:self.popup.cancelButtonIndex animated:NO];
    }
    else
    {
        self.popup = [[UIActionSheet alloc] initWithTitle:nil
                                                 delegate:self
                                        cancelButtonTitle:@""
                                   destructiveButtonTitle:nil
                                        otherButtonTitles:l10n(@"New Runner Deck"), l10n(@"New Corp Deck"), nil];
    
        [self.popup showFromBarButtonItem:sender animated:NO];
    }
}

-(void) importDecks:(UIBarButtonItem*)sender
{
    BOOL useDropbox = [[NSUserDefaults standardUserDefaults] boolForKey:USE_DROPBOX];
    
    if (!useDropbox)
    {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:l10n(@"Import Decks") message:l10n(@"Connect to your Dropbox account first.") delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
        return;
    }
    
    ImportDecksViewController* import = [[ImportDecksViewController alloc] init];
    [self.navigationController pushViewController:import animated:NO];
}

-(void) actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    NSNumber* role;
    switch (buttonIndex)
    {
        case 0: // new runner
            role = @(NRRoleRunner);
            break;
        case 1: // new corp
            role = @(NRRoleCorp);
            break;
    }
    if (role)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:NEW_DECK object:self userInfo:@{ @"role": role}];
    }
    
    self.popup = nil;
    return;
}

-(void) updateDecks
{
    NSArray* decks = [DeckManager decksForRole:self.role];
    
    switch (self.sortType)
    {
        case SortA_Z:
            decks = [decks sortedArrayUsingComparator:^NSComparisonResult(Deck* d1, Deck* d2) {
                return [[d1.name lowercaseString] compare:[d2.name lowercaseString]];
            }];
            break;
        case SortDate:
            decks = [decks sortedArrayUsingComparator:^NSComparisonResult(Deck* d1, Deck* d2) {
                return [d2.lastModified compare:d1.lastModified];
            }];
            break;
        case SortFaction:
            decks = [decks sortedArrayUsingComparator:^NSComparisonResult(Deck* d1, Deck* d2) {
                NSString* faction1 = [Faction name:d1.identity.faction];
                NSString* faction2 = [Faction name:d2.identity.faction];
                return [faction1 compare:faction2];
            }];
            break;
    }
    self.decks = [decks mutableCopy];
    [self.tableView reloadData];
}


#pragma mark tableview


-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DeckCell* cell = [tableView dequeueReusableCellWithIdentifier:@"deckCell" forIndexPath:indexPath];
    
    Deck* deck = self.decks[indexPath.row];
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
    
    NSString* summary = [NSString stringWithFormat:l10n(@"%d Cards · %d Influence"), deck.size, deck.influence];
    cell.summaryLabel.text = summary;
    BOOL valid = [deck checkValidity].count == 0;
    cell.summaryLabel.textColor = valid ? [UIColor blackColor] : [UIColor redColor];
    
    cell.dateLabel.text = [self.dateFormatter stringFromDate:deck.lastModified];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Deck* deck = [self.decks objectAtIndex:indexPath.row];
    
    TF_CHECKPOINT(@"load deck");
    
    NSDictionary* userInfo = @{
                               @"filename" : deck.filename,
                               @"role" : @(deck.role)
                               };
    [[NSNotificationCenter defaultCenter] postNotificationName:LOAD_DECK object:self userInfo:userInfo];
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        Deck* deck = [self.decks objectAtIndex:indexPath.row];
        
        [self.decks removeObjectAtIndex:indexPath.row];
        [DeckManager removeFile:deck.filename];
        
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationLeft];
        [self.tableView endUpdates];
    }
}

-(BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.decks.count;
}

@end
