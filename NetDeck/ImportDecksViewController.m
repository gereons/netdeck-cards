//
//  ImportDecksViewController.m
//  Net Deck
//
//  Created by Gereon Steffens on 12.01.14.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

@import SVProgressHUD;
@import SDCAlertView;

#import <Dropbox/Dropbox.h>
#import "ImportDecksViewController.h"
#import "EXTScope.h"
#import "ImageCache.h"
#import "DeckCell.h"
#import "OctgnImport.h"
#import "NRDB.h"

static NRDeckSearchScope searchScope = NRDeckSearchScopeAll;
static NSString* filterText;

@interface ImportDecksViewController ()

@property NSMutableArray* runnerDecks;
@property NSMutableArray* corpDecks;

@property NSArray* filteredDecks;

@property UIBarButtonItem* importButton;
@property UIBarButtonItem* spacer;
@property UIBarButtonItem* sortButton;
@property NSArray* barButtons;
@property UIAlertController* alert;

@property NSDateFormatter* dateFormatter;
@property NRDeckListSort deckListSort;

@end

@implementation ImportDecksViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        self.dateFormatter = [[NSDateFormatter alloc] init];
        if (IS_IPAD)
        {
            [self.dateFormatter setDateStyle:NSDateFormatterMediumStyle];
            [self.dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
        }
        else
        {
            [self.dateFormatter setDateStyle:NSDateFormatterMediumStyle];
            [self.dateFormatter setTimeStyle:NSDateFormatterNoStyle];
        }
    }
    return self;
}

-(void) dealloc
{
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    self.searchBar.delegate = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.deckListSort = [[NSUserDefaults standardUserDefaults] integerForKey:SettingsKeys.DECK_FILTER_SORT];
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[ImageCache hexTile]];
    
    self.searchBar.placeholder = l10n(@"Search for decks, identities or cards");
    if (filterText.length > 0)
    {
        self.searchBar.text = filterText;
    }
    self.searchBar.scopeButtonTitles = @[ l10n(@"All"), l10n(@"Name"), l10n(@"Identity"), l10n(@"Card") ];
    self.searchBar.selectedScopeButtonIndex = searchScope;
    self.searchBar.showsScopeBar = NO;
    self.searchBar.showsCancelButton = NO;
    // needed on iOS8
    [self.searchBar sizeToFit];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.rowHeight = 44;
    [self.tableView registerNib:[UINib nibWithNibName:@"DeckCell" bundle:nil] forCellReuseIdentifier:@"deckCell"];
    [self.tableView setContentOffset:CGPointMake(0, self.searchBar.frame.size.height) animated:NO];
    
    // do the initial listing in the background, as it may block the ui thread
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    if (self.source == NRImportSourceDropbox)
    {
        [SVProgressHUD showWithStatus:l10n(@"Loading decks from Dropbox") maskType:SVProgressHUDMaskTypeBlack];
        [self startDropboxImport];
    }
    else
    {
        [SVProgressHUD showWithStatus:l10n(@"Loading decks from NetrunnerDB.com") maskType:SVProgressHUDMaskTypeBlack];
        [self getNetrunnerdbDecks];
    }

    NSString* title = IS_IPHONE ? l10n(@"All") : l10n(@"Import All");
    self.importButton = [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStylePlain target:self action:@selector(importAll:)];
    
    if (IS_IPHONE)
    {
        self.sortButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"890-sort-ascending-toolbar"] style:UIBarButtonItemStylePlain target:self action:@selector(changeSort:)];
    }
    else
    {
        self.sortButton = [[UIBarButtonItem alloc] initWithTitle:l10n(@"Sort") style:UIBarButtonItemStylePlain target:self action:@selector(changeSort:)];
    }
    self.spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    self.barButtons = IS_IPHONE ? @[ self.importButton, self.sortButton ] : @[ self.importButton, self.spacer, self.sortButton ];
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.topItem.title = IS_IPHONE ? l10n(@"Import") : l10n(@"Import Deck");
    
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(willShowKeyboard:) name:UIKeyboardWillShowNotification object:nil];
    [nc addObserver:self selector:@selector(willHideKeyboard:) name:UIKeyboardWillHideNotification object:nil];
}

-(void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    @try
    {
        DBFilesystem* filesystem = [DBFilesystem sharedFilesystem];
        [filesystem removeObserver:self];
    }
    @catch (DBException* dbEx)
    {}
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark sorting

-(void)changeSort:(UIBarButtonItem*)sender
{
    self.alert = [UIAlertController alertControllerWithTitle:l10n(@"Sort by") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [self.alert addAction:[UIAlertAction actionWithTitle:l10n(@"Date") handler:^(UIAlertAction *action) {
        [self changeSortType:NRDeckListSortDate];
    }]];
    [self.alert addAction:[UIAlertAction actionWithTitle:l10n(@"Faction") handler:^(UIAlertAction *action) {
        [self changeSortType:NRDeckListSortFaction];
    }]];
    [self.alert addAction:[UIAlertAction actionWithTitle:l10n(@"A-Z") handler:^(UIAlertAction *action) {
        [self changeSortType:NRDeckListSortA_Z];
    }]];
    [self.alert addAction:[UIAlertAction cancelAction:^(UIAlertAction* action) {
        self.alert = nil;
    }]];
    
    if (IS_IPAD)
    {
        UIPopoverPresentationController* popover = self.alert.popoverPresentationController;
        popover.barButtonItem = sender;
        popover.sourceView = self.view;
        popover.permittedArrowDirections = UIPopoverArrowDirectionUp;
        [self.alert.view layoutIfNeeded];
    }
    
    [self presentViewController:self.alert animated:NO completion:nil];
}

-(void) changeSortType:(NRDeckListSort)sort
{
    [[NSUserDefaults standardUserDefaults] setInteger:sort forKey:SettingsKeys.DECK_FILTER_SORT];
    self.deckListSort = sort;
    
    [self filterDecks];
    [self.tableView reloadData];
}

-(void) dismissSortPopup {
    [self.alert dismissViewControllerAnimated:NO completion:nil];
    self.alert = nil;
}

#pragma mark import all

-(void) importAll:(id)sender
{
    if (self.alert) {
        [self dismissSortPopup];
        return;
    }
    
    NSString* msg;
    if (self.source == NRImportSourceDropbox)
    {
        msg = l10n(@"Import all decks from Dropbox?");
    }
    else
    {
        msg = l10n(@"Import all decks from NetrunnerDB.com? Existing linked decks will be overwritten.");
    }
    SDCAlertView* alert = [SDCAlertView alertWithTitle:l10n(@"Import All")
                                               message:msg
                                               buttons:@[ l10n(@"Cancel"), l10n(@"OK") ]];
    
    alert.didDismissHandler = ^(NSInteger buttonIndex) {
        if (buttonIndex == 1) // ok, import
        {
            [SVProgressHUD showSuccessWithStatus:l10n(@"Imported decks")];
            [self performSelector:@selector(doImportAll) withObject:nil afterDelay:0.001];
        }
    };
}

-(void) doImportAll
{
    for (NSArray* arr in self.filteredDecks)
    {
        for (Deck* deck in arr)
        {
            if (self.source == NRImportSourceNetrunnerDb)
            {
                deck.filename = [[NRDB sharedInstance] filenameForId:deck.netrunnerDbId];
            }
            [deck saveToDisk];
            [DeckManager resetModificationDate:deck];
        }
    }
}

#pragma mark netrunnerdb.com import

-(void) getNetrunnerdbDecks
{
    self.runnerDecks = [NSMutableArray array];
    self.corpDecks = [NSMutableArray array];
    
    [SVProgressHUD showWithStatus:l10n(@"Loading Decks...") maskType:SVProgressHUDMaskTypeBlack];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [[NRDB sharedInstance] decklist:^(NSArray* decks) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        [SVProgressHUD dismiss];

        NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy'-'MM'-'dd' 'HH':'mm':'ss"];
        
        for (NSDictionary* dict in decks)
        {
            Deck* deck = [[NRDB sharedInstance] parseDeckFromJson:dict];
            if (deck.role != NRRoleNone)
            {
                NSMutableArray* decks = deck.role == NRRoleRunner ? self.runnerDecks : self.corpDecks;
                [decks addObject:deck];
            }
        }
        
        [self filterDecks];
        [self.tableView reloadData];
        self.navigationController.navigationBar.topItem.rightBarButtonItems = self.barButtons;
    }];
}

#pragma mark dropbox import

-(void) startDropboxImport
{
    @weakify(self);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        @strongify(self);
        NSUInteger count = [self listDropboxFiles];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            @strongify(self);
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            [SVProgressHUD dismiss];
            if (count == 0)
            {
                [SDCAlertView alertWithTitle:l10n(@"No Decks found")
                                     message:l10n(@"Copy Decks in OCTGN Format (.o8d) into the Apps/Net Deck folder of your Dropbox to import them into this App.")
                                     buttons:@[ l10n(@"OK") ]];
            }
            [self filterDecks];
            [self.tableView reloadData];
            self.navigationController.navigationBar.topItem.rightBarButtonItems = self.barButtons;
        });
    });
    
    @try
    {
        DBFilesystem* filesystem = [DBFilesystem sharedFilesystem];
        DBPath* path = [DBPath root];
        
        [filesystem addObserver:self forPathAndChildren:path block:^() {
            [self listDropboxFiles];
            [self filterDecks];
            [self.tableView reloadData];
        }];
    }
    @catch (DBException* dbEx)
    {}
}

-(NSUInteger) listDropboxFiles
{
    self.runnerDecks = [NSMutableArray array];
    self.corpDecks = [NSMutableArray array];
    
    NSUInteger totalDecks = 0;
    
    @try
    {
        DBFilesystem* filesystem = [DBFilesystem sharedFilesystem];
        DBPath* path = [DBPath root];
        DBError* error;
        
        for (DBFileInfo* fileInfo in [filesystem listFolder:path error:&error])
        {
            NSString* name = fileInfo.path.name;
            NSRange textRange = [name rangeOfString:@".o8d" options:NSCaseInsensitiveSearch];
            
            if (textRange.location == name.length-4)
            {
                // NSLog(@"%@", fileInfo.path);
                Deck* deck = [self parseDeck:fileInfo.path.name];
                if (deck && deck.role != NRRoleNone)
                {
                    NSMutableArray* decks = deck.role == NRRoleRunner ? self.runnerDecks : self.corpDecks;

                    [decks addObject:deck];
                    ++totalDecks;
                }
            }
        }
    }
    @catch (DBException* dbEx)
    {}
    
    return totalDecks;
}

#pragma mark filter

-(NSMutableArray<Deck*>*) sortDecks:(NSArray<NSString*>*)decksToSort
{
    NSArray* decks;
    
    switch (self.deckListSort)
    {
        case NRDeckListSortA_Z:
            decks = [decksToSort sortedArrayUsingComparator:^NSComparisonResult(Deck* d1, Deck* d2) {
                return [[d1.name lowercaseString] compare:[d2.name lowercaseString]];
            }];
            break;
        case NRDeckListSortDate:
            decks = [decksToSort sortedArrayUsingComparator:^NSComparisonResult(Deck* d1, Deck* d2) {
                NSComparisonResult cmp = [d2.lastModified compare:d1.lastModified];
                if (cmp == NSOrderedSame)
                {
                    return [[d1.name lowercaseString] compare:[d2.name lowercaseString]];
                }
                return cmp;
            }];
            break;
        case NRDeckListSortFaction:
            decks = [decksToSort sortedArrayUsingComparator:^NSComparisonResult(Deck* d1, Deck* d2) {
                NSString* faction1 = [Faction name:d1.identity.faction];
                NSString* faction2 = [Faction name:d2.identity.faction];
                NSComparisonResult cmp = [faction1 compare:faction2];
                if (cmp == NSOrderedSame)
                {
                    cmp = [[d1.identity.name lowercaseString] compare:[d2.identity.name lowercaseString]];
                    if (cmp == NSOrderedSame)
                    {
                        return [[d1.name lowercaseString] compare:[d2.name lowercaseString]];
                    }
                    return cmp;
                }
                return cmp;
            }];
            break;
    }
    
    return decks.mutableCopy;
}

-(void) filterDecks
{
    NSMutableArray* allDecks = nil;
    if (self.deckListSort == NRDeckListSortDate)
    {
        allDecks = [NSMutableArray arrayWithArray:self.runnerDecks];
        [allDecks addObjectsFromArray:self.corpDecks];
        allDecks = [self sortDecks:allDecks];
    }
    else
    {
        self.runnerDecks = [self sortDecks:self.runnerDecks];
        self.corpDecks = [self sortDecks:self.corpDecks];
    }
    
    if (filterText.length > 0)
    {
        // NSLog(@"filter %@ %d", filterText, searchScope);
        
        NSPredicate* namePredicate = [NSPredicate predicateWithFormat:@"name CONTAINS[cd] %@", filterText];
        NSPredicate* identityPredicate = [NSPredicate predicateWithFormat:@"(identity.name CONTAINS[cd] %@) or (identity.name_en CONTAINS[cd] %@)",
                                          filterText, filterText];
        NSPredicate* cardPredicate = [NSPredicate predicateWithFormat:@"(ANY cards.card.name CONTAINS[cd] %@) OR (ANY cards.card.name_en CONTAINS[cd] %@)", filterText, filterText];
        
        NSPredicate* predicate;
        switch (searchScope)
        {
            case NRDeckSearchScopeAll:
                predicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[ namePredicate, identityPredicate, cardPredicate ]];
                break;
            case NRDeckSearchScopeName:
                predicate = namePredicate;
                break;
            case NRDeckSearchScopeIdentity:
                predicate = identityPredicate;
                break;
            case NRDeckSearchScopeCard:
                predicate = cardPredicate;
                break;
        }
        
        if (allDecks)
        {
            self.filteredDecks = @[ [allDecks filteredArrayUsingPredicate:predicate] ];
        }
        else
        {
            self.filteredDecks = @[
               [self.runnerDecks filteredArrayUsingPredicate:predicate],
               [self.corpDecks filteredArrayUsingPredicate:predicate]
            ];
        }
    }
    else
    {
        if (allDecks)
        {
            self.filteredDecks = @[ allDecks ];
        }
        else
        {
            self.filteredDecks = @[ self.runnerDecks, self.corpDecks ];
        }
    }
}

#pragma mark search bar

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    filterText = searchText;
    [self filterDecks];
    [self.tableView reloadData];
}

-(void) searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope
{
    searchScope = selectedScope;
    [self filterDecks];
    [self.tableView reloadData];
}

-(void) searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    searchBar.showsCancelButton = NO;
    searchBar.showsScopeBar = NO;
    [searchBar sizeToFit];
    self.tableView.tableHeaderView = self.searchBar;
}

-(void) searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    searchBar.showsCancelButton = YES;
    searchBar.showsScopeBar = YES;
    [searchBar sizeToFit];
    self.tableView.tableHeaderView = self.searchBar;
}

-(void) searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

#pragma mark tableView

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.filteredDecks.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray* arr = self.filteredDecks[section];
    return arr.count;
}

-(NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.deckListSort == NRDeckListSortDate ? 0 : section == NRRoleRunner ? l10n(@"Runner") : l10n(@"Corp");
}

-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* cellIdentifier = @"deckCell";
    
    DeckCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.infoButton.hidden = YES;
    
    Deck* deck = [self.filteredDecks objectAtIndexPath:indexPath];
    
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
    
    NSString* summary;
    if (deck.role == NRRoleRunner)
    {
        summary = [NSString stringWithFormat:l10n(@"%d Cards · %d Influence"), deck.size, deck.influence];
    }
    else
    {
        summary = [NSString stringWithFormat:l10n(@"%d Cards · %d Influence · %d AP"), deck.size, deck.influence, deck.agendaPoints];
    }
    cell.summaryLabel.text = summary;
    BOOL valid = [deck checkValidity].count == 0;
    cell.summaryLabel.textColor = valid ? [UIColor blackColor] : [UIColor redColor];
    
    cell.dateLabel.text = [self.dateFormatter stringFromDate:deck.lastModified];
    cell.nrdbIcon.hidden = self.source == NRImportSourceDropbox;
    
    return cell;
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Deck* deck = [self.filteredDecks objectAtIndexPath:indexPath];
    
    NSString* filename = [[NRDB sharedInstance] filenameForId:deck.netrunnerDbId];    
    if (filename)
    {
        SDCAlertView* alert = [SDCAlertView alertWithTitle:nil
                                                   message:l10n(@"A local copy of this deck already exists.")
                                                   buttons:@[ l10n(@"Cancel"), l10n(@"Overwrite"), l10n(@"Import as new")]];
        alert.didDismissHandler = ^(NSInteger buttonIndex) {
            switch (buttonIndex)
            {
                case 0: // cancel
                    return;
                case 1: // overwrite
                    deck.filename = filename;
                    break;
                case 2: // new
                    break;
            }
            
            if (self.source == NRImportSourceNetrunnerDb)
            {
                [[NRDB sharedInstance] loadDeck:deck completion:^(BOOL ok, Deck *deck) {
                    [SVProgressHUD showSuccessWithStatus:l10n(@"Deck imported")];
                    [deck saveToDisk];
                    [DeckManager resetModificationDate:deck];
                }];
            }
        };
    }
    else
    {
        [SVProgressHUD showSuccessWithStatus:l10n(@"Deck imported")];
        [deck saveToDisk];
        [DeckManager resetModificationDate:deck];
    }
}

-(Deck*) parseDeck:(NSString*)fileName
{
    @try
    {
        DBFile *file = nil;
        DBPath *path = [[DBPath root] childPath:fileName];
        if (path)
        {
            file = [[DBFilesystem sharedFilesystem] openFile:path error:nil];
        }
        
        if (file)
        {
            NSData* data = [file readData:nil];
            NSDate* lastModified = file.info.modifiedTime;
            [file close];
            
            OctgnImport* importer = [[OctgnImport alloc] init];
            Deck* deck = [importer parseOctgnDeckFromData:data];
            
            if (deck)
            {
                NSRange textRange = [fileName rangeOfString:@".o8d" options:NSCaseInsensitiveSearch];
                
                if (textRange.location == fileName.length-4)
                {
                    deck.name = [fileName substringToIndex:textRange.location];
                }
                else
                {
                    deck.name = fileName;
                }
                            
                deck.lastModified = lastModified;
                return deck;
            }
        }
    }
    @catch (DBException* dbEx)
    {}
    
    return nil;
}

#pragma mark keyboard show/hide

-(void) willShowKeyboard:(NSNotification*)sender
{
    CGRect kbRect = [[sender.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    float kbHeight = kbRect.size.height;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(64.0, 0.0, kbHeight, 0.0);
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;
}

-(void) willHideKeyboard:(NSNotification*)sender
{
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(64, 0, 0, 0);
    
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;
}

@end
