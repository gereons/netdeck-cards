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
#import "Deck.h"
#import "DeckManager.h"

@interface ImportDecksViewController ()

@property NSMutableArray* decks;
@property Deck* deck;
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
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.navigationController.navigationBar.topItem.title = @"Import Deck";
    
    self.decks = [NSMutableArray array];
    DBFilesystem* filesystem = [DBFilesystem sharedFilesystem];
    DBPath* path = [DBPath root];
    DBError* error;
    for (DBFileInfo* fileInfo in [filesystem listFolder:path error:&error])
    {
        NSString* name = fileInfo.path.name;
        NSRange textRange = [name rangeOfString:@".o8d"];
        
        if (textRange.location == name.length-4)
        {
            // NSLog(@"%@", fileInfo.path);
            [self.decks addObject:fileInfo.path.name];
        }
    }
}

#pragma mark tableView

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.decks.count;
}

-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* cellIdentifier = @"deckCell";
    
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    cell.textLabel.text = self.decks[indexPath.row];
    
    return cell;
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    TF_CHECKPOINT(@"import deck");
    NSString* fileName = self.decks[indexPath.row];
    
    DBPath *path = [[DBPath root] childPath:fileName];
    DBFile* file = [[DBFilesystem sharedFilesystem] openFile:path error:nil];
    
    if (file)
    {
        NSData* data = [file readData:nil];
        [file close];
        
        NSXMLParser* parser = [[NSXMLParser alloc] initWithData:data];
        parser.delegate = self;
        self.deck = [Deck new];
        
        if ([parser parse])
        {
            self.deck.name = fileName;
            [DeckManager saveDeck:self.deck];
            
            [SVProgressHUD showSuccessWithStatus:@"Deck imported"];
        }
    }
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
            self.deck.identity = card;
            self.deck.role = card.role;
        }
        else
        {
            [self.deck addCard:card copies:copies];
        }
    }
}

@end
