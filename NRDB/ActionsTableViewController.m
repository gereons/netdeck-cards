//
//  ActionsTableViewController.m
//  NRDB
//
//  Created by Gereon Steffens on 17.05.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <SVProgressHUD.h>

#import "ActionsTableViewController.h"
#import "EmptyDetailViewController.h"
#import "DetailViewManager.h"
#import "SettingsViewController.h"
#import "AboutViewController.h"
#import "FilteredCardViewController.h"
#import "CardEditorViewController.h"
#import "SavedDecksViewController.h"
#import "ImportDecksViewController.h"
#import "Notifications.h"
#import "CardData.h"
#import "SettingsKeys.h"
#import "Deck.h"
#import "NRNavigationController.h"
#import "DataDownload.h"
#import "DeckManager.h"

typedef NS_ENUM(NSInteger, NRMenuItem)
{
    NRMenuNewRunner,
    NRMenuNewCorp,
    NRMenuLoadRunner,
    NRMenuLoadCorp,
    NRMenuImportDecks,
    NRMenuSettings,
    NRMenuCardEditor,
    NRMenuAbout,
    
    NRMenuItemCount
};

@interface ActionsTableViewController()

@property NRMenuItem lastSelection;
@property SubstitutableNavigationController* snc;
@property SettingsViewController* settings;
@property NSString* appVersion;

@end

@implementation ActionsTableViewController

-(void) viewDidLoad
{
    [super viewDidLoad];

    self.lastSelection = -1;
    self.tableView.scrollEnabled = NO;
    
    self.title = l10n(@"Net Deck");
    
    UIView* tableFoot = [[UIView alloc] initWithFrame:CGRectZero];
    [self.tableView setTableFooterView:tableFoot];
    
    UIToolbar* footer = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 664, 320, 40)];
    // footer.text = @"footer";
    [self.view addSubview:footer];
    
    UILabel* footerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0, 320, 40)];
    
#if defined(DEBUG) || defined(ADHOC)
    // CFBundleVersion contains the git describe output
    self.appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
#else
    // CFBundleShortVersionString contains the main version
    self.appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
#endif
    
    footerLabel.text = [NSString stringWithFormat:@"Version %@", self.appVersion];
    footerLabel.textAlignment = NSTextAlignmentCenter;
    footerLabel.backgroundColor = [UIColor clearColor];
    footerLabel.font = [UIFont systemFontOfSize:14];
    [footer addSubview:footerLabel];
    
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(loadDeck:) name:LOAD_DECK object:nil];
    [nc addObserver:self selector:@selector(importDeckFromClipboard:) name:IMPORT_DECK object:nil];
    [nc addObserver:self selector:@selector(loadCards:) name:LOAD_CARDS object:nil];
    [nc addObserver:self selector:@selector(loadCards:) name:DROPBOX_CHANGED object:nil];
    
    // check if card data is available
    if (![CardData cardsAvailable])
    {
        NSString* msg = l10n(@"To use this app, you must first download card data from netrunnerdb.com");
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:l10n(@"No Card Data") message:msg delegate:self cancelButtonTitle:l10n(@"Not now") otherButtonTitles:l10n(@"Download"), nil];
        alert.tag = 0;
        [alert show];
    }
}

-(void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void) viewDidAppear:(BOOL)animated
{
    [self checkCardUpdate];
    
    [self resetDetailView];
    
    [super viewDidAppear:animated];
    
    if (self.lastSelection == NRMenuLoadRunner || self.lastSelection == NRMenuLoadCorp)
    {
        NSIndexPath* indexPath = [NSIndexPath indexPathForItem:self.lastSelection inSection:0];
        
        [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
    }
    
    // first start with this version?
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    // [defaults setObject:@"" forKey:LAST_START_VERSION];
    NSString* lastVersion = [defaults objectForKey:LAST_START_VERSION];
    if (![self.appVersion isEqualToString:lastVersion])
    {
        // yes, first start. show "about" tab, and do NOT load any previous saved state
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:NRMenuAbout inSection:0];
        [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        
        [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
        [defaults setObject:self.appVersion forKey:LAST_START_VERSION];
    }
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
    
    if ([scheduled compare:now] == NSOrderedAscending)
    {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:l10n(@"Update cards")
                                                        message:l10n(@"Card data may be out of date. Download now?")
                                                       delegate:self
                                              cancelButtonTitle:l10n(@"Later")
                                              otherButtonTitles:@"OK", nil];
        alert.tag = 1;
        [alert show];
    }
}

#pragma mark alerts

-(void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
    {
        [DataDownload downloadCardData];
    }
    
    // "later" in update alert?
    if (alertView.tag == 1 && buttonIndex == 0)
    {
        NSDateFormatter *fmt = [NSDateFormatter new];
        [fmt setDateStyle:NSDateFormatterShortStyle]; // z.B. 08.10.2008
        [fmt setTimeStyle:NSDateFormatterNoStyle];
        
        NSDate* next = [NSDate dateWithTimeIntervalSinceNow:24*60*60];
        
        [[NSUserDefaults standardUserDefaults] setObject:[fmt stringFromDate:next] forKey:NEXT_DOWNLOAD];
    }
}

#pragma mark notifications

-(void)loadDeck:(NSNotification*) notification
{
    NSDictionary* userInfo = notification.userInfo;
    
    NRRole role = [[userInfo objectForKey:@"role"] intValue];
    NSString* filename = [userInfo objectForKey:@"filename"];
    
    FilteredCardViewController *filter = [[FilteredCardViewController alloc] initWithRole:role andFile:filename];
    NSAssert([self.navigationController isKindOfClass:[NRNavigationController class]], @"oops");
    
    NRNavigationController* nc = (NRNavigationController*)self.navigationController;
    nc.deckListViewController = filter.deckListViewController;
    
    [self.navigationController pushViewController:filter animated:YES];
}

-(void)importDeckFromClipboard:(NSNotification*) notification
{
    NSDictionary* userInfo = notification.userInfo;
    Deck* deck = [userInfo objectForKey:@"deck"];
    NRRole role = deck.identity.role;
    
    [DeckManager saveDeck:deck];
    
    FilteredCardViewController *filter = [[FilteredCardViewController alloc] initWithRole:role andDeck:deck];
    NSAssert([self.navigationController isKindOfClass:[NRNavigationController class]], @"oops");
    
    NRNavigationController* nc = (NRNavigationController*)self.navigationController;
    nc.deckListViewController = filter.deckListViewController;
    
    [self.navigationController popToRootViewControllerAnimated:NO];
    [self.navigationController pushViewController:filter animated:YES];
}

-(void)loadCards:(id) sender
{
    [self.tableView reloadData];
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
    
    BOOL cardsAvailable = [CardData cardsAvailable];
    BOOL dropboxLinked = [[NSUserDefaults standardUserDefaults] boolForKey:USE_DROPBOX];
    
    // Set appropriate labels for the cells.
    switch (indexPath.row)
    {
        case NRMenuNewRunner:
            cell.textLabel.text = l10n(@"New Runner Deck");
            cell.textLabel.enabled = cardsAvailable;
            break;
        case NRMenuNewCorp:
            cell.textLabel.text = l10n(@"New Corp Deck");
            cell.textLabel.enabled = cardsAvailable;
            break;
        case NRMenuLoadRunner:
            cell.textLabel.text = l10n(@"Load Runner Deck");
            cell.textLabel.enabled = cardsAvailable;
            break;
        case NRMenuLoadCorp:
            cell.textLabel.text = l10n(@"Load Corp Deck");
            cell.textLabel.enabled = cardsAvailable;
            break;
        case NRMenuAbout:
            cell.textLabel.text = l10n(@"About");
            break;
        case NRMenuSettings:
            cell.textLabel.text = l10n(@"Settings");
            break;
        case NRMenuCardEditor:
            cell.textLabel.text = l10n(@"Card Editor");
            cell.textLabel.enabled = NO;
            break;
        case NRMenuImportDecks:
            cell.textLabel.text = l10n(@"Import Decks");
            cell.textLabel.enabled = cardsAvailable && dropboxLinked;
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

    self.lastSelection = indexPath.row;
    switch (indexPath.row)
    {
        case NRMenuNewRunner:
        {
            TF_CHECKPOINT(@"new runner deck");
            FilteredCardViewController *runner = [[FilteredCardViewController alloc] initWithRole:NRRoleRunner];
            [self.navigationController pushViewController:runner animated:YES];
            
            NSAssert([self.navigationController isKindOfClass:[NRNavigationController class]], @"oops");
        
            NRNavigationController* nc = (NRNavigationController*)self.navigationController;
            nc.deckListViewController = runner.deckListViewController;
            break;
        }
    
        case NRMenuNewCorp:
        {
            TF_CHECKPOINT(@"new corp deck");
            FilteredCardViewController *runner = [[FilteredCardViewController alloc] initWithRole:NRRoleCorp];
            [self.navigationController pushViewController:runner animated:YES];
            NSAssert([self.navigationController isKindOfClass:[NRNavigationController class]], @"oops");
            
            NRNavigationController* nc = (NRNavigationController*)self.navigationController;
            nc.deckListViewController = runner.deckListViewController;
            break;
        }
            
        case NRMenuLoadRunner:
        {
            TF_CHECKPOINT(@"load runner deck");
            SavedDecksViewController* runner = [[SavedDecksViewController alloc] initWithRole:NRRoleRunner];
            self.snc = [[SubstitutableNavigationController alloc] initWithRootViewController:runner];
            detailViewManager.detailViewController = self.snc;
            break;
        }
            
        case NRMenuLoadCorp:
        {
            TF_CHECKPOINT(@"load corp deck");
            SavedDecksViewController* corp = [[SavedDecksViewController alloc] initWithRole:NRRoleCorp];
            self.snc = [[SubstitutableNavigationController alloc] initWithRootViewController:corp];
            detailViewManager.detailViewController = self.snc;
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
            
        case NRMenuImportDecks:
        {
            TF_CHECKPOINT(@"import decks");
            ImportDecksViewController* import = [[ImportDecksViewController alloc] init];
            self.snc = [[SubstitutableNavigationController alloc] initWithRootViewController:import];
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
            
        case NRMenuCardEditor:
        {
            TF_CHECKPOINT(@"card editor");
            CardEditorViewController* edit = [[CardEditorViewController alloc] initWithNibName:@"CardEditorViewController" bundle:nil];
            
            self.snc = [[SubstitutableNavigationController alloc] initWithRootViewController:edit];
            detailViewManager.detailViewController = self.snc;
            break;
        }
    }
}

@end
