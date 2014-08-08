//
//  BrowserResultViewController.m
//  NRDB
//
//  Created by Gereon Steffens on 03.08.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "BrowserResultViewController.h"
#import "CardList.h"
#import "Card.h"
#import "TableData.h"
#import "ImageCache.h"
#import "Faction.h"
#import "CardImageViewPopover.h"
#import "SmallBrowserCell.h"

@interface BrowserResultViewController ()

@property NSArray* sections;
@property NSArray* values;

@end

@implementation BrowserResultViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.parentViewController.view.backgroundColor = [UIColor colorWithPatternImage:[ImageCache hexTile]];
    self.tableView.backgroundColor = [UIColor clearColor];
    
    UIView* footer = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.tableFooterView = footer;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"SmallBrowserCell" bundle:nil] forCellReuseIdentifier:@"smallBrowserCell"];
}

- (void) updateDisplay:(CardList *)cardList
{
    TableData* td = [cardList dataForTableView];
    self.sections = td.sections;
    self.values = td.values;
    
    [self.tableView reloadData];
}

#pragma mark tableview

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray* arr = [self.values objectAtIndex:section];
    return arr.count;
}

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.sections.count;
}

-(NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self.sections objectAtIndex:section];
}

-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* cellIdentifier = @"smallBrowserCell";
    SmallBrowserCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    NSArray* arr = [self.values objectAtIndex:indexPath.section];
    Card* card = [arr objectAtIndex:indexPath.row];
    
    cell.nameLabel.text = card.name;
    
    if (card.subtypes.count > 0)
    {
        cell.typeLabel.text = [NSString stringWithFormat:@"%@ · %@: %@",
                                 [Faction name:card.faction],
                                 card.typeStr,
                                 [card.subtypes componentsJoinedByString:@" "]];
    }
    else
    {
        cell.typeLabel.text = [NSString stringWithFormat:@"%@ · %@",
                               [Faction name:card.faction],
                               card.typeStr];
    }
    
    [cell.pips setValue:card.type == NRCardTypeAgenda ? card.agendaPoints : card.influence];
    [cell.pips setColor:card.factionColor];
    
    return cell;
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray* arr = self.values[indexPath.section];
    Card* card = arr[indexPath.row];
    
    CGRect rect = [self.tableView rectForRowAtIndexPath:indexPath];
    [CardImageViewPopover showForCard:card fromRect:rect inView:self.tableView];
}


@end
