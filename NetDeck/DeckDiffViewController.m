//
//  DeckDiffViewController.m
//  Net Deck
//
//  Created by Gereon Steffens on 13.07.14.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

#import "DeckDiffViewController.h"
#import "DeckDiffCell.h"

typedef NS_ENUM(NSInteger, DiffMode) {
    FullComparison, DiffOnly, Intersect, Overlap
};

@interface DeckDiffViewController ()
@property Deck* deck1;
@property Deck* deck2;

@property NSMutableArray* fullDiffSections;         // all cards from both decks
@property NSMutableArray* fullDiffRows;
@property NSMutableArray* smallDiffSections;        // differing cards
@property NSMutableArray* smallDiffRows;
@property NSMutableArray* overlapSections;          // cards that are in both decks
@property NSMutableArray* overlapRows;
@property NSMutableArray* intersectSections;        // cards that are in both decks, and total count is more than owned
@property NSMutableArray* intersectRows;

@property DiffMode diffMode;
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
    ddvc.preferredContentSize = CGSizeMake(768, 728);
}

- (id)initWithDecks:(Deck*)deck1 deck2:(Deck*)deck2
{
    self = [super initWithNibName:@"DeckDiffViewController" bundle:nil];
    if (self)
    {
        self.deck1 = deck1;
        self.deck2 = deck2;
        self.diffMode = DiffOnly;
        self.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    return self;
}

-(void) dealloc
{
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
}

-(void) viewDidLoad
{
    [super viewDidLoad];
    
    self.titleLabel.text = l10n(@"Deck Comparison");
    
    [self.closeButton setTitle:l10n(@"Done") forState:UIControlStateNormal];
    [self.reverseButton setTitle:l10n(@"Reverse") forState:UIControlStateNormal];
    
    self.diffModeControl.selectedSegmentIndex = DiffOnly;
    [self.diffModeControl setTitle:l10n(@"Full") forSegmentAtIndex:FullComparison];
    [self.diffModeControl setTitle:l10n(@"Diff") forSegmentAtIndex:DiffOnly];
    [self.diffModeControl setTitle:l10n(@"Intersect") forSegmentAtIndex:Intersect];
    [self.diffModeControl setTitle:l10n(@"Overlap") forSegmentAtIndex:Overlap];
    self.diffModeControl.apportionsSegmentWidthsByContent = YES;
    [self.diffModeControl sizeToFit];
    
    UIView* tableFoot = [[UIView alloc] initWithFrame:CGRectZero];
    [self.tableView setTableFooterView:tableFoot];
    [self.tableView registerNib:[UINib nibWithNibName:@"DeckDiffCell" bundle:nil] forCellReuseIdentifier:@"diffCell"];
    self.tableView.rowHeight = 44;
    
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
    TableData* data1 = [self.deck1 dataForTableView:NRDeckSortType];
    TableData* data2 = [self.deck2 dataForTableView:NRDeckSortType];
    
    // find union of card types used in both decks
    NSMutableSet* typesInDecks = [NSMutableSet setWithArray:data1.sections];
    [typesInDecks addObjectsFromArray:data2.sections];
    
    self.fullDiffSections = [NSMutableArray array];
    self.intersectSections = [NSMutableArray array];
    self.overlapSections = [NSMutableArray array];
    
    // all possible types for this role
    NSMutableArray* allTypes = [[CardType typesForRole:self.deck1.role] mutableCopy];
    // overwrite None/Any entry with "identity"
    allTypes[0] = [CardType name:NRCardTypeIdentity];
    
    // remove "ICE" / "Program"
    [allTypes removeLastObject];
    
    NSMutableArray* additionalTypes = [NSMutableArray array];
    // find every type that is not already in allTypes - i.e. the ice subtypes
    for (NSString* t in typesInDecks)
    {
        if (![allTypes containsObject:t])
        {
            [additionalTypes addObject:t];
        }
    }
    
    // sort iceTypes and append to allTypes
    [additionalTypes sortUsingComparator:^NSComparisonResult(NSString* t1, NSString* t2) {
        return [t1 compare:t2];
    }];
    [allTypes addObjectsFromArray:additionalTypes];

    for (NSString* type in allTypes)
    {
        if ([typesInDecks containsObject:type])
        {
            [self.fullDiffSections addObject:type];
            [self.intersectSections addObject:type];
            [self.overlapSections addObject:type];
        }
    }
    
    // create arrays for each section
    self.fullDiffRows = [NSMutableArray array];
    self.intersectRows = [NSMutableArray array];
    self.overlapRows = [NSMutableArray array];
    for (int i=0; i<self.fullDiffSections.count; ++i)
    {
        [self.fullDiffRows addObject:[NSMutableArray array]];
        [self.intersectRows addObject:[NSMutableArray array]];
        [self.overlapRows addObject:[NSMutableArray array]];
    }
    
    // for each type, find cards in each deck
    for (int i=0; i<self.fullDiffSections.count; ++i)
    {
        NSString* type = self.fullDiffSections[i];
        int idx1 = [self findValues:data1 forSection:type];
        int idx2 = [self findValues:data2 forSection:type];
        
        NSMutableDictionary* cards = [NSMutableDictionary dictionary];
        
        // for each card in deck1, create a CardDiff object
        if (idx1 != -1)
        {
            for (CardCounter* cc in data1.values[idx1])
            {
                if (cc.isNull)
                {
                    continue;
                }
                
                CardDiff* cd = [CardDiff new];
                cd.card = cc.card;
                cd.count1 = cc.count;
                
                NSUInteger count2 = 0;
                if (idx2 != -1)
                {
                    for (CardCounter* cc2 in data2.values[idx2])
                    {
                        if (cc2.isNull)
                        {
                            continue;
                        }
                        
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
                if (cc.isNull)
                {
                    continue;
                }
                
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
        
        // sort diffs by card name
        NSArray* arr = [cards.allValues sortedArrayUsingComparator:^NSComparisonResult(CardDiff* cd1, CardDiff* cd2) {
            return [cd1.card.name compare:cd2.card.name];
        }];
        [self.fullDiffRows[i] addObjectsFromArray:arr];
        
        // fill intersection and overlap - card is in both decks, and the total count is more than we own (for intersect)
        for (CardDiff* cd in self.fullDiffRows[i])
        {
            if (cd.count1 > 0 && cd.count2 > 0)
            {
                [self.overlapRows[i] addObject:cd];
                
                if (cd.count1+cd.count2 > cd.card.owned)
                {
                    [self.intersectRows[i] addObject:cd];
                }
            }
        }
    }
    
    NSAssert(self.intersectSections.count == self.intersectRows.count, @"count mismatch");
    NSAssert(self.overlapSections.count == self.overlapRows.count, @"count mismatch");
    
    // remove empty intersecion sections
    for (long i=self.intersectRows.count-1; i >= 0; --i)
    {
        NSArray* arr = self.intersectRows[i];
        
        if (arr.count == 0)
        {
            [self.intersectSections removeObjectAtIndex:i];
            [self.intersectRows removeObjectAtIndex:i];
        }
    }
    NSAssert(self.intersectSections.count == self.intersectRows.count, @"count mismatch");

    // remove empty overlap sections
    for (long i=self.overlapRows.count-1; i >= 0; --i)
    {
        NSArray* arr = self.overlapRows[i];
        
        if (arr.count == 0)
        {
            [self.overlapSections removeObjectAtIndex:i];
            [self.overlapRows removeObjectAtIndex:i];
        }
    }
    NSAssert(self.overlapSections.count == self.overlapRows.count, @"count mismatch");
    
    // from the full diff, create the (potentially) smaller diff-only arrays
    self.smallDiffRows = [NSMutableArray array];
    for (int i=0; i<self.fullDiffRows.count; ++i)
    {
        NSMutableArray* arr = [NSMutableArray array];
        [self.smallDiffRows addObject:arr];
        
        NSArray* diff = self.fullDiffRows[i];
        for (int j=0; j<diff.count; ++j)
        {
            CardDiff* cd = diff[j];
            if (cd.count1 != cd.count2)
            {
                [arr addObject:cd];
            }
        }
    }
    NSAssert(self.smallDiffRows.count == self.fullDiffRows.count, @"count mismatch");
    
    self.smallDiffSections = [NSMutableArray array];
    for (long i=self.smallDiffRows.count-1; i >= 0; --i)
    {
        NSArray* arr = self.smallDiffRows[i];
        if (arr.count > 0)
        {
            NSString* section = self.fullDiffSections[i];
            [self.smallDiffSections insertObject:section atIndex:0];
        }
        else
        {
            [self.smallDiffRows removeObjectAtIndex:i];
        }
    }
    
    NSAssert(self.smallDiffRows.count == self.smallDiffSections.count, @"count mismatch");
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

#pragma mark buttons

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

-(void) diffMode:(UISegmentedControl*)sender
{
    self.diffMode = sender.selectedSegmentIndex;
    
    [self.tableView reloadData];
}

#pragma mark table view

-(NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (self.diffMode)
    {
        case FullComparison:
            return self.fullDiffSections[section];
        case DiffOnly:
            return self.smallDiffSections[section];
        case Intersect:
            return self.intersectSections[section];
        case Overlap:
            return self.overlapSections[section];
    }
}

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    switch (self.diffMode)
    {
        case FullComparison:
            return self.fullDiffSections.count;
        case DiffOnly:
            return self.smallDiffSections.count;
        case Intersect:
            return self.intersectSections.count;
        case Overlap:
            return self.overlapSections.count;
    }
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray* arr;
    
    switch (self.diffMode)
    {
        case FullComparison:
            arr = self.fullDiffRows[section];
            break;
        case DiffOnly:
            arr = self.smallDiffRows[section];
            break;
        case Intersect:
            arr = self.intersectRows[section];
            break;
        case Overlap:
            arr = self.overlapRows[section];
            break;
    }
    
    return arr.count;
}

-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DeckDiffCell* cell = [tableView dequeueReusableCellWithIdentifier:@"diffCell" forIndexPath:indexPath];

    NSArray* arr;
    
    switch (self.diffMode)
    {
        case FullComparison:
            arr = self.fullDiffRows[indexPath.section];
            break;
        case DiffOnly:
            arr = self.smallDiffRows[indexPath.section];
            break;
        case Intersect:
            arr = self.intersectRows[indexPath.section];
            break;
        case Overlap:
            arr = self.overlapRows[indexPath.section];
            break;
    }
    CardDiff* cd = arr[indexPath.row];
    
    cell.vc = self;
    cell.card1 = nil;
    cell.card2 = nil;
    
    cell.deck1Card.textColor = [UIColor blackColor];
    cell.deck2Card.textColor = [UIColor blackColor];
    
    if (cd.count1 > 0)
    {
        cell.deck1Card.text = [NSString stringWithFormat:@"%lu× %@", (unsigned long)cd.count1, cd.card.name];
        cell.card1 = cd.card;
        if (cd.count1 > cd.card.owned)
        {
            cell.deck1Card.textColor = [UIColor redColor];
        }
    }
    else
    {
        cell.deck1Card.text = @"";
    }
    
    if (cd.count2 > 0)
    {
        cell.deck2Card.text = [NSString stringWithFormat:@"%lu× %@", (unsigned long)cd.count2, cd.card.name];
        cell.card2 = cd.card;
        if (cd.count2 > cd.card.owned)
        {
            cell.deck2Card.textColor = [UIColor redColor];
        }
    }
    else
    {
        cell.deck2Card.text = @"";
    }
    
    if (self.diffMode == Intersect)
    {
        NSInteger owned = cd.card.owned;
        NSInteger diff = cd.count1 + cd.count2 - owned;

        cell.diff.text = [NSString stringWithFormat:@"%ld", (long)diff];
        cell.diff.textColor = [UIColor blackColor];
    }
    else if (self.diffMode == Overlap)
    {
        NSInteger diff = MIN(cd.count1, cd.count2);
        cell.diff.text = [NSString stringWithFormat:@"%ld", (long)diff];
        cell.diff.textColor = [UIColor blackColor];
    }
    else
    {
        NSInteger diff = cd.count2 - cd.count1;
        if (diff != 0)
        {
            cell.diff.text = [NSString stringWithFormat:@"%+ld", (long)diff];
            cell.diff.textColor = diff > 0 ? UIColorFromRGB(0x177a00) : UIColorFromRGB(0xdb0c0c);
        }
        else
        {
            cell.diff.text = @"";
        }
    }
    
    return cell;
}

@end
