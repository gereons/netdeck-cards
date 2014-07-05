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
#import <AFNetworking.h>

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

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
        
    self.parentViewController.view.backgroundColor = [UIColor colorWithPatternImage:[ImageCache hexTile]];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.backgroundColor = [UIColor clearColor];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"DeckCell" bundle:nil] forCellReuseIdentifier:@"deckCell"];
    
    [self.tableView setContentOffset:CGPointMake(0,self.searchBar.frame.size.height) animated:NO];
    
    // do the initial listing in the background, as it may block the ui thread
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    if (self.source == NRImportSourceDropbox)
    {
        [SVProgressHUD showWithStatus:l10n(@"Loading decks from Dropbox")];
        [self startDropboxImport];
    }
    else
    {
        [SVProgressHUD showWithStatus:l10n(@"Loading decks from NetrunnerDB.com")];
        [self getNetrunnerdbDecks];
    }

    self.searchBar.placeholder = l10n(@"Search for decks, identities or cards");
    if (filterText.length > 0)
    {
        self.searchBar.text = filterText;
    }
    self.searchBar.scopeButtonTitles = @[ l10n(@"All"), l10n(@"Name"), l10n(@"Identity"), l10n(@"Card") ];
    self.searchBar.selectedScopeButtonIndex = searchScope;
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.navigationController.navigationBar.topItem.title = l10n(@"Import Deck");
}

-(void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    DBFilesystem* filesystem = [DBFilesystem sharedFilesystem];
    [filesystem removeObserver:self];
}


#pragma mark netrunnerdb.com import

-(void) getNetrunnerdbDecks
{
    self.allDecks = @[ [NSMutableArray array], [NSMutableArray array] ];
    
    NRDB* nrdb = [NRDB sharedInstance];
    
    [nrdb decklist:^(NSArray* decks) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        [SVProgressHUD dismiss];

        NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy'-'MM'-'dd' 'HH':'mm':'ss"];
        
        for (NSDictionary* d in decks)
        {
            Deck* deck = [Deck new];
            deck.name = d[@"name"];
            deck.notes = d[@"description"];
            deck.netrunnerDbId = [NSString stringWithFormat:@"%d", [d[@"id"] integerValue]];
            
            // parse creation date, '2014-06-19 13:52:24'
            deck.lastModified = [formatter dateFromString:d[@"creation"]];
            
            for (NSDictionary* c in d[@"cards"])
            {
                NSString* code = c[@"card_code"];
                NSInteger qty = [c[@"qty"] integerValue];
                
                Card* card = [Card cardByCode:code];
                if (card.type == NRCardTypeIdentity)
                {
                    deck.identity = card;
                }
                else
                {
                    [deck addCard:card copies:qty];
                }
            }
            
            if (deck.role != NRRoleNone)
            {
                NSMutableArray* decks = self.allDecks[deck.role];
                [decks addObject:deck];
            }
        }
        
        [self filterDecks];
        [self.tableView reloadData];
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
        });
    });
    
    DBFilesystem* filesystem = [DBFilesystem sharedFilesystem];
    DBPath* path = [DBPath root];
    
    [filesystem addObserver:self forPathAndChildren:path block:^() {
        [self listDropboxFiles];
        [self filterDecks];
        [self.tableView reloadData];
    }];
}

-(NSUInteger) listDropboxFiles
{
    self.allDecks = @[ [NSMutableArray array], [NSMutableArray array] ];
    
    DBFilesystem* filesystem = [DBFilesystem sharedFilesystem];
    DBPath* path = [DBPath root];
    DBError* error;
    
    NSUInteger totalDecks = 0;
    for (DBFileInfo* fileInfo in [filesystem listFolder:path error:&error])
    {
        NSString* name = fileInfo.path.name;
        NSRange textRange = [name rangeOfString:@".o8d" options:NSCaseInsensitiveSearch];
        
        if (textRange.location == name.length-4)
        {
            // NSLog(@"%@", fileInfo.path);
            Deck* deck = [self parseDeck:fileInfo.path.name];
            if (deck)
            {
                NSMutableArray* decks = self.allDecks[deck.role];

                [decks addObject:deck];
                ++totalDecks;
            }
        }
    }
    
    return totalDecks;
}

#pragma mark filter

-(void) filterDecks
{
    if (filterText.length > 0)
    {
        // NSLog(@"filter %@ %d", filterText, searchScope);
        
        NSPredicate* namePredicate = [NSPredicate predicateWithFormat:@"name CONTAINS[cd] %@", filterText];
        NSPredicate* identityPredicate = [NSPredicate predicateWithFormat:@"identity.name CONTAINS[cd] %@", filterText];
        NSPredicate* cardPredicate = [NSPredicate predicateWithFormat:@"ANY cards.card.name CONTAINS[cd] %@", filterText];
        
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
    
    return cell;
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    TF_CHECKPOINT(@"import deck");
    
    
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
            
            [SVProgressHUD showSuccessWithStatus:l10n(@"Deck imported")];
            [DeckManager saveDeck:deck];
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
    DBPath *path = [[DBPath root] childPath:fileName];
    DBFile* file = [[DBFilesystem sharedFilesystem] openFile:path error:nil];
    
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
    return nil;
}

@end
