//
//  BrowserResultViewController.m
//  NRDB
//
//  Created by Gereon Steffens on 03.08.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <CSStickyHeaderFlowLayout.h>
#import <EXTScope.h>

#import "UIAlertAction+NRDB.h"
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
#import "BrowserSectionHeaderView.h"
#import "Notifications.h"

@interface BrowserResultViewController ()

@property NRBrowserSort sortType;
@property CardList* cardList;
@property NSArray* sections;
@property NSArray* values;

@property UIBarButtonItem* toggleViewButton;
@property UIBarButtonItem* sortButton;

@property UIAlertController* popup;

@property BOOL largeCells;
@property CGFloat scale;

@end

static NSDictionary* sortStr;

@implementation BrowserResultViewController

static BrowserResultViewController* instance;

+ (void) initialize
{
    sortStr = @{
                @(NRBrowserSortType): l10n(@"Type"),
                @(NRBrowserSortFaction): l10n(@"Faction"),
                @(NRBrowserSortTypeFaction): l10n(@"Type/Faction"),
                @(NRBrowserSortSet): l10n(@"Set"),
                @(NRBrowserSortSetFaction): l10n(@"Set/Faction"),
                @(NRBrowserSortSetType): l10n(@"Set/Type"),
    };
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    self.tableView = nil;
    
    self.collectionView.delegate = nil;
    self.collectionView.dataSource = nil;
    self.collectionView = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    instance = self;
    
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    CGFloat scale = [settings floatForKey:BROWSER_VIEW_SCALE];
    self.scale = scale == 0 ? 1.0 : scale;
    
    self.sortType = [settings integerForKey:BROWSER_SORT_TYPE];
    
    // left buttons
    NSArray* selections = @[
                            [UIImage imageNamed:@"deckview_card"],   // NRCardViewImage
                            [UIImage imageNamed:@"deckview_table"],  // NRCardViewLargeTable
                            [UIImage imageNamed:@"deckview_list"]    // NRCardViewSmallTable
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

    // right buttons
    self.sortButton = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:@"%@ ▾", sortStr[@(self.sortType)]]
                                                       style:UIBarButtonItemStylePlain
                                                      target:self
                                                      action:@selector(sortPopup:)];
    self.sortButton.possibleTitles = [NSSet setWithArray:@[
                                                           [NSString stringWithFormat:@"%@ ▾", l10n(@"Type")],
                                                           [NSString stringWithFormat:@"%@ ▾", l10n(@"Faction")],
                                                           [NSString stringWithFormat:@"%@ ▾", l10n(@"Type/Faction")],
                                                           [NSString stringWithFormat:@"%@ ▾", l10n(@"Set")],
                                                           [NSString stringWithFormat:@"%@ ▾", l10n(@"Set/Faction")],
                                                           [NSString stringWithFormat:@"%@ ▾", l10n(@"Set/Type")],
                                                           ] ];
    topItem.rightBarButtonItem = self.sortButton;
    
    self.parentViewController.view.backgroundColor = [UIColor colorWithPatternImage:[ImageCache hexTile]];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.collectionView.backgroundColor = [UIColor clearColor];
    
    UIView* footer = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.tableFooterView = footer;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"SmallBrowserCell" bundle:nil] forCellReuseIdentifier:@"smallBrowserCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"LargeBrowserCell" bundle:nil] forCellReuseIdentifier:@"largeBrowserCell"];
    
    [self.collectionView registerNib:[UINib nibWithNibName:@"BrowserImageCell" bundle:nil] forCellWithReuseIdentifier:@"browserImageCell"];
    [self.collectionView registerNib:[UINib nibWithNibName:@"BrowserSectionHeaderView" bundle:nil] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"sectionHeader"];
    
    self.collectionView.contentInset = UIEdgeInsetsMake(64, 0, 0, 0);
    UIPinchGestureRecognizer* pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGesture:)];
    [self.collectionView addGestureRecognizer:pinch];
    self.collectionView.alwaysBounceVertical = YES;
    
    CSStickyHeaderFlowLayout *layout = (id)self.collectionView.collectionViewLayout;
    layout.headerReferenceSize = CGSizeMake(703, 22);
    layout.sectionInset = UIEdgeInsetsMake(2, 2, 2, 2);
    layout.minimumInteritemSpacing = 3;
    layout.minimumLineSpacing = 3;
}

-(void) viewDidAppear:(BOOL)animated
{
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(willShowKeyboard:) name:UIKeyboardWillShowNotification object:nil];
    [nc addObserver:self selector:@selector(willHideKeyboard:) name:UIKeyboardWillHideNotification object:nil];
}

-(void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    [settings setObject:@(self.scale) forKey:BROWSER_VIEW_SCALE];
    [settings setObject:@(self.sortType) forKey:BROWSER_SORT_TYPE];
    
    instance = nil;
}

- (void) updateDisplay:(CardList *)cardList
{
    self.cardList = cardList;
    [cardList sortBy:self.sortType];
    TableData* td = [cardList dataForTableView];
    self.sections = td.sections;
    self.values = td.values;
    
    [self reloadViews];
}

-(void) sortPopup:(UIBarButtonItem*)sender
{
    if (self.popup)
    {
        [self.popup dismissViewControllerAnimated:NO completion:nil];
        self.popup = nil;
        return;
    }
    
    self.popup = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [self.popup addAction:[UIAlertAction actionWithTitle:l10n(@"Type") handler:^(UIAlertAction *action) {
        [self changeSortType:NRBrowserSortType];
    }]];
    [self.popup addAction:[UIAlertAction actionWithTitle:l10n(@"Faction") handler:^(UIAlertAction *action) {
        [self changeSortType:NRBrowserSortFaction];
    }]];
    [self.popup addAction:[UIAlertAction actionWithTitle:l10n(@"Type/Faction") handler:^(UIAlertAction *action) {
        [self changeSortType:NRBrowserSortTypeFaction];
    }]];
    [self.popup addAction:[UIAlertAction actionWithTitle:l10n(@"Set") handler:^(UIAlertAction *action) {
        [self changeSortType:NRBrowserSortSet];
    }]];
    [self.popup addAction:[UIAlertAction actionWithTitle:l10n(@"Set/Faction") handler:^(UIAlertAction *action) {
        [self changeSortType:NRBrowserSortSetFaction];
    }]];
    [self.popup addAction:[UIAlertAction actionWithTitle:l10n(@"Set/Type") handler:^(UIAlertAction *action) {
        [self changeSortType:NRBrowserSortSetType];
    }]];
    
    [self.popup addAction:[UIAlertAction cancelAction:^(UIAlertAction *action) {
        self.popup = nil;
    }]];
    
    UIPopoverPresentationController* popover = self.popup.popoverPresentationController;
    popover.barButtonItem = sender;
    popover.sourceView = self.view;
    popover.permittedArrowDirections = UIPopoverArrowDirectionAny;
    
    [self presentViewController:self.popup animated:NO completion:nil];
}

-(void) changeSortType:(NRBrowserSort)sortType
{
    self->_sortType = sortType;
    self.sortButton.title = [NSString stringWithFormat:@"%@ ▾", sortStr[@(self.sortType)]];
    [self updateDisplay:self.cardList];
    self.popup = nil;
}

-(void) toggleView:(UISegmentedControl*)sender
{
    NSInteger viewMode = sender.selectedSegmentIndex;
    [[NSUserDefaults standardUserDefaults] setInteger:viewMode forKey:BROWSER_VIEW_STYLE];
    [self doToggleView:viewMode];
}

-(void) doToggleView:(NSInteger)viewMode
{
    self.tableView.hidden = viewMode == NRCardViewImage;
    self.collectionView.hidden = viewMode != NRCardViewImage;
    
    self.largeCells = viewMode == NRCardViewLargeTable;
    
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
    if (tableView.hidden)
    {
        return 0;
    }
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
    if (collectionView.hidden)
    {
        return 0;
    }
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

    cell.card = card;
    
    return cell;
}

-(void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell* cell = [collectionView cellForItemAtIndexPath:indexPath];
    CGRect rect = cell.frame;
    
    NSArray* arr = self.values[indexPath.section];
    Card* card = arr[indexPath.row];

    [BrowserResultViewController showPopupForCard:card inView:collectionView fromRect:rect];
}

+(void) showPopupForCard:(Card*)card inView:(UIView*)view fromRect:(CGRect)rect
{
    UIAlertController* sheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [sheet addAction:[UIAlertAction actionWithTitle:l10n(@"Find decks using this card") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[NSNotificationCenter defaultCenter] postNotificationName:BROWSER_FIND object:self userInfo:@{ @"code": card.code }];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:l10n(@"New deck with this card") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[NSNotificationCenter defaultCenter] postNotificationName:BROWSER_NEW object:self userInfo:@{ @"code": card.code }];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:l10n(@"ANCUR page for this card") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:card.ancurLink]];
    }]];
    
    UIPopoverPresentationController* popover = sheet.popoverPresentationController;
    popover.sourceRect = rect;
    popover.sourceView = view;
    popover.permittedArrowDirections = UIPopoverArrowDirectionUp|UIPopoverArrowDirectionDown;
    
    NSAssert(instance != nil, @"oops");
    [instance presentViewController:sheet animated:NO completion:nil];
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    BrowserSectionHeaderView* header = nil;
    if (kind == UICollectionElementKindSectionHeader)
    {
        header = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"sectionHeader" forIndexPath:indexPath];
        
        NSArray* arr = self.values[indexPath.section];
        header.header.text = [NSString stringWithFormat:@"%@ (%lu)", self.sections[indexPath.section], (unsigned long)arr.count ];
    }
    
    NSAssert(header != nil, @"no header?");
    return header;
}

#pragma mark pinch gesture

-(void) pinchGesture:(UIPinchGestureRecognizer*)gesture
{
    static CGFloat scaleStart;
    static NSIndexPath* startIndex;
    
    if (gesture.state == UIGestureRecognizerStateBegan)
    {
        scaleStart = self.scale;
        CGPoint startPoint = [gesture locationInView:self.collectionView];
        startIndex = [self.collectionView indexPathForItemAtPoint:startPoint];
    }
    else if (gesture.state == UIGestureRecognizerStateChanged)
    {
        self.scale = scaleStart * gesture.scale;
    }
    
    self.scale = MAX(self.scale, 0.5);
    self.scale = MIN(self.scale, 1.0);
    
    [self.collectionView reloadData];
    if (startIndex)
    {
        [self.collectionView scrollToItemAtIndexPath:startIndex atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
    }
}

#pragma mark keyboard show/hide

-(void) willShowKeyboard:(NSNotification*)sender
{
    CGRect kbRect = [[sender.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    float kbHeight = kbRect.size.height;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(64.0, 0.0, kbHeight, 0.0);
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;
    
    self.collectionView.contentInset = contentInsets;
    self.collectionView.scrollIndicatorInsets = contentInsets;
}

-(void) willHideKeyboard:(NSNotification*)sender
{
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(64, 0, 0, 0);
    
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;
    
    self.collectionView.contentInset = contentInsets;
    self.collectionView.scrollIndicatorInsets = contentInsets;
}

@end
