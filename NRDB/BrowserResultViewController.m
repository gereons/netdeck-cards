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
#import "BrowserImageCell.h"

@interface BrowserResultViewController ()

@property NSArray* sections;
@property NSArray* values;

@property UIBarButtonItem* toggleViewButton;
@property BOOL largeCells;
@property CGFloat scale;

@end

enum { CARD_VIEW, TABLE_VIEW, LIST_VIEW };

@implementation BrowserResultViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    CGFloat scale = [settings floatForKey:BROWSER_VIEW_SCALE];
    self.scale = scale == 0 ? 1.0 : scale;
    
    // left buttons
    NSArray* selections = @[
                            [UIImage imageNamed:@"deckview_card"],   // CARD_VIEW
                            [UIImage imageNamed:@"deckview_table"],  // TABLE_VIEW
                            [UIImage imageNamed:@"deckview_list"]    // LIST_VIEW
                            ];
    UISegmentedControl* viewSelector = [[UISegmentedControl alloc] initWithItems:selections];
    viewSelector.selectedSegmentIndex = [settings integerForKey:BROWSER_VIEW_STYLE];
    [viewSelector addTarget:self action:@selector(toggleView:) forControlEvents:UIControlEventValueChanged];
    self.toggleViewButton = [[UIBarButtonItem alloc] initWithCustomView:viewSelector];
    [self doToggleView:viewSelector.selectedSegmentIndex];
    
    UINavigationItem* topItem = self.navigationController.navigationBar.topItem;
    topItem.leftBarButtonItems = @[
                                   self.toggleViewButton,
                                   ];

    
    self.parentViewController.view.backgroundColor = [UIColor colorWithPatternImage:[ImageCache hexTile]];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.collectionView.backgroundColor = [UIColor clearColor];
    
    UIView* footer = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.tableFooterView = footer;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"SmallBrowserCell" bundle:nil] forCellReuseIdentifier:@"smallBrowserCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"LargeBrowserCell" bundle:nil] forCellReuseIdentifier:@"largeBrowserCell"];
    
    [self.collectionView registerNib:[UINib nibWithNibName:@"BrowserImageCell" bundle:nil] forCellWithReuseIdentifier:@"browserImageCell"];
    
    self.collectionView.contentInset = UIEdgeInsetsMake(64, 0, 44, 0);
    UIPinchGestureRecognizer* pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGesture:)];
    [self.collectionView addGestureRecognizer:pinch];
}

-(void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    [settings setObject:@(self.scale) forKey:BROWSER_VIEW_SCALE];
    [settings synchronize];
}

- (void) updateDisplay:(CardList *)cardList
{
    TableData* td = [cardList dataForTableView];
    self.sections = td.sections;
    self.values = td.values;
    
    [self reloadViews];
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
    self.collectionView.hidden = viewMode != CARD_VIEW;
    
    self.largeCells = viewMode == TABLE_VIEW;
    
    [self reloadViews];
}

-(void) reloadViews
{
    [self.tableView reloadData];
    [self.collectionView reloadData];
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

#pragma mark collectionview

#define CARD_WIDTH  225
#define CARD_HEIGHT 313

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake((int)(CARD_WIDTH * self.scale), (int)(CARD_HEIGHT * self.scale));
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(2, 2, 5, 2);
}


-(NSInteger) numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return self.sections.count;
}

-(NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSArray* arr = self.values[section];
    return arr.count;
}

-(UICollectionViewCell*) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* cellIdentifier = @"browserImageCell";
    
    BrowserImageCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    NSArray* arr = self.values[indexPath.section];
    Card* card = arr[indexPath.row];

    [cell loadImageFor:card];
    
    return cell;
}

-(void) pinchGesture:(UIPinchGestureRecognizer*)gesture
{
    static CGFloat scaleStart;
    
    if (gesture.state == UIGestureRecognizerStateBegan)
    {
        scaleStart = self.scale;
    }
    else if (gesture.state == UIGestureRecognizerStateChanged)
    {
        self.scale = scaleStart * gesture.scale;
    }
    self.scale = MAX(self.scale, 0.5);
    self.scale = MIN(self.scale, 1.0);
    
    [self.collectionView reloadData];
}

@end
