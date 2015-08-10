//
//  ListCardsViewController.m
//  NRDB
//
//  Created by Gereon Steffens on 10.08.15.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

#import "ListCardsViewController.h"
#import "ImageCache.h"
#import "EditDeckCell.h"
#import "Deck.h"
#import "TableData.h"
#import "CardList.h"
#import "Faction.h"
#import "CardType.h"

@interface ListCardsViewController ()

@property NSArray* cards;
@property NSArray* sections;

@property CardList* cardList;

@end

@implementation ListCardsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[ImageCache hexTile]];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.backgroundColor = [UIColor clearColor];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"EditDeckCell" bundle:nil] forCellReuseIdentifier:@"cardCell"];
    
    self.cardList = [[CardList alloc] initForRole:self.deck.role];
    
    if (self.deck.role == NRRoleCorp && self.deck.identity != nil)
    {
        [self.cardList preFilterForCorp:self.deck.identity];
    }
    
    TableData* data = [self.cardList dataForTableView];
    
    self.cards = data.values;
    self.sections = data.sections;
}

-(void) countChanged:(UIStepper*)stepper
{
    NSInteger section = stepper.tag / 1000;
    NSInteger row = stepper.tag - (section*1000);
    
    NSArray* arr = self.cards[section];
    Card* card = arr[row];
    
    NSInteger count = 0;
    CardCounter* cc = [self.deck findCard:card];
    if (cc)
    {
        count = cc.count;
    }
    
    NSInteger copies = stepper.value;
    NSInteger diff = ABS(count - copies);
    if (copies < count)
    {
        [self.deck addCard:card copies:-diff];
    }
    else
    {
        [self.deck addCard:card copies:diff];
    }
    
    [self.tableView reloadData];
}

#pragma mark - tableview

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray* arr = self.cards[section];
    return arr.count;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.sections.count;
}

-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.sections[section];
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    EditDeckCell* cell = [tableView dequeueReusableCellWithIdentifier:@"cardCell" forIndexPath:indexPath];
    
    cell.stepper.tag = indexPath.section * 1000 + indexPath.row;
    [cell.stepper addTarget:self action:@selector(countChanged:) forControlEvents:UIControlEventValueChanged];
    
    NSArray* arr = self.cards[indexPath.section];
    Card* card = arr[indexPath.row];
    CardCounter* cc = [self.deck findCard:card];
    
    cell.stepper.minimumValue = 0;
    cell.stepper.maximumValue = card.maxPerDeck;
    cell.stepper.value = cc.count;
    
    if (cc)
    {
        if (card.unique)
        {
            cell.nameLabel.text = [NSString stringWithFormat:@"%lu× %@ •", (unsigned long)cc.count, card.name];
        }
        else
        {
            cell.nameLabel.text = [NSString stringWithFormat:@"%lu× %@", (unsigned long)cc.count, card.name];
        }
    }
    else
    {
        if (card.unique)
        {
            cell.nameLabel.text = [NSString stringWithFormat:@"%@ •", card.name];
        }
        else
        {
            cell.nameLabel.text = [NSString stringWithFormat:@"%@", card.name];
        }
    }
    
    
    NSString* factionName = [Faction name:card.faction];
    NSString* typeName = [CardType name:card.type];
    
    NSString* subtype = card.subtype;
    if (subtype)
    {
        cell.typeLabel.text = [NSString stringWithFormat:@"%@ · %@: %@", factionName, typeName, card.subtype];
    }
    else
    {
        cell.typeLabel.text = [NSString stringWithFormat:@"%@ · %@", factionName, typeName];
    }
    
    return cell;
}

@end
