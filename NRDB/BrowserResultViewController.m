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
#import "BrowserCell.h"
#import "SettingsKeys.h"

@interface BrowserResultViewController ()

@property NSArray* sections;
@property NSArray* values;

@property UIBarButtonItem* toggleViewButton;
@property BOOL largeCells;

@end

enum { CARD_VIEW, TABLE_VIEW, LIST_VIEW };

@implementation BrowserResultViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UINavigationItem* topItem = self.navigationController.navigationBar.topItem;
    
    // left buttons
    NSArray* selections = @[
                            [UIImage imageNamed:@"deckview_card"],   // CARD_VIEW
                            [UIImage imageNamed:@"deckview_table"],  // TABLE_VIEW
                            [UIImage imageNamed:@"deckview_list"]    // LIST_VIEW
                            ];
    UISegmentedControl* viewSelector = [[UISegmentedControl alloc] initWithItems:selections];
    [viewSelector setEnabled:NO forSegmentAtIndex:0];
    viewSelector.selectedSegmentIndex = [[NSUserDefaults standardUserDefaults] integerForKey:BROWSER_VIEW_STYLE];
    [viewSelector addTarget:self action:@selector(toggleView:) forControlEvents:UIControlEventValueChanged];
    self.toggleViewButton = [[UIBarButtonItem alloc] initWithCustomView:viewSelector];
    [self doToggleView:viewSelector.selectedSegmentIndex];
    
    topItem.leftBarButtonItems = @[
                                   self.toggleViewButton,
                                   ];

    
    self.parentViewController.view.backgroundColor = [UIColor colorWithPatternImage:[ImageCache hexTile]];
    self.tableView.backgroundColor = [UIColor clearColor];
    
    UIView* footer = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.tableFooterView = footer;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"SmallBrowserCell" bundle:nil] forCellReuseIdentifier:@"smallBrowserCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"LargeBrowserCell" bundle:nil] forCellReuseIdentifier:@"largeBrowserCell"];
}

- (void) updateDisplay:(CardList *)cardList
{
    TableData* td = [cardList dataForTableView];
    self.sections = td.sections;
    self.values = td.values;
    
    [self.tableView reloadData];
}

-(void) toggleView:(UISegmentedControl*)sender
{
    NSInteger viewMode = sender.selectedSegmentIndex;
    [[NSUserDefaults standardUserDefaults] setInteger:viewMode forKey:BROWSER_VIEW_STYLE];
    [self doToggleView:viewMode];
}

-(void) doToggleView:(NSInteger)viewMode
{
    self.tableView.hidden = viewMode == CARD_VIEW;
    // self.collectionView.hidden = viewMode != CARD_VIEW;
    
    self.largeCells = viewMode == TABLE_VIEW;
    
    [self reloadViews];
}

-(void) reloadViews
{
    [self.tableView reloadData];
    // [self.collectionView reloadData];
}

#pragma mark tableview

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.largeCells ? 83 : 40;
}

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
    NSArray* arr = [self.values objectAtIndex:section];
    return [NSString stringWithFormat:@"%@ (%lu)", [self.sections objectAtIndex:section], (unsigned long)arr.count];
}

-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString* cellIdentifier = self.largeCells ? @"largeBrowserCell" : @"smallBrowserCell";
    BrowserCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    NSArray* arr = [self.values objectAtIndex:indexPath.section];
    Card* card = [arr objectAtIndex:indexPath.row];
    
    cell.card = card;
    
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
