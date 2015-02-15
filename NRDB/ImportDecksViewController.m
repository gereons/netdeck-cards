//
//  ImportDecksViewController.m
//  NRDB
//
//  Created by Gereon Steffens on 12.01.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "ImportDecksViewController.h"

#import <Dropbox/Dropbox.h>
#import <SVProgressHUD.h>
#import <EXTScope.h>
#import <SDCAlertView.h>

#import "Deck.h"
#import "DeckManager.h"
#import "ImageCache.h"
#import "DeckCell.h"
#import "OctgnImport.h"
#import "SettingsKeys.h"
#import "NRDB.h"

static NRDeckSearchScope searchScope = NRDeckSearchAll;
static NSString* filterText;

@interface ImportDecksViewController ()

@property NSArray* allDecks;
@property NSArray* filteredDecks;
@property UIBarButtonItem* importButton;
@property NSDateFormatter* dateFormatter;

@end

@implementation ImportDecksViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [self.dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    }
    return self;
}

-(void) dealloc
{
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    self.searchBar.delegate = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
        
    self.parentViewController.view.backgroundColor = [UIColor colorWithPatternImage:[ImageCache hexTile]];
    
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

    self.importButton = [[UIBarButtonItem alloc] initWithTitle:l10n(@"Import All") style:UIBarButtonItemStylePlain target:self action:@selector(importAll:)];
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.navigationController.navigationBar.topItem.title = l10n(@"Import Deck");
    
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

#pragma mark import all

-(void) importAll:(id)sender
{
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
            for (NSArray* arr in self.filteredDecks)
            {
                for (Deck* deck in arr)
                {
                    if (self.source == NRImportSourceNetrunnerDb)
                    {
                        deck.filename = [[NRDB sharedInstance] filenameForId:deck.netrunnerDbId];
                    }
                    [DeckManager saveDeck:deck];
                }
            }
        }
    };
}

#pragma mark netrunnerdb.com import

-(void) getNetrunnerdbDecks
{
    self.allDecks = @[ [NSMutableArray array], [NSMutableArray array] ];
    
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
                NSMutableArray* decks = self.allDecks[deck.role];
                [decks addObject:deck];
            }
        }
        
        [self filterDecks];
        [self.tableView reloadData];
        self.navigationController.navigationBar.topItem.rightBarButtonItem = self.importButton;
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
            self.navigationController.navigationBar.topItem.rightBarButtonItem = self.importButton;
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
    self.allDecks = @[ [NSMutableArray array], [NSMutableArray array] ];
    
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
                    NSMutableArray* decks = self.allDecks[deck.role];

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

-(void) filterDecks
{
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
            case NRDeckSearchAll:
                predicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[ namePredicate, identityPredicate, cardPredicate ]];
                break;
            case NRDeckSearchName:
                predicate = namePredicate;
                break;
            case NRDeckSearchIdentity:
                predicate = identityPredicate;
                break;
            case NRDeckSearchCard:
                predicate = cardPredicate;
                break;
        }
        
        self.filteredDecks = @[
                               [self.allDecks[NRRoleRunner] filteredArrayUsingPredicate:predicate],
                               [self.allDecks[NRRoleCorp] filteredArrayUsingPredicate:predicate]
                               ];
    }
    else
    {
        self.filteredDecks = self.allDecks;
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
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray* arr = self.filteredDecks[section];
    return arr.count;
}

-(NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return section == NRRoleRunner ? l10n(@"Runner") : l10n(@"Corp");
}

-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* cellIdentifier = @"deckCell";
    
    DeckCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.infoButton.hidden = YES;
    
    NSArray* decks = self.filteredDecks[indexPath.section];
    Deck* deck = decks[indexPath.row];
    
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
    NSArray* decks = self.filteredDecks[indexPath.section];
    Deck* deck = decks[indexPath.row];
    
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
                    NSLog(@"ok=%d", ok);
                    [SVProgressHUD showSuccessWithStatus:l10n(@"Deck imported")];
                    [DeckManager saveDeck:deck];
                }];
            }
        };
    }
    else
    {
        [SVProgressHUD showSuccessWithStatus:l10n(@"Deck imported")];
        [DeckManager saveDeck:deck];
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
