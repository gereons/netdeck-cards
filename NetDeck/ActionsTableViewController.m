//
//  ActionsTableViewController.m
//  Net Deck
//
//  Created by Gereon Steffens on 17.05.13.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

#import "ActionsTableViewController.h"
#import "SettingsViewController.h"
#import "AboutViewController.h"
#import "CardFilterViewController.h"
#import "BrowserFilterViewController.h"
#import "SavedDecksList.h"
#import "CompareDecksList.h"

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

@property UINavigationController* navController;
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
    
//    UIToolbar* footer = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 664, 320, 40)];
//    // footer.text = @"footer";
//    [self.view addSubview:footer];
//    
//    UILabel* footerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0, 320, 40)];
    
    [self.version setTitle:[AppDelegate appVersion]];
//    self.version.textAlignment = NSTextAlignmentCenter;
//    self.version.backgroundColor = [UIColor clearColor];
//    self.version.font = [UIFont systemFontOfSize:14];
    // [footer addSubview:footerLabel];
    
    
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(loadDeck:) name:Notifications.LOAD_DECK object:nil];
    [nc addObserver:self selector:@selector(newDeck:) name:Notifications.NEW_DECK object:nil];
    [nc addObserver:self selector:@selector(newDeck:) name:Notifications.BROWSER_NEW object:nil];
    [nc addObserver:self selector:@selector(importDeckFromClipboard:) name:Notifications.IMPORT_DECK object:nil];
    [nc addObserver:self selector:@selector(loadCards:) name:Notifications.LOAD_CARDS object:nil];
    [nc addObserver:self selector:@selector(loadCards:) name:Notifications.DROPBOX_CHANGED object:nil];
    [nc addObserver:self selector:@selector(listDecks:) name:Notifications.BROWSER_FIND object:nil];
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    BOOL displayedAlert = [CardUpdateCheck checkCardUpdateAvailable:self];
    
    if (!displayedAlert) {
        [AppUpdateCheck checkUpdate];
    }
    
#if !DEBUG
    // first start with this version?
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    // [defaults setObject:@"" forKey:LAST_START_VERSION];
    NSString* lastVersion = [defaults stringForKey:SettingsKeys.LAST_START_VERSION];
    NSString* thisVersion = [AppDelegate appVersion];
    if ([thisVersion isEqualToString:lastVersion])
    {
        // yes, first start. show "about" tab
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:NRMenuAbout inSection:0];
        [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
        [defaults setObject:thisVersion forKey:SettingsKeys.LAST_START_VERSION];
        [defaults synchronize];
        return;
    }
#endif
    
    if (![CardManager cardsAvailable] || ![PackManager packsAvailable])
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
    
    self.navController = [[UINavigationController alloc] initWithRootViewController:empty];
    
    DetailViewManager *detailViewManager = (DetailViewManager*)self.splitViewController.delegate;
    detailViewManager.detailViewController = self.navController;
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
    
    if ([notification.name isEqualToString:Notifications.BROWSER_NEW])
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

    id delegate = self.splitViewController.delegate;
    if ([delegate isKindOfClass:[DetailViewManager class]]) {
        DetailViewManager* manager = (DetailViewManager*)delegate;
        UIViewController* detail = manager.detailViewController;
        
        if ([detail.childViewControllers.firstObject isKindOfClass:[EmptyDetailViewController class]]) {
            NSIndexPath* indexPath = [NSIndexPath indexPathForRow:NRMenuDecks inSection:0];
            [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
        }
    }
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
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.font = [UIFont systemFontOfSize:17];
    }
    
    BOOL cardsAvailable = [CardManager cardsAvailable] && [PackManager packsAvailable];
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
    
    return cell;
}

#pragma mark Table view selection

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    if (!cell.textLabel.enabled)
    {
        [self resetDetailView];
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
            self.navController = [[UINavigationController alloc] initWithRootViewController:decks];
            detailViewManager.detailViewController = self.navController;
            break;
        }
            
        case NRMenuDeckDiff:
        {
            CompareDecksList* decks = [[CompareDecksList alloc] init];
            self.navController = [[UINavigationController alloc] initWithRootViewController:decks];
            detailViewManager.detailViewController = self.navController;
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
            self.navController = [[UINavigationController alloc] initWithRootViewController:self.settings.iask];
            detailViewManager.detailViewController = self.navController;
            break;
        }
            
        case NRMenuAbout:
        {
            AboutViewController* about = [[AboutViewController alloc] initWithNibName:@"AboutView" bundle:nil];
            
            self.navController = [[UINavigationController alloc] initWithRootViewController:about];
            detailViewManager.detailViewController = self.navController;
            break;
        }
    }
}

@end
