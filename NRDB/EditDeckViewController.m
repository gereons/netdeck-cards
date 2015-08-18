//
//  EditDeckViewController.m
//  NRDB
//
//  Created by Gereon Steffens on 09.08.15.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

#import "EditDeckViewController.h"
#import "ListCardsViewController.h"
#import "CardImageViewController.h"
#import "IphoneIdentityViewController.h"
#import "Deck.h"
#import "TableData.h"
#import "ImageCache.h"
#import "Faction.h"
#import "CardType.h"
#import "EditDeckCell.h"

@interface EditDeckViewController ()

@property NSArray* cards;
@property NSArray* sections;

@end

@implementation EditDeckViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[ImageCache hexTile]];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.backgroundColor = [UIColor clearColor];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"EditDeckCell" bundle:nil] forCellReuseIdentifier:@"cardCell"];
    
    self.title = self.deck.name;
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self refreshDeck:@(YES)];
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    // right buttons
    UIBarButtonItem* exportButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"702-share"] style:UIBarButtonItemStylePlain target:self action:@selector(exportDeck:)];
    UIBarButtonItem* addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addCard:)];
    
    self.navigationController.navigationBar.topItem.rightBarButtonItems = @[ addButton, exportButton];
}

-(void) exportDeck:(id)sender
{
    NSLog(@"stub - export deck");
}

-(void) addCard:(id)sender
{
    ListCardsViewController* listCards = [[ListCardsViewController alloc] initWithNibName:@"ListCardsViewController" bundle:nil];
    listCards.deck = self.deck;
    [self.navigationController pushViewController:listCards animated:YES];
}

-(void) refreshDeck:(NSNumber*)reload
{
    TableData* data = [self.deck dataForTableView:NRDeckSortType];
    self.cards = data.values;
    self.sections = data.sections;
    
    if (reload.boolValue)
    {
        [self.tableView reloadData];
    }
    
    NSMutableString* footer = [NSMutableString string];
    [footer appendString:[NSString stringWithFormat:@"%d %@", self.deck.size, self.deck.size == 1 ? l10n(@"Card") : l10n(@"Cards")]];
    if (self.deck.identity && !self.deck.isDraft)
    {
        [footer appendString:[NSString stringWithFormat:@" · %d/%d %@", self.deck.influence, self.deck.identity.influenceLimit, l10n(@"Influence")]];
    }
    else
    {
        [footer appendString:[NSString stringWithFormat:@" · %d %@", self.deck.influence, l10n(@"Influence")]];
    }
    
    if (self.deck.role == NRRoleCorp)
    {
        [footer appendString:[NSString stringWithFormat:@" · %d %@", self.deck.agendaPoints, l10n(@"AP")]];
    }
    
    [footer appendString:@"\n"];
    
    NSArray* reasons = [self.deck checkValidity];
    if (reasons.count > 0)
    {
        [footer appendString:reasons[0]];
    }

    self.statusLabel.text = footer;
    self.statusLabel.textColor = reasons.count == 0 ? [UIColor darkGrayColor] : [UIColor redColor];
}

-(void) changeCount:(UIStepper*)stepper
{
    NSInteger section = stepper.tag / 1000;
    NSInteger row = stepper.tag - (section*1000);
    
    NSArray* arr = self.cards[section];
    CardCounter* cc = arr[row];
    
    NSInteger copies = stepper.value;
    NSInteger diff = ABS(cc.count - copies);
    if (copies < cc.count)
    {
        [self.deck addCard:cc.card copies:-diff];
    }
    else
    {
        [self.deck addCard:cc.card copies:diff];
    }
    
    [self refreshDeck:@(YES)];
}

-(void) selectIdentity:(id)sender
{
    IphoneIdentityViewController* idvc = [[IphoneIdentityViewController alloc] initWithNibName:@"IphoneIdentityViewController" bundle:nil];
    idvc.role = self.deck.role;
    idvc.deck = self.deck;  
    [self.navigationController pushViewController:idvc animated:YES];
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
    static NSString* cellIdentifier = @"cardCell";
    EditDeckCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    cell.stepper.tag = indexPath.section * 1000 + indexPath.row;
    [cell.stepper addTarget:self action:@selector(changeCount:) forControlEvents:UIControlEventValueChanged];

    CardCounter* cc = [self.cards objectAtIndexPath:indexPath];
    
    if (ISNULL(cc))
    {
        // empty identity
        cell.nameLabel.textColor = [UIColor blackColor];
        cell.nameLabel.text = @"";
        cell.typeLabel.text = @"";
        cell.stepper.hidden = YES;
        cell.idButton.hidden = NO;
        return cell;
    }
    
    Card* card = cc.card;
    cell.stepper.minimumValue = 0;
    cell.stepper.maximumValue = card.maxPerDeck;
    cell.stepper.value = cc.count;
    cell.stepper.hidden = card.type == NRCardTypeIdentity;
    cell.idButton.hidden = card.type != NRCardTypeIdentity;
    
    [cell.idButton addTarget:self action:@selector(selectIdentity:) forControlEvents:UIControlEventTouchUpInside];
    
    if (card.unique)
    {
        cell.nameLabel.text = [NSString stringWithFormat:@"%lu× %@ •", (unsigned long)cc.count, card.name];
    }
    else
    {
        cell.nameLabel.text = [NSString stringWithFormat:@"%lu× %@", (unsigned long)cc.count, card.name];
    }
    if (card.type == NRCardTypeIdentity)
    {
        cell.nameLabel.text = card.name;
        cell.stepper.hidden = YES;
    }
    
    cell.nameLabel.textColor = [UIColor blackColor];
    if (card.isCore && !self.deck.isDraft)
    {
        if (card.owned < cc.count)
        {
            cell.nameLabel.textColor = [UIColor redColor];
        }
    }
    
    NSString* factionName = [Faction name:card.faction];
    NSString* typeName = [CardType name:card.type];
    
    NSString* subtype = card.subtype;
    if (subtype)
    {
        cell.typeLabel.text = [NSString stringWithFormat:@"%@ · %@: %@", factionName, typeName, card.subtype];
    }
    else
    {
        cell.typeLabel.text = [NSString stringWithFormat:@"%@ · %@", factionName, typeName];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CardCounter* cc = [self.cards objectAtIndexPath:indexPath];
    
    if (ISNULL(cc))
    {
        return;
    }
    
    CardImageViewController* img = [[CardImageViewController alloc] initWithNibName:@"CardImageViewController" bundle:nil];
    img.deck = self.deck;
    img.selectedCard = cc.card;
    
    [self.navigationController pushViewController:img animated:YES];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        CardCounter* cc = [self.cards objectAtIndexPath:indexPath];
        
        if (!ISNULL(cc))
        {
            [self.deck addCard:cc.card copies:0];
        }
        
        [self performSelector:@selector(refreshDeck:) withObject:@(YES) afterDelay:0.001];
    }
}

@end
