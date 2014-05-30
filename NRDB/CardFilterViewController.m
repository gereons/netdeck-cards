//
//  CardFilterViewController.m
//  NRDB
//
//  Created by Gereon Steffens on 30.05.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "CardFilterViewController.h"
#import "DeckListViewController.h"
#import "Deck.h"
#import "CardCounter.h"
#import "CardList.h"
#import "CardData.h"
#import "CardType.h"
#import "CardSets.h"
#import "Faction.h"
#import "CardFilterPopover.h"
#import "Notifications.h"
#import "CardImageViewPopover.h"

@interface CardFilterViewController ()

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

@property NSMutableDictionary* selectedValues;

@end

@implementation CardFilterViewController

enum { TYPE_BUTTON, FACTION_BUTTON, SET_BUTTON, SUBTYPE_BUTTON };
static NSArray* scopes;

+(void)initialize
{
    scopes = @[ @"all text", @"card name", @"card text" ];
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
    if ((self = [self initWithRole:role]))
    {
        self.deckListViewController.deck = deck;
        self.deckListViewController.deckChanged = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationController.navigationBar.backgroundColor = [UIColor whiteColor];
    
    self.cardList = [[CardList alloc] initForRole:self.role];
    [self initCards];
    
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(updateFilter:) name:UPDATE_FILTER object:nil];
    // [nc addObserver:self selector:@selector(willShowKeyboard:) name:UIKeyboardWillShowNotification object:nil];
    // [nc addObserver:self selector:@selector(willHideKeyboard:) name:UIKeyboardWillHideNotification object:nil];
    [nc addObserver:self selector:@selector(addTopCard:) name:ADD_TOP_CARD object:nil];
    [nc addObserver:self selector:@selector(deckChanged:) name:DECK_CHANGED object:nil];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    self.moreLessButton.enabled = NO;
    self.viewMode.enabled = NO;
    
    [self initFilters];
}

-(void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    
    UINavigationItem* topItem = self.navigationController.navigationBar.topItem;
    topItem.title = l10n(@"Filter");
    topItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:l10n(@"Clear") style:UIBarButtonItemStylePlain target:self action:@selector(clearFilters:)];
}

- (void) initCards
{
    TableData* data = [self.cardList dataForTableView];
    self.cards = data.values;
    self.sections = data.sections;
}

-(void) deckChanged:(id)sender
{
    [self.tableView reloadData];
}

-(void) initFilters
{
    self.role = self.role;
    self.typeButton.tag = TYPE_BUTTON;
    self.setButton.tag = SET_BUTTON;
    self.factionButton.tag = FACTION_BUTTON;
    self.subtypeButton.tag = SUBTYPE_BUTTON;
    
    self.costSlider.maximumValue = 1+[CardData maxCost];
    self.muSlider.maximumValue = 1+[CardData maxMU];
    self.strengthSlider.maximumValue = 1+[CardData maxStrength];
    self.influenceSlider.maximumValue = 1+[CardData maxInfluence];
    self.apSlider.maximumValue = [CardData maxAgendaPoints]; // NB: no +1 here!
    
    [self.costSlider setThumbImage:[UIImage imageNamed:@"credit_slider"] forState:UIControlStateNormal];
    [self.muSlider setThumbImage:[UIImage imageNamed:@"mem_slider"] forState:UIControlStateNormal];
    [self.strengthSlider setThumbImage:[UIImage imageNamed:@"strength_slider"] forState:UIControlStateNormal];
    [self.influenceSlider setThumbImage:[UIImage imageNamed:@"influence_slider"] forState:UIControlStateNormal];
    [self.apSlider setThumbImage:[UIImage imageNamed:@"point_slider"] forState:UIControlStateNormal];
    
    self.searchLabel.text = l10n(@"Search in:");
    self.searchField.placeholder = l10n(@"Search Cards");
    [self.searchScope setTitle:l10n(@"All") forSegmentAtIndex:0];
    
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

#pragma mark clear filters

-(void) clearFilters:(id)sender
{
    [self.cardList clearFilters];
    
    [self initCards];
    [self.tableView reloadData];
}

-(void) clearFilters
{
    self.sendNotifications = NO;
    
    self.scope = NRSearchName;
    self.searchScope.selectedSegmentIndex = self.scope;
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
    
    [self resetButton:TYPE_BUTTON];
    [self resetButton:SET_BUTTON];
    [self resetButton:FACTION_BUTTON];
    [self resetButton:SUBTYPE_BUTTON];
    self.selectedType = kANY;
    self.selectedTypes = nil;
    
    self.selectedValues = [NSMutableDictionary dictionary];
    
    self.sendNotifications = YES;
}

-(void) addTopCard:(id)sender
{
    if (self.cards.count > 0)
    {
        NSArray* arr = self.cards[0];
        if (arr.count > 0)
        {
            Card* card = arr[0];
            [self.deckListViewController addCard:card];
            [self.tableView reloadData];
        }
    }
}
#pragma mark button callbacks

-(void) moreLessClicked:(id)sender
{
    
}

-(void) viewModeChanged:(id)sender
{
    
}

-(void) typeClicked:(UIButton*)sender
{
    TF_CHECKPOINT(@"filter type");
    TableData* data = [[TableData alloc] initWithValues:[CardType typesForRole:self.role]];
    id selected = [self.selectedValues objectForKey:@(TYPE_BUTTON)];
    
    [CardFilterPopover showFromButton:sender inView:self entries:data type:@"Type" selected:selected];
}

-(void) setClicked:(UIButton*)sender
{
    TF_CHECKPOINT(@"filter set");
    id selected = [self.selectedValues objectForKey:@(SET_BUTTON)];
    [CardFilterPopover showFromButton:sender inView:self entries:[CardSets allSetsForTableview] type:@"Set" selected:selected];
}

-(void) subtypeClicked:(UIButton*)sender
{
    TF_CHECKPOINT(@"filter subtype");
    TableData* data;
    if (self.selectedTypes)
    {
        data = [[TableData alloc] initWithValues:[CardType subtypesForRole:self.role andTypes:self.selectedTypes]];
    }
    else
    {
        data = [[TableData alloc] initWithValues:[CardType subtypesForRole:self.role andType:self.selectedType]];
    }
    id selected = [self.selectedValues objectForKey:@(SUBTYPE_BUTTON)];
    
    [CardFilterPopover showFromButton:sender inView:self entries:data type:@"Subtype" selected:selected];
}

-(void) factionClicked:(UIButton*)sender
{
    TF_CHECKPOINT(@"filter faction");
    TableData* data = [[TableData alloc] initWithValues:[Faction factionsForRole:self.role]];
    id selected = [self.selectedValues objectForKey:@(FACTION_BUTTON)];
    
    [CardFilterPopover showFromButton:sender inView:self entries:data type:@"Faction" selected:selected];
}

-(void) filterCallback:(UIButton *)button value:(NSObject *)object
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
    [self postNotification:[pfx lowercaseString] value:kANY];
    [btn setTitle:[NSString stringWithFormat:@"%@: %@", l10n(pfx), l10n(kANY)] forState:UIControlStateNormal];
    
    NSAssert(btn != nil, @"no button");
}

#pragma mark slider callbacks

-(void) strengthValueChanged:(UISlider*)sender
{
    TF_CHECKPOINT(@"filter strength");
    int value = round(sender.value);
    // NSLog(@"str: %f %d", sender.value, value);
    sender.value = value--;
    self.strengthLabel.text = [NSString stringWithFormat:l10n(@"Strength: %@"), value == -1 ? l10n(@"All") : [@(value) stringValue]];
    [self postNotification:@"strength" value:@(value)];
}

-(void) muValueChanged:(UISlider*)sender
{
    TF_CHECKPOINT(@"filter mu");
    int value = round(sender.value);
    // NSLog(@"mu: %f %d", sender.value, value);
    sender.value = value--;
    self.muLabel.text = [NSString stringWithFormat:l10n(@"MU: %@"), value == -1 ? l10n(@"All") : [@(value) stringValue]];
    [self postNotification:@"mu" value:@(value)];
}

-(void) costValueChanged:(UISlider*)sender
{
    TF_CHECKPOINT(@"filter cost");
    int value = round(sender.value);
    // NSLog(@"cost: %f %d", sender.value, value);
    sender.value = value--;
    self.costLabel.text = [NSString stringWithFormat:l10n(@"Cost: %@"), value == -1 ? l10n(@"All") : [@(value) stringValue]];
    [self postNotification:@"card cost" value:@(value)];
}

-(void) influenceValueChanged:(UISlider*)sender
{
    TF_CHECKPOINT(@"filter influence");
    int value = round(sender.value);
    // NSLog(@"inf: %f %d", sender.value, value);
    sender.value = value--;
    self.influenceLabel.text = [NSString stringWithFormat:l10n(@"Influence: %@"), value == -1 ? l10n(@"All") : [@(value) stringValue]];
    [self postNotification:@"influence" value:@(value)];
}

-(void) apValueChanged:(UISlider*)sender
{
    TF_CHECKPOINT(@"filter ap");
    int value = round(sender.value);
    // NSLog(@"ap: %f %d", sender.value, value);
    if (value == 0)
    {
        value = -1;
    }
    sender.value = value;
    self.apLabel.text = [NSString stringWithFormat:l10n(@"AP: %@"), value == -1 ? l10n(@"All") : [@(value) stringValue]];
    [self postNotification:@"agendaPoints" value:@(value)];
}

#pragma mark text search

-(void) scopeValueChanged:(UISegmentedControl*)sender
{
    TF_CHECKPOINT(@"filter scope");
    self.scope = sender.selectedSegmentIndex;
    [self postNotification:scopes[self.scope] value:self.searchText];
}

-(BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if ([CardImageViewPopover dismiss])
    {
        return NO;
    }
    
    self.searchText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    // NSLog(@"search: %d %@", self.scope, self.searchText);
    
    [self postNotification:scopes[self.scope] value:self.searchText];
    
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    if ([CardImageViewPopover dismiss])
    {
        return NO;
    }
    
    self.searchText = @"";
    
    [self postNotification:scopes[self.scope] value:self.searchText];
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
        [[NSNotificationCenter defaultCenter] postNotificationName:ADD_TOP_CARD object:self];
    }
    else
    {
        [textField resignFirstResponder];
    }
    return NO;
    
}

#pragma mark notification

-(void) updateFilter:(NSNotification*)notification
{
    // NSLog(@"update filter %@", notification.userInfo);
    
    NSString* type = [notification.userInfo objectForKey:@"type"];
    
    NSString* value;
    NSSet* values;
    NSNumber* num;
    NSObject* v = [notification.userInfo objectForKey:@"value"];
    if ([v isKindOfClass:[NSString class]])
    {
        value = (NSString*)v;
    }
    else if ([v isKindOfClass:[NSSet class]])
    {
        values = (NSSet*)v;
    }
    else if ([v isKindOfClass:[NSNumber class]])
    {
        num = (NSNumber*)v;
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
        [self.cardList filterByInfluence:[num intValue]];
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
    [self.tableView reloadData];
}

-(void) postNotification:(NSString*)type value:(id)value
{
    if (self.sendNotifications)
    {
        NSDictionary* userInfo = @{ @"type": type, @"value": value };
        [[NSNotificationCenter defaultCenter] postNotificationName:UPDATE_FILTER object:self userInfo:userInfo];
    }
}

#pragma mark - Table View

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 33;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 38;
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.sections[section];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray* cards = self.cards[section];
    return cards.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* cellIdentifier = @"cardCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
        
        UIButton* button = [UIButton buttonWithType:UIButtonTypeContactAdd];
        button.frame = CGRectMake(0, 0, 30, 30);
        cell.accessoryView = button;
        
        [cell.contentView addSubview:button];
        
        [button addTarget:self action:@selector(addCardToDeck:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    cell.textLabel.font = [UIFont systemFontOfSize:17];
    NSArray* cards = self.cards[indexPath.section];
    Card *card = cards[indexPath.row];
    
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
    if (indexPath.section > self.cards.count)
    {
        return;
    }
    
    NSArray* cards = self.cards[indexPath.section];
    Card *card = cards[indexPath.row];
    
    CGRect rect = [self.tableView rectForRowAtIndexPath:indexPath];
    [CardImageViewPopover showForCard:card fromRect:rect inView:self.tableView];
}

- (void) addCardToDeck:(UIButton*)sender
{
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    
    NSArray* cards = self.cards[indexPath.section];
    Card *card = cards[indexPath.row];
    
    UITextField* textField = self.searchField;
    if (textField.isFirstResponder && textField.text.length > 0)
    {
        [textField setSelectedTextRange:[textField textRangeFromPosition:textField.beginningOfDocument toPosition:textField.endOfDocument]];
    }
    
    [self.deckListViewController addCard:card];
    [self.tableView reloadData];
}

@end
