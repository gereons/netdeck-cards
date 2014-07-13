//
//  DeckDiffViewController.m
//  NRDB
//
//  Created by Gereon Steffens on 13.07.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "DeckDiffViewController.h"
#import "Deck.h"
#import "CardType.h"
#import "CardCounter.h"
#import "DeckDiffCell.h"

@interface DeckDiffViewController ()
@property Deck* deck1;
@property Deck* deck2;
@property NSMutableArray* diffRows;
@property NSMutableArray* diffSections;
@end

@interface CardDiff: NSObject
@property Card* card;
@property NSUInteger count1;
@property NSUInteger count2;
@end
@implementation CardDiff
@end

@implementation DeckDiffViewController

+(void) showForDecks:(Deck*)deck1 deck2:(Deck*)deck2 inViewController:(UIViewController*)vc
{
    DeckDiffViewController* ddvc = [[DeckDiffViewController alloc] initWithDecks:deck1 deck2:deck2];
    
    [vc presentViewController:ddvc animated:NO completion:nil];
}

- (id)initWithDecks:(Deck*)deck1 deck2:(Deck*)deck2
{
    TF_CHECKPOINT(@"deck diff");
    
    self = [super initWithNibName:@"DeckDiffViewController" bundle:nil];
    if (self)
    {
        self.deck1 = deck1;
        self.deck2 = deck2;
        
        self.modalPresentationStyle = UIModalPresentationFullScreen;
    }
    return self;
}

-(void) viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"DeckDiffCell" bundle:nil] forCellReuseIdentifier:@"diffCell"];
    [self setup];
}

-(void) setup
{
    [self calcDiff];
    self.deck1Name.text = self.deck1.name;
    self.deck2Name.text = self.deck2.name;
}

-(void) calcDiff
{
    TableData* data1 = [self.deck1 dataForTableView];
    TableData* data2 = [self.deck2 dataForTableView];
    
    // find union of card types used in both decks
    NSMutableSet* types = [NSMutableSet setWithArray:data1.sections];
    [types addObjectsFromArray:data2.sections];
    
    self.diffSections = [NSMutableArray array];
    NSMutableArray* availableTypes = [[CardType typesForRole:self.deck1.role] mutableCopy];
    availableTypes[0] = [CardType name:NRCardTypeIdentity];
    for (NSString* type in availableTypes)
    {
        if ([types containsObject:type])
        {
            [self.diffSections addObject:type];
        }
    }
    
    // create arrays for each section
    self.diffRows = [NSMutableArray array];
    for (int i=0; i<self.diffSections.count; ++i)
    {
        [self.diffRows addObject:[NSMutableArray array]];
    }
    
    // for each type, find cards in each deck
    for (int i=0; i<self.diffSections.count; ++i)
    {
        NSString* type = self.diffSections[i];
        int idx1 = [self findValues:data1 forSection:type];
        int idx2 = [self findValues:data2 forSection:type];
        
        NSMutableDictionary* cards = [NSMutableDictionary dictionary];
        
        // for each card in deck1, create a CardDiff object
        if (idx1 != -1)
        {
            for (CardCounter* cc in data1.values[idx1])
            {
                CardDiff* cd = [CardDiff new];
                cd.card = cc.card;
                cd.count1 = cc.count;
                
                NSUInteger count2 = 0;
                if (idx2 != -1)
                {
                    for (CardCounter* cc2 in data2.values[idx2])
                    {
                        if ([cc2.card isEqual:cc.card])
                        {
                            count2 = cc2.count;
                            break;
                        }
                    }
                }
                cd.count2 = count2;
                
                [cards setObject:cd forKey:cd.card.code];
            }
        }
        
        // for each card in deck2 that is not already in `cards´, create a CardDiff object
        if (idx2 != -1)
        {
            for (CardCounter* cc in data2.values[idx2])
            {
                CardDiff* cd = [cards objectForKey:cc.card.code];
                if (cd)
                {
                    continue;
                }
                cd = [CardDiff new];
                cd.card = cc.card;
                cd.count1 = 0; // by definition
                cd.count2 = cc.count;
                [cards setObject:cd forKey:cd.card.code];
            }
        }
        
        [self.diffRows[i] addObjectsFromArray:cards.allValues];
    }
}

-(int) findValues:(TableData*)data forSection:(NSString*)type
{
    for (int i=0; i<data.sections.count; ++i)
    {
        if ([data.sections[i] isEqualToString:type])
        {
            return i;
        }
    }
    return -1;
}

- (void) close:(id)sender
{
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void) reverse:(id)sender
{
    Deck* tmp = self.deck1;
    self.deck1 = self.deck2;
    self.deck2 = tmp;
    
    [self setup];
    [self.tableView reloadData];
}

#pragma mark table view

-(NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.diffSections[section];
}

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.diffSections.count;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray* arr = self.diffRows[section];
    return arr.count;
}

-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DeckDiffCell* cell = [tableView dequeueReusableCellWithIdentifier:@"diffCell" forIndexPath:indexPath];

    NSArray* arr = self.diffRows[indexPath.section];
    CardDiff* cd = arr[indexPath.row];
    
    if (cd.count1 > 0)
    {
        cell.deck1Card.text = [NSString stringWithFormat:@"%lu× %@", (unsigned long)cd.count1, cd.card.name];
    }
    else
    {
        cell.deck1Card.text = @"";
    }
    
    if (cd.count2 > 0)
    {
        cell.deck2Card.text = [NSString stringWithFormat:@"%lu× %@", (unsigned long)cd.count2, cd.card.name];
    }
    else
    {
        cell.deck2Card.text = @"";
    }
    
    NSInteger diff = cd.count2 - cd.count1;
    if (diff != 0)
    {
        cell.diff.text = [NSString stringWithFormat:@"%+ld", (long)diff];
    }
    else
    {
        cell.diff.text = @"";
    }
    
    return cell;
}

@end
