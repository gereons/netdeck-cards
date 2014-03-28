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

@interface ImportDecksViewController ()

@property NSArray* deckNames;
@property NSArray* decks;

@property Deck* tmpDeck;
@property BOOL setIdentity;

@end

@implementation ImportDecksViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
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
    // do the initial listing in the background, as it may block the ui thread
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    @weakify(self);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        @strongify(self);
        NSUInteger count = [self listFiles];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            @strongify(self);
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            if (count == 0)
            {
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:l10n(@"No Decks found")
                                                                message:l10n(@"Copy Decks in OCTGN Format (.o8d) into the Apps/Net Deck folder of your Dropbox to import them into the App.")
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
    
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
    }
    
    NSArray* names = self.deckNames[indexPath.section];
    NSArray* decks = self.decks[indexPath.section];

    cell.textLabel.text = names[indexPath.row];
    Deck* deck = decks[indexPath.row];
    cell.detailTextLabel.text = [NSString stringWithFormat:l10n(@"%@ (%d Cards)"), deck.identity.name, deck.size];
    
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
        [file close];
        
        NSXMLParser* parser = [[NSXMLParser alloc] initWithData:data];
        parser.delegate = self;
        self.tmpDeck = [Deck new];
        
        if ([parser parse])
        {
            NSRange textRange = [fileName rangeOfString:@".o8d" options:NSCaseInsensitiveSearch];
            
            if (textRange.location == fileName.length-4)
            {
                self.tmpDeck.name = [fileName substringToIndex:textRange.location];
            }
            else
            {
                self.tmpDeck.name = fileName;
            }
        }
        else
        {
            self.tmpDeck = nil;
        }
    }
    return self.tmpDeck;
}

#pragma mark nsxml delegate

-(void) parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if ([elementName isEqualToString:@"section"])
    {
        NSString* name = attributeDict[@"name"];
        self.setIdentity = [[name lowercaseString] isEqualToString:@"identity"];
        // NSLog(@"start section: %@", name);
    }
    
    if ([elementName isEqualToString:@"card"])
    {
        NSString* qty = attributeDict[@"qty"];
        NSString* code = attributeDict[@"id"];
        
        Card* card = [Card cardByCode:[code substringFromIndex:31]];
        int copies = [qty intValue];

        // NSLog(@"card: %d %@", copies, card.name);
        
        if (self.setIdentity)
        {
            self.tmpDeck.identity = card;
            self.tmpDeck.role = card.role;
        }
        else
        {
            [self.tmpDeck addCard:card copies:copies];
        }
    }
}

@end
