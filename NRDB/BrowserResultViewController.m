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

@interface BrowserResultViewController ()

@property CardList* cardList;
@property NSArray* sections;
@property NSArray* values;

@end

@implementation BrowserResultViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.cardList = [[CardList alloc] initForRole:NRRoleRunner];
    TableData* td = [self.cardList dataForTableView];
    self.sections = td.sections;
    self.values = td.values;
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
    static NSString* cellIdentifier = @"browserCell";
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    NSArray* arr = [self.values objectAtIndex:indexPath.section];
    Card* card = [arr objectAtIndex:indexPath.row];
    
    cell.textLabel.text = card.name;
    
    return cell;
}

@end
