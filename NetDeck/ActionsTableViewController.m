//
//  ActionsTableViewController.m
//  Net Deck
//
//  Created by Gereon Steffens on 17.05.13.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

@import SDCAlertView;
@import AFNetworking;

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
#import "SettingsKeys.h"
#import "DataDownload.h"
#import "CardUpdateCheck.h"

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
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void) viewDidLoad
{
    [super viewDidLoad];

    self.tableView.scrollEnabled = NO;
    
    self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
    
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
    [super viewDidAppear:animated];
    
    [CardUpdateCheck checkCardsAvailable];
    
#if !DEBUG
    // first start with this version?
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    // [defaults setObject:@"" forKey:LAST_START_VERSION];
    NSString* lastVersion = [defaults stringForKey:LAST_START_VERSION];
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
    
    if (![CardManager cardsAvailable] || ![CardSets setsAvailable])
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

#pragma mark notifications

-(void)loadDeck:(NSNotification*) notification
{
    NSDictionary* userInfo = notification.userInfo;
    
    NRRole role = [[userInfo objectForKey:@"role"] intValue];
    NSString* filename = [userInfo objectForKey:@"filename"];
    
    CardFilterViewController *filter = [[CardFilterViewController alloc] initWithRole:role andFile:filename];
    
    UINavigationController* nc = self.navigationController;
    [nc pushViewController:filter animated:NO];
}

-(void)newDeck:(NSNotification*) notification
{
    UINavigationController* nc = self.navigationController;

    NSDictionary* userInfo = notification.userInfo;
    CardFilterViewController* filter;
    
    if ([notification.name isEqualToString:BROWSER_NEW])
    {
        Card* card = [CardManager cardByCode:[userInfo objectForKey:@"code"]];
        Deck* deck = [[Deck alloc] init];
        deck.role = card.role;
        [deck addCard:card copies:1];
        
        filter = [[CardFilterViewController alloc] initWithRole:deck.role andDeck:deck];
    }
    else
    {
        NRRole role = [[userInfo objectForKey:@"role"] intValue];
        filter = [[CardFilterViewController alloc] initWithRole:role];
    }
    
    if (nc.viewControllers.count > 1)
    {
        [nc popToRootViewControllerAnimated:NO];
    }
    
    [nc pushViewController:filter animated:NO];
}

-(void)importDeckFromClipboard:(NSNotification*) notification
{
    NSDictionary* userInfo = notification.userInfo;
    Deck* deck = [userInfo objectForKey:@"deck"];
    NRRole role = deck.identity.role;
    
    [deck saveToDisk];
    
    CardFilterViewController *filter = [[CardFilterViewController alloc] initWithRole:role andDeck:deck];
    
    UINavigationController* nc = self.navigationController;
    
    if (nc.viewControllers.count > 1)
    {
        [nc popToRootViewControllerAnimated:NO];
    }
    [nc pushViewController:filter animated:NO];
}

-(void)loadCards:(id) sender
{
    [self.tableView reloadData];
}

-(void) listDecks:(NSNotification*)sender
{
    [self.navigationController popToRootViewControllerAnimated:NO];
    self.searchForCard = [CardManager cardByCode:[sender.userInfo objectForKey:@"code"]];
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
    
    BOOL cardsAvailable = [CardManager cardsAvailable] && [CardSets setsAvailable];
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
            cell.textLabel.enabled = cardsAvailable;
            break;
        case NRMenuDecks:
            cell.textLabel.text = l10n(@"Decks");
            cell.textLabel.enabled = cardsAvailable;
            break;
        case NRMenuCardBrowser:
            cell.textLabel.text = l10n(@"Card Browser");
            cell.textLabel.enabled = cardsAvailable;
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
    
    self.settings = nil;
    
    // Get a reference to the DetailViewManager.
    // DetailViewManager is the delegate of our split view.
    DetailViewManager *detailViewManager = (DetailViewManager*)self.splitViewController.delegate;

    switch (indexPath.row)
    {
        case NRMenuDecks:
        {
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
            CompareDecksList* decks = [[CompareDecksList alloc] init];
            self.snc = [[SubstitutableNavigationController alloc] initWithRootViewController:decks];
            detailViewManager.detailViewController = self.snc;
            break;
        }
            
        case NRMenuCardBrowser:
        {
            UINavigationController* nc = self.navigationController;
            BrowserFilterViewController* browser = [[BrowserFilterViewController alloc] init];
            [nc pushViewController:browser animated:NO];
            break;
        }
            
        case NRMenuSettings:
        {
            self.settings = [[SettingsViewController alloc] init];
            self.snc = [[SubstitutableNavigationController alloc] initWithRootViewController:self.settings.iask];
            detailViewManager.detailViewController = self.snc;
            break;
        }
            
        case NRMenuAbout:
        {
            AboutViewController* about = [[AboutViewController alloc] initWithNibName:@"AboutView" bundle:nil];
            
            self.snc = [[SubstitutableNavigationController alloc] initWithRootViewController:about];
            detailViewManager.detailViewController = self.snc;
            break;
        }
    }
}

@end
