//
//  FilteredCardViewController.m
//  NRDB
//
//  Created by Gereon Steffens on 29.11.13.
//  Copyright (c) 2013 Gereon Steffens. All rights reserved.
//

#import "FilteredCardViewController.h"
#import "DetailViewManager.h"
#import "DeckListViewController.h"
#import "CardFilterHeaderView.h"
#import "CardImageViewPopover.h"
#import "NRNavigationController.h"

#import "Card.h"
#import "CardList.h"
#import "CGRectUtils.h"
#import "Notifications.h"
#import "SettingsKeys.h"

@interface FilteredCardViewController ()

@property (strong) CardList* cardList;
@property (strong) NSArray* cards;
@property (strong) NSArray* sections;
@property CardFilterHeaderView* filterView;
@property CGFloat normalTableHeight;

@property (strong) SubstitutableNavigationController* snc;

@end

@implementation FilteredCardViewController

- (id) initWithRole:(NRRole)role
{
    if ((self = [super init]))
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.filterView = [[[NSBundle mainBundle] loadNibNamed:@"CardFilterHeaderView" owner:self options:nil] objectAtIndex:0];
    self.filterView.role = self.role;
    
    self.filterViewContainer.backgroundColor = [UIColor lightGrayColor];
    [self.filterViewContainer addSubview:self.filterView];
    
    self.cardList = [[CardList alloc] initForRole:self.role];
    [self initCards];
    
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(updateFilter:) name:UPDATE_FILTER object:nil];
    [nc addObserver:self selector:@selector(willShowKeyboard:) name:UIKeyboardWillShowNotification object:nil];
    [nc addObserver:self selector:@selector(willHideKeyboard:) name:UIKeyboardWillHideNotification object:nil];
    [nc addObserver:self selector:@selector(addTopCard:) name:ADD_TOP_CARD object:nil];
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
    topItem.title = @"Filter";
    topItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Clear" style:UIBarButtonItemStylePlain target:self action:@selector(clearFilters:)];
}

#pragma mark keyboard show/hide

#define KEYBOARD_HEIGHT_OFFSET  225

-(void) willShowKeyboard:(NSNotification*)sender
{
    if (!self.filterView.searchField.isFirstResponder)
    {
        return;
    }
    
    TF_CHECKPOINT(@"filter text entry");
    self.normalTableHeight = self.tableView.frame.size.height;
    
    CGRect kbRect = [[sender.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    float kbHeight = kbRect.size.width; // kbRect is screen/portrait coords
    float tableHeight = 768 - kbHeight - 44 - 85;
    
    float animDuration = [[sender.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    [UIView animateWithDuration:animDuration
                     animations:^{
                         self.tableView.frame = CGRectAddY(self.tableView.frame, -KEYBOARD_HEIGHT_OFFSET);
                     }
                     completion:^(BOOL finished){
                         self.tableView.frame = CGRectSetHeight(self.tableView.frame, tableHeight);
                         self.filterViewContainer.frame = CGRectAddHeight(self.filterViewContainer.frame, -KEYBOARD_HEIGHT_OFFSET);
                     }];
}

-(void) willHideKeyboard:(NSNotification*)sender
{
    if (!self.filterView.searchField.isFirstResponder)
    {
        return;
    }
    
    float animDuration = [[sender.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    
    [UIView animateWithDuration:animDuration
                     animations:^{
                         self.tableView.frame = CGRectAddY(self.tableView.frame, KEYBOARD_HEIGHT_OFFSET);
                     }
                     completion:^(BOOL finished) {
                         self.tableView.frame = CGRectSetHeight(self.tableView.frame, self.normalTableHeight);
                     }];
    self.filterViewContainer.frame = CGRectAddHeight(self.filterViewContainer.frame, KEYBOARD_HEIGHT_OFFSET);
}

#pragma mark cards / filters

- (void) initCards
{
    TableData* data = [self.cardList dataForTableView];
    self.cards = data.values;
    self.sections = data.sections;
}

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
    
    [self initCards];
    [self.tableView reloadData];
}

-(void) clearFilters:(id)sender
{
    [self.filterView clearFilters];
    [self.cardList clearFilters];
    
    [self initCards];
    [self.tableView reloadData];
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
        }
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
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        
        UIButton* button = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        button.frame = CGRectMake(280, 5, 30, 30);
        [cell.contentView addSubview:button];
        
        [button addTarget:self action:@selector(showImage:) forControlEvents:UIControlEventTouchUpInside];
    }

    cell.textLabel.font = [UIFont systemFontOfSize:17];
    NSArray* cards = self.cards[indexPath.section];
    Card *card = cards[indexPath.row];
    
    cell.textLabel.text = card.name;
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return NO;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray* cards = self.cards[indexPath.section];
    Card *card = cards[indexPath.row];
    
    [self.deckListViewController addCard:card];
}

#pragma mark card popup

-(void) showImage:(UIButton*)sender
{
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    
    NSArray* cards = self.cards[indexPath.section];
    Card *card = cards[indexPath.row];
    
    CGRect rect = [self.tableView rectForRowAtIndexPath:indexPath];
    // rect.origin.x = sender.frame.origin.x;
    [CardImageViewPopover showForCard:card fromRect:rect inView:self.tableView];
}
@end
