//
//  CardFilterViewController.m
//  Net Deck
//
//  Created by Gereon Steffens on 30.05.14.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

#import "CardFilterViewController.h"
#import "DeckListViewController.h"
#import "CardFilterPopover.h"
#import "CardImageViewPopover.h"
#import "CardFilterThumbView.h"
#import "CardFilterSectionHeaderView.h"
#import "SmallPipsView.h"

@interface CardFilterViewController ()

@property UIBarButtonItem* revertButton;
@property (nonatomic) NRRole role;
@property SubstitutableNavigationController* snc;
@property CardList* cardList;
@property NSArray* cards;
@property NSArray* sections;

@property NSString* searchText;
@property NRSearchScope scope;
@property BOOL sendNotifications;
@property NSString* selectedType;
@property NSSet* selectedTypes;
@property CGRect smallResultFrame;
@property CGRect largeResultFrame;
@property NSMutableDictionary* selectedValues;

@property int influenceValue;

@end

@implementation CardFilterViewController

#define LARGE_CELL_HEIGHT   140
#define SMALL_CELL_HEIGHT   107

enum { TYPE_BUTTON, FACTION_BUTTON, SET_BUTTON, SUBTYPE_BUTTON };
enum { VIEW_LIST, VIEW_IMG_2, VIEW_IMG_3 };
enum { ADD_BUTTON_TABLE, ADD_BUTTON_COLLECTION };

static NSArray* scopes;
static NSDictionary* scopeLabels;
static BOOL showAllFilters = YES;
static NSInteger viewMode = VIEW_LIST;

+(void)initialize
{
    scopes = @[ @"all text", @"card name", @"card text" ];
    
    scopeLabels = @{ @(NRSearchScopeAll): l10n(@"All"),
                     @(NRSearchScopeName): l10n(@"Name"),
                     @(NRSearchScopeText): l10n(@"Text")
                     };
}

- (id) initWithRole:(NRRole)role
{
    if ((self = [self initWithNibName:@"CardFilterViewController" bundle:nil]))
    {
        self.role = role;
        
        self.deckListViewController = [[DeckListViewController alloc] initWithNibName:@"DeckListViewController" bundle:nil];
        self.deckListViewController.role = role;
        
        self.snc = [[SubstitutableNavigationController alloc] initWithRootViewController:self.deckListViewController];
    }
    return self;
}

-(id) initWithRole:(NRRole)role andFile:(NSString *)filename
{
    if ((self = [self initWithRole:role]))
    {
        [self.deckListViewController loadDeckFromFile:filename];
    }
    return self;
}

-(id) initWithRole:(NRRole)role andDeck:(Deck *)deck
{
    NSAssert(role == deck.role, @"role mismatch");
    if ((self = [self initWithRole:role]))
    {
        self.deckListViewController.deck = deck;
    }
    return self;
}

-(void) dealloc
{
    NSAssert(self.collectionView.window == nil, @"collectionView.window still set");
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    self.tableView = nil;
    
    self.collectionView.delegate = nil;
    self.collectionView.dataSource = nil;
    self.collectionView = nil;
    
    self.searchField.delegate = nil;
    self.searchField = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    showAllFilters = [settings boolForKey:SettingsKeys.SHOW_ALL_FILTERS];
    viewMode = [settings integerForKey:SettingsKeys.FILTER_VIEW_MODE];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationController.navigationBar.backgroundColor = [UIColor whiteColor];
    
    self.cardList = [[CardList alloc] initForRole:self.role];
    [self initCards];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [self.collectionView registerNib:[UINib nibWithNibName:@"CardFilterThumbView" bundle:nil] forCellWithReuseIdentifier:@"cardThumb"];
    [self.collectionView registerNib:[UINib nibWithNibName:@"CardFilterSmallThumbView" bundle:nil] forCellWithReuseIdentifier:@"cardSmallThumb"];
    [self.collectionView registerNib:[UINib nibWithNibName:@"CardFilterSectionHeaderView" bundle:nil]
          forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"sectionHeader"];
    self.collectionView.alwaysBounceVertical = YES;
   
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    
    UICollectionViewFlowLayout* layout = (UICollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
    layout.headerReferenceSize = CGSizeMake(320, 22);
    layout.sectionInset = UIEdgeInsetsMake(2, 2, 0, 2);
    layout.minimumInteritemSpacing = 3;
    layout.minimumLineSpacing = 3;

    CGRect rect = [self.sliderContainer convertRect:self.influenceSeparator.frame toView:self.view];
    CGFloat buttonBoxHeight = self.bottomSeparator.frame.origin.y - rect.origin.y;
    
    rect = self.tableView.frame;
    self.smallResultFrame = rect;
    self.largeResultFrame = CGRectMake(rect.origin.x, rect.origin.y-buttonBoxHeight, rect.size.width, rect.size.height+buttonBoxHeight);
    
    NSString* moreLess = showAllFilters ? l10n(@"Less △") : l10n(@"More ▽");
    [self.moreLessButton setTitle:moreLess forState:UIControlStateNormal];
    self.influenceSeparator.hidden = showAllFilters;
    
    self.viewMode.selectedSegmentIndex = viewMode;
    self.collectionView.hidden = viewMode == VIEW_LIST;
    self.tableView.hidden = viewMode != VIEW_LIST;
    
    self.revertButton = [[UIBarButtonItem alloc] initWithTitle:l10n(@"Cancel")
                                                         style:UIBarButtonItemStylePlain
                                                        target:self
                                                        action:@selector(revertDeck:)];
    
    [self resetAllButtons];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self setEdgesForExtendedLayout:UIRectEdgeBottom];
    
    DetailViewManager *detailViewManager = (DetailViewManager*)self.splitViewController.delegate;
    detailViewManager.detailViewController = self.snc;
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self setResultFrames];
    
    UINavigationItem* topItem = self.navigationController.navigationBar.topItem;
    topItem.title = l10n(@"Filter");
    topItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:l10n(@"Clear")
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(clearFiltersClicked:)];
    
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(willShowKeyboard:) name:UIKeyboardWillShowNotification object:nil];
    [nc addObserver:self selector:@selector(willHideKeyboard:) name:UIKeyboardWillHideNotification object:nil];
    [nc addObserver:self selector:@selector(addTopCard:) name:Notifications.ADD_TOP_CARD object:nil];
    [nc addObserver:self selector:@selector(deckChanged:) name:Notifications.DECK_CHANGED object:nil];
    [nc addObserver:self selector:@selector(deckSaved:) name:Notifications.DECK_SAVED object:nil];
    [nc addObserver:self selector:@selector(nameAlertWillAppear:) name:Notifications.NAME_ALERT object:nil];
    
    [self initFilters];
}

-(void) viewDidDisappear:(BOOL)animated
{
    self.deckListViewController = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super viewDidDisappear:animated];
    
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    [settings setObject:@(showAllFilters) forKey:SettingsKeys.SHOW_ALL_FILTERS];
    [settings setObject:@(viewMode) forKey:SettingsKeys.FILTER_VIEW_MODE];
}

-(BOOL) canBecomeFirstResponder {
    return YES;
}

-(NSArray*) keyCommands {
    return @[
        KEYCMD(@"F", UIKeyModifierCommand, startTextSearch:, @"Find Cards"),
        KEYCMD(@"A", UIKeyModifierCommand, changeScopeKeyCmd:, @"Scope: All"),
        KEYCMD(@"N", UIKeyModifierCommand, changeScopeKeyCmd:, @"Scope: Name"),
        KEYCMD(@"T", UIKeyModifierCommand, changeScopeKeyCmd:, @"Scope: Text"),
        [UIKeyCommand keyCommandWithInput:UIKeyInputEscape modifierFlags:0 action:@selector(escKeyPressed:)]
    ];
}

-(void) startTextSearch:(UIKeyCommand*)keyCommand {
    [self.searchField becomeFirstResponder];
}

-(void) escKeyPressed:(UIKeyCommand*) keyCmd {
    [self.searchField resignFirstResponder];
}

-(void) setResultFrames
{
    if (viewMode == VIEW_LIST)
    {
        self.tableView.frame = showAllFilters ? self.smallResultFrame : self.largeResultFrame;
    }
    else
    {
        self.collectionView.frame = showAllFilters ? self.smallResultFrame : self.largeResultFrame;
    }
}

- (void) initCards
{
    TableData* data = [self.cardList dataForTableView];
    self.cards = data.values;
    self.sections = data.sections;
}

-(void) deckChanged:(NSNotification*)notification
{
    Deck* deck = self.deckListViewController.deck;
    Card* identity = deck.identity;
    if (identity != nil)
    {
        if (self.role == NRRoleCorp) {
            [self.cardList preFilterForCorp:identity];
        }
        else if (self.role == NRRoleRunner) {
            [self.cardList preFilterForRunner:identity];
        }
        [self initCards];
    }

    if (self.influenceValue != -1)
    {
        if (identity)
        {
            [self.cardList filterByInfluence:self.influenceValue forFaction:identity.faction];
        }
        else
        {
            [self.cardList filterByInfluence:self.influenceValue];
        }
        [self initCards];
    }
    
    [self setBackOrRevertButton];
    
    [self reloadData];
}

-(void) deckSaved:(id)notification
{
    [self setBackOrRevertButton];
}

-(void) setBackOrRevertButton
{
    Deck* deck = self.deckListViewController.deck;
    UINavigationItem* topItem = self.navigationController.navigationBar.topItem;
    
    if (deck.modified) {
        topItem.leftBarButtonItem = self.revertButton;
    } else {
        topItem.leftBarButtonItem = nil;
    }
}

-(void) revertDeck:(id)sender
{
    Deck* deck = self.deckListViewController.deck;
    
    if (deck.filename) {
        deck = [DeckManager loadDeckFromPath:deck.filename useCache:NO];
        [self reloadData];
        self.deckListViewController.deck = deck;
        [self setBackOrRevertButton];
    } else {
        self.navigationController.navigationBar.topItem.leftBarButtonItem = nil;
        [self.navigationController popToRootViewControllerAnimated:NO];
    }
}

-(void) initFilters
{
    self.role = self.role;
    
    self.typeButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.setButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.factionButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.subtypeButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    
    self.typeButton.tag = TYPE_BUTTON;
    self.setButton.tag = SET_BUTTON;
    self.factionButton.tag = FACTION_BUTTON;
    self.subtypeButton.tag = SUBTYPE_BUTTON;
    
    self.costSlider.maximumValue = 1+(self.role == NRRoleRunner ? [CardManager maxRunnerCost] : [CardManager maxCorpCost]);
    self.muSlider.maximumValue = 1+[CardManager maxMU];
    self.strengthSlider.maximumValue = 1+[CardManager maxStrength];
    self.influenceSlider.maximumValue = 1+[CardManager maxInfluence];
    self.apSlider.maximumValue = 1+[CardManager maxAgendaPoints];
    
    [self.costSlider setThumbImage:[UIImage imageNamed:@"credit_slider"] forState:UIControlStateNormal];
    [self.muSlider setThumbImage:[UIImage imageNamed:@"mem_slider"] forState:UIControlStateNormal];
    [self.strengthSlider setThumbImage:[UIImage imageNamed:@"strength_slider"] forState:UIControlStateNormal];
    [self.influenceSlider setThumbImage:[UIImage imageNamed:@"influence_slider"] forState:UIControlStateNormal];
    [self.apSlider setThumbImage:[UIImage imageNamed:@"point_slider"] forState:UIControlStateNormal];
    
    self.searchField.placeholder = l10n(@"Search Cards");
    self.searchField.clearButtonMode = UITextFieldViewModeAlways;
    
    [self clearFilters];
}

-(void) setRole:(NRRole)role
{
    self->_role = role;
    
    self.muLabel.hidden = role == NRRoleCorp;
    self.muSlider.hidden = role == NRRoleCorp;
    
    self.apLabel.hidden = role == NRRoleRunner;
    self.apSlider.hidden = role == NRRoleRunner;
}

-(void) reloadData
{
    if (viewMode == VIEW_LIST)
    {
        [self.tableView reloadData];
    }
    else
    {
        [self.collectionView.collectionViewLayout invalidateLayout];
        [self.collectionView reloadData];
    }
}

#pragma mark clear filters

-(void) clearFiltersClicked:(id)sender
{
    [self.cardList clearFilters];
    [self clearFilters];
    
    [self initCards];
    [self reloadData];
}

-(void) clearFilters
{
    self.sendNotifications = NO;
    
    self.scope = NRSearchScopeName;
    [self.scopeButton setTitle:[NSString stringWithFormat:@"%@ ▾", scopeLabels[@(self.scope)]] forState:UIControlStateNormal];
    self.scopeButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.scopeButton.titleLabel.minimumScaleFactor = 0.5;
    
    self.searchField.text = @"";
    self.searchText = @"";
    
    self.costSlider.value = 0;
    [self costValueChanged:nil];
    
    self.muSlider.value = 0;
    [self muValueChanged:nil];
    
    self.influenceSlider.value = 0;
    [self influenceValueChanged:nil];
    
    self.strengthSlider.value = 0;
    [self strengthValueChanged:nil];
    
    self.apSlider.value = 0;
    [self apValueChanged:nil];
    
    [self resetAllButtons];
    self.selectedType = kANY;
    self.selectedTypes = nil;
    
    self.selectedValues = [NSMutableDictionary dictionary];
    
    self.sendNotifications = YES;
}

-(void) addTopCard:(NSNotification*)sender
{
    if (self.cards.count > 0)
    {
        NSArray* arr = self.cards[0];
        if (arr.count > 0)
        {
            Card* card = arr[0];
            [self.deckListViewController addCard:card];
            [self setBackOrRevertButton];
            [self reloadData];
        }
    }
}

#pragma mark keyboard show/hide

-(void) willShowKeyboard:(NSNotification*)sender
{
    if (!self.searchField.isFirstResponder)
    {
        return;
    }
    
    CGFloat topY = self.searchSeparator.frame.origin.y;
    
    CGRect keyboardFrame = [[sender.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat kbHeight = keyboardFrame.size.height;
    
    CGRect keyboardRect = [self.view convertRect:keyboardFrame fromView:self.view.window];
    CGFloat viewHeight = self.view.frame.size.height;
    
    if ((keyboardRect.origin.y + keyboardRect.size.height) > viewHeight) {
        // external keyboard present, virtual kb is offscreen
        kbHeight = 768 - keyboardFrame.origin.y;
    }
    
    float tableHeight = 768 - kbHeight - topY - 64; // screen height - kbd height - height of visible filter - height of status/nav bar
    
    CGRect newFrame = self.tableView.frame;
    newFrame.origin.y = topY + 1;
    newFrame.size.height = tableHeight;
    
    float animDuration = [[sender.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    [UIView animateWithDuration:animDuration animations:^{
        self.tableView.frame = newFrame;
        self.collectionView.frame = newFrame;
    }];
}

-(void) willHideKeyboard:(NSNotification*)sender
{
    if (!self.searchField.isFirstResponder)
    {
        return;
    }
    
    // explicitly resignFirstResponser, since the kb may have been auto-dismissed by the identity selection form
    [self.searchField resignFirstResponder];
    NSTimeInterval animDuration = [[sender.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    
    [UIView animateWithDuration:animDuration animations:^{
        [self setResultFrames];
    }];
}

-(void) nameAlertWillAppear:(id)notification
{
    if (self.searchField.isFirstResponder)
    {
        [self.searchField resignFirstResponder];
    }
}

#pragma mark button callbacks

-(void) moreLessClicked:(id)sender
{
    showAllFilters = !showAllFilters;
    
    if (!showAllFilters)
    {
        // reset all filters that are now inaccessible
        self.costSlider.value = 0;
        [self costValueChanged:nil];
        
        self.muSlider.value = 0;
        [self muValueChanged:nil];
        
        self.strengthSlider.value = 0;
        [self strengthValueChanged:nil];
        
        self.apSlider.value = 0;
        [self apValueChanged:nil];
    }
    
    if ([self.searchField isFirstResponder])
    {
        [self.searchField resignFirstResponder];
    }
    
    NSString* moreLess = showAllFilters ? l10n(@"Less △") : l10n(@"More ▽");
    [self.moreLessButton setTitle:moreLess forState:UIControlStateNormal];
   
    if (showAllFilters)
    {
        self.influenceSeparator.hidden = YES;
    }
    
    NSTimeInterval animDuration = 0.10;
    [UIView animateWithDuration:animDuration
        animations:^{
            [self setResultFrames];
        }
        completion:^(BOOL finished){
            self.influenceSeparator.hidden = showAllFilters;
        }];
}

-(void) viewModeChanged:(UISegmentedControl*)sender
{
    NSIndexPath* scrollToPath;
    
    if (viewMode != VIEW_LIST)
    {
        // remember the top-left visible card
        
        NSArray* cells = [self.collectionView indexPathsForVisibleItems]; // wtf is this unordered?
        NSArray *sortedIndexPaths = [cells sortedArrayUsingComparator:^NSComparisonResult(NSIndexPath* ip1, NSIndexPath* ip2) {
            return [ip1 compare:ip2];
        }];
        // find the first cell that's completely visible
        for (NSIndexPath* indexPath in sortedIndexPaths)
        {
            UICollectionViewCell* cell = [self.collectionView cellForItemAtIndexPath:indexPath];
            CGRect cellRect = cell.frame;
            cellRect = [self.collectionView convertRect:cellRect toView:self.collectionView.superview];
            BOOL completelyVisible = CGRectContainsRect(self.collectionView.frame, cellRect);
            if (completelyVisible)
            {
                scrollToPath = indexPath;
                break;
            }
        }
    }
    else
    {
        NSArray* cells = [self.tableView indexPathsForVisibleRows];
        // find the first cell that's completely visible
        for (NSIndexPath* indexPath in cells)
        {
            CGRect cellRect = [self.tableView rectForRowAtIndexPath:indexPath];
            cellRect = [self.tableView convertRect:cellRect toView:self.tableView.superview];
            BOOL completelyVisible = CGRectContainsRect(self.tableView.frame, cellRect);
            if (completelyVisible)
            {
                scrollToPath = indexPath;
                break;
            }
        }
    }
    
    viewMode = sender.selectedSegmentIndex;
    self.collectionView.hidden = viewMode == VIEW_LIST;
    self.tableView.hidden = viewMode != VIEW_LIST;
    
    [self reloadData];
    [self setResultFrames];
    
    if (scrollToPath)
    {
        if (!self.collectionView.hidden)
        {
            // doesn't work, card images are below the sticky header
            // [self.collectionView scrollToItemAtIndexPath:scrollToPath atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
            
            // calculate scroll offset manually
            CGFloat y;
            if (viewMode == VIEW_IMG_2)
            {
                y = (scrollToPath.row / 2) * (LARGE_CELL_HEIGHT + 3);
            }
            else
            {
                y = (scrollToPath.row / 3) * (SMALL_CELL_HEIGHT + 3);
                
            }
            [self.collectionView setContentOffset:CGPointMake(0, y) animated:NO];
        }
        if (!self.tableView.hidden)
        {
            [self.tableView scrollToRowAtIndexPath:scrollToPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
        }
    }
}

-(void) typeClicked:(UIButton*)sender
{
    TableData* data = [[TableData alloc] initWithValues:[CardType typesForRole:self.role]];
    id selected = [self.selectedValues objectForKey:@(TYPE_BUTTON)];
    
    [CardFilterPopover showFromButton:sender inView:self entries:data type:@"Type" selected:selected];
}

-(void) setClicked:(UIButton*)sender
{
    id selected = [self.selectedValues objectForKey:@(SET_BUTTON)];
    [CardFilterPopover showFromButton:sender inView:self entries:[CardSets allEnabledSetsForTableview] type:@"Set" selected:selected];
}

-(void) subtypeClicked:(UIButton*)sender
{
    NSMutableArray* arr;
    if (self.selectedTypes)
    {
        arr = [CardManager subtypesForRole:self.role andTypes:self.selectedTypes includeIdentities:NO].mutableCopy;
    }
    else
    {
        arr = [CardManager subtypesForRole:self.role andType:self.selectedType includeIdentities:NO].mutableCopy;
    }
    [arr insertObject:kANY atIndex:0];
    TableData* data = [[TableData alloc] initWithValues:arr];
    id selected = [self.selectedValues objectForKey:@(SUBTYPE_BUTTON)];
    
    [CardFilterPopover showFromButton:sender inView:self entries:data type:@"Subtype" selected:selected];
}

-(void) factionClicked:(UIButton*)sender
{
    TableData* data = [[TableData alloc] initWithValues:[Faction factionsForRole:self.role]];
    id selected = [self.selectedValues objectForKey:@(FACTION_BUTTON)];
    
    [CardFilterPopover showFromButton:sender inView:self entries:data type:@"Faction" selected:selected];
}

-(void) filterCallback:(UIButton *)button type:(NSString*)type value:(NSObject *)object
{
    NSString* value = [object isKindOfClass:[NSString class]] ? (NSString*)object : nil;
    NSSet* values = [object isKindOfClass:[NSSet class]] ? (NSSet*)object : nil;
    NSAssert(value != nil || values != nil, @"values");
    
    if (button.tag == TYPE_BUTTON)
    {
        if (value)
        {
            self.selectedType = value;
            self.selectedTypes = nil;
        }
        if (values)
        {
            self.selectedType = @"";
            self.selectedTypes = values;
        }
        
        [self resetButton:SUBTYPE_BUTTON];
    }
    [self.selectedValues setObject:value ? value : values forKey:@(button.tag)];
    
    [self updateFilter:type value:object];
}

-(void) resetAllButtons
{
    [self resetButton:TYPE_BUTTON];
    [self resetButton:SET_BUTTON];
    [self resetButton:FACTION_BUTTON];
    [self resetButton:SUBTYPE_BUTTON];
}

-(void) resetButton:(NSInteger)tag
{
    UIButton* btn;
    NSString* pfx;
    switch (tag)
    {
        case SET_BUTTON:
        {
            btn = self.setButton;
            pfx = @"Set";
            break;
        }
        case TYPE_BUTTON:
        {
            btn = self.typeButton;
            pfx = @"Type";
            // reset subtypes to "any"
            [self resetButton:SUBTYPE_BUTTON];
            break;
        }
        case SUBTYPE_BUTTON:
        {
            btn = self.subtypeButton;
            pfx = @"Subtype";
            break;
        }
        case FACTION_BUTTON:
        {
            btn = self.factionButton;
            pfx = @"Faction";
            break;
        }
    }
    
    [self.selectedValues setObject:kANY forKey:@(tag)];
    [self updateFilter:[pfx lowercaseString] value:kANY];
    [btn setTitle:[NSString stringWithFormat:@"%@: %@", l10n(pfx), l10n(kANY)] forState:UIControlStateNormal];
    
    NSAssert(btn != nil, @"no button");
}

#pragma mark slider callbacks

-(void) strengthValueChanged:(UISlider*)sender
{
    int value = round(sender.value);
    // NSLog(@"str: %f %d", sender.value, value);
    sender.value = value--;
    self.strengthLabel.text = [NSString stringWithFormat:l10n(@"Strength: %@"), value == -1 ? l10n(@"All") : [@(value) stringValue]];
    [self updateFilter:@"strength" value:@(value)];
}

-(void) muValueChanged:(UISlider*)sender
{
    int value = round(sender.value);
    // NSLog(@"mu: %f %d", sender.value, value);
    sender.value = value--;
    self.muLabel.text = [NSString stringWithFormat:l10n(@"MU: %@"), value == -1 ? l10n(@"All") : [@(value) stringValue]];
    [self updateFilter:@"mu" value:@(value)];
}

-(void) costValueChanged:(UISlider*)sender
{
    int value = round(sender.value);
    // NSLog(@"cost: %f %d", sender.value, value);
    sender.value = value--;
    self.costLabel.text = [NSString stringWithFormat:l10n(@"Cost: %@"), value == -1 ? l10n(@"All") : [@(value) stringValue]];
    [self updateFilter:@"card cost" value:@(value)];
}

-(void) influenceValueChanged:(UISlider*)sender
{
    int value = round(sender.value);
    // NSLog(@"inf: %f %d", sender.value, value);
    sender.value = value--;
    self.influenceValue = value;
    self.influenceLabel.text = [NSString stringWithFormat:l10n(@"Influence: %@"), value == -1 ? l10n(@"All") : [@(value) stringValue]];
    [self updateFilter:@"influence" value:@(value)];
}

-(void) apValueChanged:(UISlider*)sender
{
    int value = round(sender.value);
    // NSLog(@"ap: %f %d", sender.value, value);
    sender.value = value--;
    self.apLabel.text = [NSString stringWithFormat:l10n(@"AP: %@"), value == -1 ? l10n(@"All") : [@(value) stringValue]];
    [self updateFilter:@"agendaPoints" value:@(value)];
}

#pragma mark scope

-(void) scopeClicked:(UIButton*)sender
{
    UIAlertController* sheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [sheet addAction:[UIAlertAction actionWithTitle:CHECKED_TITLE(l10n(@"All"), self.scope == NRSearchScopeAll )
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
                                                [self changeScope:NRSearchScopeAll];
                                            }]];
    [sheet addAction:[UIAlertAction actionWithTitle:CHECKED_TITLE(l10n(@"Name"), self.scope == NRSearchScopeName)
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
                                                [self changeScope:NRSearchScopeName];
                                            }]];
    [sheet addAction:[UIAlertAction actionWithTitle:CHECKED_TITLE(l10n(@"Text"), self.scope == NRSearchScopeText)
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
                                                [self changeScope:NRSearchScopeText];
                                            }]];
    
    UIPopoverPresentationController* popover = sheet.popoverPresentationController;
    popover.sourceRect = sender.frame;
    popover.sourceView = self.view;
    popover.permittedArrowDirections = UIPopoverArrowDirectionUp;
    [sheet.view layoutIfNeeded];
    
    [self presentViewController:sheet animated:NO completion:nil];
}

-(void) changeScopeKeyCmd:(UIKeyCommand*)keyCommand {
    if ([keyCommand.input.lowercaseString isEqualToString:@"a"]) {
        [self changeScope:NRSearchScopeAll];
    }
    else if ([keyCommand.input.lowercaseString isEqualToString:@"n"]) {
        [self changeScope:NRSearchScopeName];
    }
    else if ([keyCommand.input.lowercaseString isEqualToString:@"t"]) {
        [self changeScope:NRSearchScopeText];
    }
}

-(void) changeScope:(NRSearchScope)scope
{
    self.scope = scope;
    [self.scopeButton setTitle:[NSString stringWithFormat:@"%@ ▾", scopeLabels[@(self.scope)]] forState:UIControlStateNormal];
    
    [self updateFilter:scopes[self.scope] value:self.searchText];
}

#pragma mark text search

-(BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if ([CardImageViewPopover dismiss])
    {
        return NO;
    }
    
    self.searchText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    // NSLog(@"search: %d %@", self.scope, self.searchText);
    
    [self updateFilter:scopes[self.scope] value:self.searchText];
    
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    if ([CardImageViewPopover dismiss])
    {
        return NO;
    }
    
    self.searchText = @"";
    
    [self updateFilter:scopes[self.scope] value:self.searchText];
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if ([CardImageViewPopover dismiss])
    {
        return NO;
    }
    
    if (self.searchText.length > 0)
    {
        [textField setSelectedTextRange:[textField textRangeFromPosition:textField.beginningOfDocument toPosition:textField.endOfDocument]];
        [[NSNotificationCenter defaultCenter] postNotificationName:Notifications.ADD_TOP_CARD object:self];
    }
    else
    {
        [textField resignFirstResponder];
    }
    return NO;
    
}

#pragma mark filter update

-(void) updateFilter:(NSString*)type value:(NSObject*)valueObject
{
    // NSLog(@"update filter %@ %@", type, valueObject);
    NSString* value;
    NSSet* values;
    NSNumber* num;
    
    if ([valueObject isKindOfClass:[NSString class]])
    {
        value = (NSString*)valueObject;
    }
    else if ([valueObject isKindOfClass:[NSSet class]])
    {
        values = (NSSet*)valueObject;
    }
    else if ([valueObject isKindOfClass:[NSNumber class]])
    {
        num = (NSNumber*)valueObject;
    }
    NSAssert(value != nil || values != nil || num != nil, @"invalid values type");
    
    if ([type isEqualToString:@"mu"])
    {
        NSAssert(num != nil, @"need number");
        [self.cardList filterByMU:[num intValue]];
    }
    else if ([type isEqualToString:@"influence"])
    {
        NSAssert(num != nil, @"need number");
        Card* identity = self.deckListViewController.deck.identity;
        if (identity)
        {
            [self.cardList filterByInfluence:[num intValue] forFaction:identity.faction];
        }
        else
        {
            [self.cardList filterByInfluence:[num intValue]];
        }
    }
    else if ([type isEqualToString:@"faction"])
    {
        if (value)
        {
            [self.cardList filterByFaction:value];
        }
        else
        {
            NSAssert(values != nil, @"need values");
            [self.cardList filterByFactions:values];
        }
    }
    else if ([type isEqualToString:@"card name"])
    {
        NSAssert(value != nil, @"need value");
        [self.cardList filterByName:value];
    }
    else if ([type isEqualToString:@"card text"])
    {
        NSAssert(value != nil, @"need value");
        [self.cardList filterByText:value];
    }
    else if ([type isEqualToString:@"all text"])
    {
        NSAssert(value != nil, @"need value");
        [self.cardList filterByTextOrName:value];
    }
    else if ([type isEqualToString:@"subtype"])
    {
        if (value)
        {
            [self.cardList filterBySubtype:value];
        }
        else
        {
            NSAssert(values != nil, @"need values");
            [self.cardList filterBySubtypes:values];
        }
    }
    else if ([type isEqualToString:@"set"])
    {
        if (value)
        {
            [self.cardList filterBySet:value];
        }
        else
        {
            NSAssert(values != nil, @"need values");
            [self.cardList filterBySets:values];
        }
    }
    else if ([type isEqualToString:@"strength"])
    {
        NSAssert(num != nil, @"need number");
        [self.cardList filterByStrength:[num intValue]];
    }
    else if ([type isEqualToString:@"card cost"])
    {
        NSAssert(num != nil, @"need number");
        [self.cardList filterByCost:[num intValue]];
    }
    else if ([type isEqualToString:@"type"])
    {
        if (value)
        {
            [self.cardList filterByType:value];
        }
        else
        {
            [self.cardList filterByTypes:values];
        }
    }
    else if ([type isEqualToString:@"agendaPoints"])
    {
        NSAssert(num != nil, @"need number");
        [self.cardList filterByAgendaPoints:[num intValue]];
    }
    else
    {
        NSAssert(NO, @"unknown filter '%@'", type);
    }
    
    [self initCards];
    
    if (self.sendNotifications)
    {
        [self reloadData];
    }
}

#pragma mark - Table View

- (void) tableView:(UITableView *)tableView willDisplayHeaderView:(UITableViewHeaderFooterView *)view forSection:(NSInteger)section
{
    view.contentView.backgroundColor = UIColorFromRGB(0xEBEBEC);
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 22;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 38;
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSArray* cards = self.cards[section];
    return [NSString stringWithFormat:@"%@ (%ld)", self.sections[section], (long)cards.count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.tableView.hidden ? 0 : self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray* cards = self.cards[section];
    return cards.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* cellIdentifier = @"cardCell";
    
    Card *card = [self.cards objectAtIndexPath:indexPath];

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
        
        UIButton* button = [UIButton buttonWithType:UIButtonTypeContactAdd];
        button.frame = CGRectMake(0, 0, 30, 30);
        button.tag = ADD_BUTTON_TABLE;
        
        cell.accessoryView = button;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        SmallPipsView* pips = [SmallPipsView createWithFrame:CGRectMake(230, 0, 38, 38)];
        [cell.contentView addSubview:pips];
        
        [button addTarget:self action:@selector(addCardToDeck:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    for (UIView* v in [cell.contentView subviews])
    {
        if ([v isKindOfClass:[SmallPipsView class]])
        {
            SmallPipsView* pips = (SmallPipsView*)v;
            
            Card* identity = self.deckListViewController.deck.identity;
            
            NSInteger influence = card.influence;
            if (identity && card.faction == identity.faction)
            {
                influence = 0;
            }
            [pips setValue:influence];
            [pips setColor:card.factionColor];
            break;
        }
    }
    
    cell.textLabel.font = [UIFont systemFontOfSize:17];
    
    cell.textLabel.text = card.name;
    
    CardCounter* cc = [self.deckListViewController.deck findCard:card];
    cell.detailTextLabel.text = cc.count > 0 ? [@(cc.count) stringValue] : @"";
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Card *card = [self.cards objectAtIndexPath:indexPath];

    CGRect rect = [self.tableView rectForRowAtIndexPath:indexPath];
    [CardImageViewPopover showForCard:card fromRect:rect inView:self.tableView];
}

- (void) addCardToDeck:(UIButton*)sender
{
    NSIndexPath *indexPath = nil;
    
    if (sender.tag == ADD_BUTTON_TABLE)
    {
        CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
        indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    }
    else
    {
        CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.collectionView];
        indexPath = [self.collectionView indexPathForItemAtPoint:buttonPosition];
    }
    
    if (indexPath == nil)
    {
        return;
    }
    
    UITextField* textField = self.searchField;
    if (textField.isFirstResponder && textField.text.length > 0)
    {
        [textField setSelectedTextRange:[textField textRangeFromPosition:textField.beginningOfDocument toPosition:textField.endOfDocument]];
    }
    
    Card *card = [self.cards objectAtIndexPath:indexPath];
    if (card)
    {
        [self.deckListViewController addCard:card];
        [self setBackOrRevertButton];
        
        NSArray* paths = @[indexPath];
        
        if (viewMode == VIEW_LIST)
        {
            [self.tableView reloadRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationNone];
        }
        else
        {
            [UIView setAnimationsEnabled:NO];
            [self.collectionView reloadItemsAtIndexPaths:paths];
            [UIView setAnimationsEnabled:YES];
        }
    }
}

#pragma mark collectionview

-(UICollectionViewCell*) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSString* cellIdentifier = viewMode == VIEW_IMG_3 ? @"cardSmallThumb" : @"cardThumb";
    
    Card *card = [self.cards objectAtIndexPath:indexPath];
    CardCounter* cc = [self.deckListViewController.deck findCard:card];
    
    CardFilterThumbView* cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    cell.addButton.tag = ADD_BUTTON_COLLECTION;
    
    [cell.addButton addTarget:self action:@selector(addCardToDeck:) forControlEvents:UIControlEventTouchUpInside];
    
    cell.countLabel.text = cc.count > 0 ? [NSString stringWithFormat:@"×%lu", (unsigned long)cc.count] : @"";    
    cell.card = card;
    
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    Card *card = [self.cards objectAtIndexPath:indexPath];
    UICollectionViewCell* cell = [collectionView cellForItemAtIndexPath:indexPath];
    
    // convert to on-screen coordinates
    CGRect rect = [collectionView convertRect:cell.frame toView:self.collectionView];
    
    [CardImageViewPopover showForCard:card fromRect:rect inView:self.collectionView];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return viewMode == VIEW_IMG_3 ? CGSizeMake(103, SMALL_CELL_HEIGHT) : CGSizeMake(156, LARGE_CELL_HEIGHT);
}

-(NSInteger) numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return self.collectionView.hidden ? 0 : self.cards.count;
}

-(NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSArray* cards = self.cards[section];
    return cards.count;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(2, 2, 0, 2);
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    CardFilterSectionHeaderView* header = nil;
    if (kind == UICollectionElementKindSectionHeader)
    {
        header = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"sectionHeader" forIndexPath:indexPath];
        
        NSArray* cards = self.cards[indexPath.section];
        header.titleLabel.text = [NSString stringWithFormat:@"%@ (%ld)", self.sections[indexPath.section], (long)cards.count];
    }
    
    NSAssert(header != nil, @"no header?");
    return header;
}

@end
