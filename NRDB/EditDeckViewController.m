//
//  EditDeckViewController.m
//  NRDB
//
//  Created by Gereon Steffens on 09.08.15.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

#import "EditDeckViewController.h"
#import "Deck.h"
#import "TableData.h"
#import "ImageCache.h"
#import "Faction.h"
#import "CardType.h"

@interface EditDeckViewController ()

@property NSArray* cards;
@property NSArray* sections;

@end

@implementation EditDeckViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    TableData* data = [self.deck dataForTableView:NRDeckSortType];
    self.cards = data.values;
    self.sections = data.sections;
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[ImageCache hexTile]];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.backgroundColor = [UIColor clearColor];
    
    self.title = self.deck.name;
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    // right buttons
    UIBarButtonItem* exportButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"702-share"] style:UIBarButtonItemStylePlain target:self action:@selector(exportDeck:)];
    UIBarButtonItem* addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addCard:)];
    
    self.navigationController.navigationBar.topItem.rightBarButtonItems = @[ addButton, exportButton];
}

-(void) exportDeck:(id)sender
{
    NSLog(@"stub - save/export deck");
}

-(void) addCard:(id)sender
{
    NSLog(@"stub - add card to deck");
}

#pragma mark - table view

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.sections.count;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray* arr = self.cards[section];
    return arr.count;
}

-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.sections[section];
}

-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* cellIdentifier = @"cardCell";
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    NSArray* arr = self.cards[indexPath.section];
    CardCounter* cc = arr[indexPath.row];
    
    Card* card = cc.card;
    
    if (card.unique)
    {
        cell.textLabel.text = [NSString stringWithFormat:@"%lu× %@ •", (unsigned long)cc.count, card.name];
    }
    else
    {
        cell.textLabel.text = [NSString stringWithFormat:@"%lu× %@", (unsigned long)cc.count, card.name];
    }
    
    cell.textLabel.textColor = [UIColor blackColor];
    if (card.isCore && !self.deck.isDraft)
    {
        if (card.owned < cc.count)
        {
            cell.textLabel.textColor = [UIColor redColor];
        }
    }
    
    NSString* factionName = [Faction name:card.faction];
    NSString* typeName = [CardType name:card.type];
    
    NSString* subtype = card.subtype;
    if (subtype)
    {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ · %@: %@", factionName, typeName, card.subtype];
    }
    else
    {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ · %@", factionName, typeName];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray* arr = self.cards[indexPath.section];
    CardCounter* cc = arr[indexPath.row];
    
    NSLog(@"stub - show card image for %@", cc.card.name);
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        NSArray* arr = self.cards[indexPath.section];
        CardCounter* cc = arr[indexPath.row];
        
        if (!ISNULL(cc))
        {
            [self.deck addCard:cc.card copies:0];
        }
        
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationLeft];
        
        // duplicate code!
        TableData* data = [self.deck dataForTableView:NRDeckSortType];
        self.cards = data.values;
        self.sections = data.sections;
        
        [self.tableView endUpdates];
    }
}

@end
