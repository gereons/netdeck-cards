//
//  ActionsTableViewController.m
//  NRDB
//
//  Created by Gereon Steffens on 17.05.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <SDCAlertView.h>
#import "NRAlertView.h"
#import "AppDelegate.h"
#import "ActionsTableViewController.h"
#import "EmptyDetailViewController.h"
#import "DetailViewManager.h"
#import "SettingsViewController.h"
#import "AboutViewController.h"
#import "CardFilterViewController.h"
#import "BrowserFilterViewController.h"
#import "SavedDecksList.h"
#import "CompareDecksList.h"
#import "Notifications.h"
#import "CardManager.h"
#import "SettingsKeys.h"
#import "Deck.h"
#import "NRNavigationController.h"
#import "DataDownload.h"
#import "DeckManager.h"

typedef NS_ENUM(NSInteger, NRMenuItem)
{
    NRMenuDecks,
    NRMenuDeckDiff,
    NRMenuCardBrowser,
    NRMenuSettings,
    NRMenuAbout,
    
    NRMenuItemCount
};

@interface ActionsTableViewController()

@property SubstitutableNavigationController* snc;
@property SettingsViewController* settings;
@property Card* searchForCard;

@end

@implementation ActionsTableViewController

-(void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void) viewDidLoad
{
    [super viewDidLoad];

    self.tableView.scrollEnabled = NO;
    
    self.title = @"Net Deck";
    
    UIView* tableFoot = [[UIView alloc] initWithFrame:CGRectZero];
    [self.tableView setTableFooterView:tableFoot];
    
    UIToolbar* footer = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 664, 320, 40)];
    // footer.text = @"footer";
    [self.view addSubview:footer];
    
    UILabel* footerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0, 320, 40)];
    
    footerLabel.text = [AppDelegate appVersion];
    footerLabel.textAlignment = NSTextAlignmentCenter;
    footerLabel.backgroundColor = [UIColor clearColor];
    footerLabel.font = [UIFont systemFontOfSize:14];
    [footer addSubview:footerLabel];
    
    // check if card data is available
    if (![CardManager cardsAvailable])
    {
        SDCAlertView* alert = [SDCAlertView alertWithTitle:l10n(@"No Card Data")
                                                   message:l10n(@"To use this app, you must first download card data.")
                                                   buttons:@[l10n(@"Not now"), l10n(@"Download")]];
        
        alert.didDismissHandler = ^(NSInteger buttonIndex) {
            if (buttonIndex == 1)
            {
                [DataDownload downloadCardData];
            }
        };

    }
    
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(loadDeck:) name:LOAD_DECK object:nil];
    [nc addObserver:self selector:@selector(newDeck:) name:NEW_DECK object:nil];
    [nc addObserver:self selector:@selector(newDeck:) name:BROWSER_NEW object:nil];
    [nc addObserver:self selector:@selector(importDeckFromClipboard:) name:IMPORT_DECK object:nil];
    [nc addObserver:self selector:@selector(loadCards:) name:LOAD_CARDS object:nil];
    [nc addObserver:self selector:@selector(loadCards:) name:DROPBOX_CHANGED object:nil];
    [nc addObserver:self selector:@selector(listDecks:) name:BROWSER_FIND object:nil];
}

-(void) viewDidAppear:(BOOL)animated
{
    [self checkCardUpdate];
    
    [super viewDidAppear:animated];

#if !DEBUG
    // first start with this version?
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    // [defaults setObject:@"" forKey:LAST_START_VERSION];
    NSString* lastVersion = [defaults objectForKey:LAST_START_VERSION];
    NSString* thisVersion = [AppDelegate appVersion];
    if ([thisVersion isEqualToString:lastVersion])
    {
        // yes, first start. show "about" tab
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:NRMenuAbout inSection:0];
        [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
        [defaults setObject:thisVersion forKey:LAST_START_VERSION];
        [defaults synchronize];
        return;
    }
#endif
    
    if (![CardManager cardsAvailable])
    {
        [self resetDetailView];
        return;
    }
    
    // select Decks view
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:NRMenuDecks inSection:0];
    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
}

-(void) resetDetailView
{
    EmptyDetailViewController *empty = [[EmptyDetailViewController alloc] initWithNibName:@"EmptyDetailView" bundle:nil];
    
    self.snc = [[SubstitutableNavigationController alloc] initWithRootViewController:empty];
    
    DetailViewManager *detailViewManager = (DetailViewManager*)self.splitViewController.delegate;
    detailViewManager.detailViewController = self.snc;
}

#pragma card data update

-(void) checkCardUpdate
{
    NSString* next = [[NSUserDefaults standardUserDefaults] objectForKey:NEXT_DOWNLOAD];
    
    NSDateFormatter *fmt = [NSDateFormatter new];
    [fmt setDateStyle:NSDateFormatterShortStyle]; // z.B. 08.10.2008
    [fmt setTimeStyle:NSDateFormatterNoStyle];
    
    NSDate* scheduled = [fmt dateFromString:next];
    NSDate* now = [NSDate date];
    
    if (APP_ONLINE && [scheduled compare:now] == NSOrderedAscending)
    {
        SDCAlertView* alert = [SDCAlertView alertWithTitle:l10n(@"Update cards")
                                                   message:l10n(@"Card data may be out of date. Download now?")
                                                   buttons:@[l10n(@"Later"), l10n(@"OK")]];
        alert.didDismissHandler = ^(NSInteger buttonIndex) {
            if (buttonIndex == 0) // later
            {
                NSDateFormatter *fmt = [NSDateFormatter new];
                [fmt setDateStyle:NSDateFormatterShortStyle]; // dd.mm.yyyy
                [fmt setTimeStyle:NSDateFormatterNoStyle];
                // ask again tomorrow
                NSDate* next = [NSDate dateWithTimeIntervalSinceNow:24*60*60];
                
                [[NSUserDefaults standardUserDefaults] setObject:[fmt stringFromDate:next] forKey:NEXT_DOWNLOAD];
            }
            if (buttonIndex == 1) // ok
            {
                [DataDownload downloadCardData];
            }
        };
    }
}

#pragma mark notifications

-(void)loadDeck:(NSNotification*) notification
{
    NSDictionary* userInfo = notification.userInfo;
    
    NRRole role = [[userInfo objectForKey:@"role"] intValue];
    NSString* filename = [userInfo objectForKey:@"filename"];
    
    CardFilterViewController *filter = [[CardFilterViewController alloc] initWithRole:role andFile:filename];
    NSAssert([self.navigationController isKindOfClass:[NRNavigationController class]], @"oops");
    
    NRNavigationController* nc = (NRNavigationController*)self.navigationController;
    nc.deckListViewController = filter.deckListViewController;
    
    [nc pushViewController:filter animated:NO];
}

-(void)newDeck:(NSNotification*) notification
{
    NSAssert([self.navigationController isKindOfClass:[NRNavigationController class]], @"oops");
    NRNavigationController* nc = (NRNavigationController*)self.navigationController;

    NSDictionary* userInfo = notification.userInfo;
    CardFilterViewController* filter;
    
    if ([notification.name isEqualToString:BROWSER_NEW])
    {
        Card* card = [Card cardByCode:[userInfo objectForKey:@"code"]];
        Deck* deck = [[Deck alloc] init];
        deck.role = card.role;
        if (card.type == NRCardTypeIdentity)
        {
            deck.identity = card;
        }
        else
        {
            [deck addCard:card copies:1];
        }
        
        filter = [[CardFilterViewController alloc] initWithRole:deck.role andDeck:deck];
        [nc popToRootViewControllerAnimated:NO];
    }
    else
    {
        NRRole role = [[userInfo objectForKey:@"role"] intValue];
        filter = [[CardFilterViewController alloc] initWithRole:role];
    }
    
    nc.deckListViewController = filter.deckListViewController;
    [nc pushViewController:filter animated:NO];
}

-(void)importDeckFromClipboard:(NSNotification*) notification
{
    NSDictionary* userInfo = notification.userInfo;
    Deck* deck = [userInfo objectForKey:@"deck"];
    NRRole role = deck.identity.role;
    
    [DeckManager saveDeck:deck];
    
    CardFilterViewController *filter = [[CardFilterViewController alloc] initWithRole:role andDeck:deck];
    NSAssert([self.navigationController isKindOfClass:[NRNavigationController class]], @"oops");
    
    NRNavigationController* nc = (NRNavigationController*)self.navigationController;
    nc.deckListViewController = filter.deckListViewController;
    
    [nc popToRootViewControllerAnimated:NO];
    [nc pushViewController:filter animated:NO];
}

-(void)loadCards:(id) sender
{
    [self.tableView reloadData];
}

-(void) listDecks:(NSNotification*)sender
{
    [self.navigationController popToRootViewControllerAnimated:NO];
    self.searchForCard = [Card cardByCode:[sender.userInfo objectForKey:@"code"]];
}

#pragma mark Table view data source

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section
{
    return NRMenuItemCount;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellIdentifier = @"actions";
    
    // Dequeue or create a cell of the appropriate type.
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    // Set appropriate labels for the cells.
    switch (indexPath.row)
    {
        case NRMenuAbout:
            cell.textLabel.text = l10n(@"About");
            break;
        case NRMenuSettings:
            cell.textLabel.text = l10n(@"Settings");
            break;
        case NRMenuDeckDiff:
            cell.textLabel.text = l10n(@"Compare Decks");
            cell.textLabel.enabled = [CardManager cardsAvailable];
            break;
        case NRMenuDecks:
            cell.textLabel.text = l10n(@"Decks");
            cell.textLabel.enabled = [CardManager cardsAvailable];
            break;
        case NRMenuCardBrowser:
            cell.textLabel.text = l10n(@"Card Browser");
            cell.textLabel.enabled = [CardManager cardsAvailable];
            break;
    }
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.font = [UIFont systemFontOfSize:17];
    
    return cell;
}

#pragma mark Table view selection

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    return cell.textLabel.enabled ? indexPath : nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    if (!cell.textLabel.enabled)
    {
        return;
    }
    
    // Get a reference to the DetailViewManager.
    // DetailViewManager is the delegate of our split view.
    DetailViewManager *detailViewManager = (DetailViewManager*)self.splitViewController.delegate;

    switch (indexPath.row)
    {
        case NRMenuDecks:
        {
            TF_CHECKPOINT(@"decks");
            SavedDecksList* decks;
            if (self.searchForCard == nil)
            {
                decks = [[SavedDecksList alloc] init];
            }
            else
            {
                decks = [[SavedDecksList alloc] initWithCardFilter:self.searchForCard];
                self.searchForCard = nil;
            }
            self.snc = [[SubstitutableNavigationController alloc] initWithRootViewController:decks];
            detailViewManager.detailViewController = self.snc;
            break;
        }
            
        case NRMenuDeckDiff:
        {
            TF_CHECKPOINT(@"deck diff");
            CompareDecksList* decks = [[CompareDecksList alloc] init];
            self.snc = [[SubstitutableNavigationController alloc] initWithRootViewController:decks];
            detailViewManager.detailViewController = self.snc;
            break;
        }
            
        case NRMenuCardBrowser:
        {
            TF_CHECKPOINT(@"card browser");
            
            NRNavigationController* nc = (NRNavigationController*)self.navigationController;
            nc.deckListViewController = nil;
            
            BrowserFilterViewController* browser = [[BrowserFilterViewController alloc] init];
            [nc pushViewController:browser animated:NO];
            break;
        }
            
        case NRMenuSettings:
        {
            TF_CHECKPOINT(@"settings");
            self.settings = [[SettingsViewController alloc] initWithNibName:@"SettingsViewController" bundle:nil];
            self.snc = [[SubstitutableNavigationController alloc] initWithRootViewController:self.settings];
            detailViewManager.detailViewController = self.snc;
            break;
        }
            
        case NRMenuAbout:
        {
            TF_CHECKPOINT(@"about");
            AboutViewController* about = [[AboutViewController alloc] initWithNibName:@"AboutView" bundle:nil];
            
            self.snc = [[SubstitutableNavigationController alloc] initWithRootViewController:about];
            detailViewManager.detailViewController = self.snc;
            break;
        }
    }
}

@end
