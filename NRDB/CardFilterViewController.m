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
#import "Notifications.h"
#import "CardImageViewPopover.h"

@interface CardFilterViewController ()

@property NRRole role;
@property SubstitutableNavigationController* snc;
@property (strong) CardList* cardList;
@property (strong) NSArray* cards;
@property (strong) NSArray* sections;
@end

@implementation CardFilterViewController

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
    [nc addObserver:self selector:@selector(willShowKeyboard:) name:UIKeyboardWillShowNotification object:nil];
    [nc addObserver:self selector:@selector(willHideKeyboard:) name:UIKeyboardWillHideNotification object:nil];
    [nc addObserver:self selector:@selector(addTopCard:) name:ADD_TOP_CARD object:nil];
    [nc addObserver:self selector:@selector(deckChanged:) name:DECK_CHANGED object:nil];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
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
