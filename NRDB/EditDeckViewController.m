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
    NSString* cellIdentifier = @"cardCell";
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    
    NSArray* arr = self.cards[indexPath.section];
    CardCounter* cc = arr[indexPath.row];
    
    cell.textLabel.text = ISNULL(cc) ? @"null" : cc.card.name;
    
    return cell;
}

@end
