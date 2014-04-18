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
#import "Deck.h"
#import "DeckManager.h"
#import "ImageCache.h"
#import "DeckCell.h"
#import "OctgnImport.h"

@interface ImportDecksViewController ()

@property NSArray* deckNames;
@property NSArray* decks;
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
    
    // do the initial listing in the background, as it may block the ui thread
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [SVProgressHUD showWithStatus:l10n(@"Loading decks from Dropbox")];
    @weakify(self);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        @strongify(self);
        NSUInteger count = [self listFiles];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            @strongify(self);
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            [SVProgressHUD dismiss];
            if (count == 0)
            {
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:l10n(@"No Decks found")
                                                                message:l10n(@"Copy Decks in OCTGN Format (.o8d) into the Apps/Net Deck folder of your Dropbox to import them into this App.")
                                                               delegate:nil
                                                      cancelButtonTitle:l10n(@"OK")
                                                      otherButtonTitles:nil];
                [alert show];
            }

            [self.tableView reloadData];
        });
    });
    
    DBFilesystem* filesystem = [DBFilesystem sharedFilesystem];
    DBPath* path = [DBPath root];
    
    [filesystem addObserver:self forPathAndChildren:path block:^() {
        [self listFiles];
        [self.tableView reloadData];
    }];
}

-(NSUInteger) listFiles
{
    self.deckNames = @[ [NSMutableArray array], [NSMutableArray array] ];
    self.decks = @[ [NSMutableArray array], [NSMutableArray array] ];
    
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
                NSMutableArray* names = self.deckNames[deck.role];
                NSMutableArray* decks = self.decks[deck.role];
                
                NSString* filename = fileInfo.path.name;
                [names addObject:[filename substringToIndex:textRange.location]];
                [decks addObject:deck];
                ++totalDecks;
            }
        }
    }
    
    return totalDecks;
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

#pragma mark tableView

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray* arr = self.deckNames[section];
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
    
    NSArray* names = self.deckNames[indexPath.section];
    NSArray* decks = self.decks[indexPath.section];

    cell.nameLabel.text = names[indexPath.row];
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
    
    [SVProgressHUD showSuccessWithStatus:l10n(@"Deck imported")];
    
    NSArray* decks = self.decks[indexPath.section];
    Deck* deck = decks[indexPath.row];
    [DeckManager saveDeck:deck];
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
