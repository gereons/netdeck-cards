//
//  BrowserResultViewController.m
//  Net Deck
//
//  Created by Gereon Steffens on 03.08.14.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

#import "BrowserResultViewController.h"
#import "CardImageViewPopover.h"
#import "BrowserCell.h"
#import "BrowserImageCell.h"
#import "BrowserSectionHeaderView.h"

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
        @(NRBrowserSortByType): l10n(@"Type"),
        @(NRBrowserSortByFaction): l10n(@"Faction"),
        @(NRBrowserSortByTypeFaction): l10n(@"Type/Faction"),
        @(NRBrowserSortBySet): l10n(@"Set"),
        @(NRBrowserSortBySetFaction): l10n(@"Set/Faction"),
        @(NRBrowserSortBySetType): l10n(@"Set/Type"),
        @(NRBrowserSortBySetNumber): l10n(@"Set/Number")
    };
}

- (void) dealloc
{
    NSAssert(self.collectionView.window == nil, @"collectionView.window still set");
    
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
    CGFloat scale = [settings floatForKey:SettingsKeys.BROWSER_VIEW_SCALE];
    self.scale = scale == 0 ? 1.0 : scale;
    
    self.sortType = [settings integerForKey:SettingsKeys.BROWSER_SORT_TYPE];
    
    // left buttons
    NSArray* selections = @[
        [UIImage imageNamed:@"deckview_card"],   // NRCardViewImage
        [UIImage imageNamed:@"deckview_table"],  // NRCardViewLargeTable
        [UIImage imageNamed:@"deckview_list"]    // NRCardViewSmallTable
    ];
    UISegmentedControl* viewSelector = [[UISegmentedControl alloc] initWithItems:selections];
    viewSelector.selectedSegmentIndex = [settings integerForKey:SettingsKeys.BROWSER_VIEW_STYLE];
    [viewSelector addTarget:self action:@selector(toggleView:) forControlEvents:UIControlEventValueChanged];
    self.toggleViewButton = [[UIBarButtonItem alloc] initWithCustomView:viewSelector];
    [self doToggleView:viewSelector.selectedSegmentIndex];
    
    self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
    UINavigationItem* topItem = self.navigationController.navigationBar.topItem;
    topItem.leftBarButtonItems = @[ self.toggleViewButton ];

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
    [self.collectionView registerNib:[UINib nibWithNibName:@"BrowserSectionHeaderView" bundle:nil]
          forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"sectionHeader"];
    
    self.collectionView.contentInset = UIEdgeInsetsMake(64, 0, 0, 0);
    self.collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(64, 0, 0, 0);
    self.collectionView.alwaysBounceVertical = YES;
    
    UIGestureRecognizer* pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGesture:)];
    [self.collectionView addGestureRecognizer:pinch];
    
    UIGestureRecognizer* longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGesture:)];
    [self.collectionView addGestureRecognizer:longPress];
    
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
    layout.headerReferenceSize = CGSizeMake(703, 22);
    layout.sectionInset = UIEdgeInsetsMake(2, 2, 2, 2);
    layout.minimumInteritemSpacing = 3;
    layout.minimumLineSpacing = 3;
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(willShowKeyboard:) name:UIKeyboardWillShowNotification object:nil];
    [nc addObserver:self selector:@selector(willHideKeyboard:) name:UIKeyboardWillHideNotification object:nil];
    
    [self updateDisplay:self.cardList];
}

-(void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    [settings setObject:@(self.scale) forKey:SettingsKeys.BROWSER_VIEW_SCALE];
    [settings setObject:@(self.sortType) forKey:SettingsKeys.BROWSER_SORT_TYPE];
    
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
    
    self.popup = [UIAlertController actionSheetWithTitle:nil message:nil];
    
    [self.popup addAction:[UIAlertAction actionWithTitle:l10n(@"Type") handler:^(UIAlertAction *action) {
        [self changeSortType:NRBrowserSortByType];
    }]];
    [self.popup addAction:[UIAlertAction actionWithTitle:l10n(@"Faction") handler:^(UIAlertAction *action) {
        [self changeSortType:NRBrowserSortByFaction];
    }]];
    [self.popup addAction:[UIAlertAction actionWithTitle:l10n(@"Type/Faction") handler:^(UIAlertAction *action) {
        [self changeSortType:NRBrowserSortByTypeFaction];
    }]];
    [self.popup addAction:[UIAlertAction actionWithTitle:l10n(@"Set") handler:^(UIAlertAction *action) {
        [self changeSortType:NRBrowserSortBySet];
    }]];
    [self.popup addAction:[UIAlertAction actionWithTitle:l10n(@"Set/Faction") handler:^(UIAlertAction *action) {
        [self changeSortType:NRBrowserSortBySetFaction];
    }]];
    [self.popup addAction:[UIAlertAction actionWithTitle:l10n(@"Set/Type") handler:^(UIAlertAction *action) {
        [self changeSortType:NRBrowserSortBySetType];
    }]];
    [self.popup addAction:[UIAlertAction actionWithTitle:l10n(@"Set/Number") handler:^(UIAlertAction *action) {
        [self changeSortType:NRBrowserSortBySetNumber];
    }]];
    
    [self.popup addAction:[UIAlertAction cancelAction:^(UIAlertAction *action) {
        self.popup = nil;
    }]];
    
    UIPopoverPresentationController* popover = self.popup.popoverPresentationController;
    popover.barButtonItem = sender;
    popover.sourceView = self.view;
    popover.permittedArrowDirections = UIPopoverArrowDirectionAny;
    [self.popup.view layoutIfNeeded];
    
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
    [[NSUserDefaults standardUserDefaults] setInteger:viewMode forKey:SettingsKeys.BROWSER_VIEW_STYLE];
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
    if (!self.tableView.hidden)
    {
        [self.tableView reloadData];
    }
    
    if (!self.collectionView.hidden)
    {
        [self.collectionView.collectionViewLayout invalidateLayout];
        [self.collectionView reloadData];
    }
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
    return self.tableView.hidden ? 0 : self.sections.count;
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
    
    Card* card = [self.values objectAtIndexPath:indexPath];
    
    cell.card = card;
    
    return cell;
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Card* card = [self.values objectAtIndexPath:indexPath];
    
    CGRect rect = [self.tableView rectForRowAtIndexPath:indexPath];
    [CardImageViewPopover showForCard:card fromRect:rect inViewController:self subView:self.tableView];
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
    return self.collectionView.hidden ? 0 : self.sections.count;
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
    
    Card* card = [self.values objectAtIndexPath:indexPath];
    
    cell.card = card;
    
    return cell;
}

-(void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell* cell = [collectionView cellForItemAtIndexPath:indexPath];
    CGRect rect = cell.frame;
    
    Card* card = [self.values objectAtIndexPath:indexPath];

    [BrowserResultViewController showPopupForCard:card inView:collectionView fromRect:rect];
}

+(void) showPopupForCard:(Card*)card inView:(UIView*)view fromRect:(CGRect)rect
{
    UIAlertController* sheet = [UIAlertController actionSheetWithTitle:nil message:nil];
    
    [sheet addAction:[UIAlertAction actionWithTitle:l10n(@"Find decks using this card") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[NSNotificationCenter defaultCenter] postNotificationName:Notifications.BROWSER_FIND object:self userInfo:@{ @"code": card.code }];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:l10n(@"New deck with this card") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[NSNotificationCenter defaultCenter] postNotificationName:Notifications.BROWSER_NEW object:self userInfo:@{ @"code": card.code }];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:l10n(@"ANCUR page for this card") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        LOG_EVENT(@"Open ANCUR", @{@"Card": card.name});
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:card.ancurLink]];
    }]];
    
    UIPopoverPresentationController* popover = sheet.popoverPresentationController;
    popover.sourceRect = rect;
    popover.sourceView = view;
    popover.permittedArrowDirections = UIPopoverArrowDirectionUp|UIPopoverArrowDirectionDown;
    [sheet.view layoutIfNeeded];
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

#pragma mark long press gesture

-(void) longPressGesture:(UIGestureRecognizer*)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan)
    {
        CGPoint point = [gesture locationInView:self.collectionView];
        NSIndexPath* indexPath = [self.collectionView indexPathForItemAtPoint:point];
        if (indexPath)
        {
            UICollectionViewCell* cell = [self.collectionView cellForItemAtIndexPath:indexPath];
            
            Card* card = [self.values objectAtIndexPath:indexPath];
            
            [CardImageViewPopover showForCard:card fromRect:cell.frame inViewController:self subView:self.collectionView];
        }
    }
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
        
        self.scale = MAX(self.scale, 0.5);
        self.scale = MIN(self.scale, 1.0);
        
        [self.collectionView reloadData];
        if (startIndex)
        {
            BOOL ok = startIndex.section < self.values.count;
            if (ok)
            {
                NSArray* arr = self.values[startIndex.section];
                ok = startIndex.row < arr.count;
            }
            
            if (ok)
            {
                    [self.collectionView scrollToItemAtIndexPath:startIndex atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
            }
        }
    }
    else if (gesture.state == UIGestureRecognizerStateEnded)
    {
        startIndex = nil;
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
