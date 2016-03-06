//
//  FilterViewController.m
//  Net Deck
//
//  Created by Gereon Steffens on 24.08.15.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

#import "FilterViewController.h"

@interface FilterViewController ()

@property NSArray* factionNames;
@property NSArray* typeNames;
@property BOOL dataDestinyAllowed;

@property NSArray* cards;
@property BOOL showPreviewTable;

@end

@implementation FilterViewController 

enum { TAG_FACTION, TAG_MINI_FACTION, TAG_TYPE };

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Filter";
    
    self.dataDestinyAllowed = [[NSUserDefaults standardUserDefaults] boolForKey:SettingsKeys.USE_DATA_DESTINY];
    self.factionLabel.text = l10n(@"Faction");
    self.typeLabel.text = l10n(@"Type");
    
    self.typeVerticalDistance.constant = 18;
    self.miniFactionControl.hidden = YES;
    self.miniFactionControl.tag = TAG_MINI_FACTION;
    self.miniFactionControl.delegate = self;
    [self.miniFactionControl selectAllSegments:self.dataDestinyAllowed];
    
    NSInteger factionLimit;
    if (self.role == NRRoleRunner)
    {
        self.factionNames = @[ [Faction name:NRFactionAnarch], [Faction name:NRFactionCriminal], [Faction name:NRFactionShaper], [Faction name:NRFactionNeutral]];
        self.typeNames = @[ [CardType name:NRCardTypeEvent], [CardType name:NRCardTypeHardware], [CardType name:NRCardTypeResource], [CardType name:NRCardTypeProgram] ];
        factionLimit = self.factionNames.count;
        
        if (self.dataDestinyAllowed)
        {
            self.factionNames = @[ [Faction name:NRFactionAnarch], [Faction name:NRFactionCriminal], [Faction name:NRFactionShaper], [Faction name:NRFactionNeutral],
                                   [Faction name:NRFactionAdam], [Faction name:NRFactionApex], [Faction name:NRFactionSunnyLebeau] ];
            
            self.miniFactionControl.hidden = NO;
            self.typeVerticalDistance.constant = 50;
        }
    }
    else
    {
        self.factionNames = @[ [Faction name:NRFactionHaasBioroid], [Faction name:NRFactionNBN], [Faction name:NRFactionJinteki], [Faction name:NRFactionWeyland], [Faction name:NRFactionNeutral]];
        factionLimit = self.factionNames.count;
        
        self.typeNames = @[ [CardType name:NRCardTypeAgenda], [CardType name:NRCardTypeAsset], [CardType name:NRCardTypeUpgrade], [CardType name:NRCardTypeOperation], [CardType name:NRCardTypeIce]];
    }
    
    self.factionControl.delegate = self;
    self.factionControl.tag = TAG_FACTION;
    [self.factionControl removeAllSegments];
    
    for (NSInteger i = 0; i<factionLimit; ++i)
    {
        [self.factionControl insertSegmentWithTitle:self.factionNames[i] atIndex:i animated:NO];
    }
    [self.factionControl selectAllSegments:YES];
    
    self.typeControl.delegate = self;
    self.typeControl.tag = TAG_TYPE;
    [self.typeControl removeAllSegments];
    
    for (NSInteger i = 0; i<self.typeNames.count; ++i)
    {
        [self.typeControl insertSegmentWithTitle:self.typeNames[i] atIndex:i animated:NO];
    }
    [self.typeControl selectAllSegments:YES];
    
    self.costSlider.maximumValue = 1+(self.role == NRRoleRunner ? [CardManager maxRunnerCost] : [CardManager maxCorpCost]);
    self.muApSlider.maximumValue = self.role == NRRoleRunner ? 1+[CardManager maxMU] : 1+[CardManager maxAgendaPoints];
    self.strengthSlider.maximumValue = 1+[CardManager maxStrength];
    self.influenceSlider.maximumValue = 1+[CardManager maxInfluence];
    
    [self.costSlider setThumbImage:[UIImage imageNamed:@"credit_slider"] forState:UIControlStateNormal];
    [self.muApSlider setThumbImage:[UIImage imageNamed:self.role == NRRoleRunner ? @"mem_slider" : @"point_slider" ] forState:UIControlStateNormal];
    [self.strengthSlider setThumbImage:[UIImage imageNamed:@"strength_slider"] forState:UIControlStateNormal];
    [self.influenceSlider setThumbImage:[UIImage imageNamed:@"influence_slider"] forState:UIControlStateNormal];
    
    [self clearFilters:nil];
    
    self.previewTable.rowHeight = 30;
    self.previewTable.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.showPreviewTable = YES;
    
    if (self.parentViewController.view.frame.size.height == 480)
    {
        // iphone 4s
        self.previewTable.scrollEnabled = NO;
        self.showPreviewTable = NO;
    }
    
    self.previewHeader.font = [UIFont md_systemFontOfSize:15];
}

-(void) viewDidAppear:(BOOL)animated
{
    NSAssert(self.navigationController.viewControllers.count == 4, @"nav oops");
    
    UINavigationItem* topItem = self.navigationController.navigationBar.topItem;
    UIBarButtonItem* clearButton = [[UIBarButtonItem alloc] initWithTitle:l10n(@"Clear") style:UIBarButtonItemStylePlain target:self action:@selector(clearFilters:)];
    topItem.rightBarButtonItem = clearButton;
    
    [super viewDidAppear:animated];
}

-(void) clearFilters:(id)sender
{
    [self.cardList clearFilters];
    
    [self.factionControl selectAllSegments:YES];
    [self.miniFactionControl selectAllSegments:self.dataDestinyAllowed];
    [self.typeControl selectAllSegments:YES];
    
    self.influenceSlider.value = 0;
    self.strengthSlider.value = 0;
    self.muApSlider.value = 0;
    self.costSlider.value = 0;
    
    [self influenceChanged:nil];
    [self strengthChanged:nil];
    [self muApChanged:nil];
    [self costChanged:nil];
}

-(void) strengthChanged:(UISlider*)sender
{
    int value = round(sender.value);
    // NSLog(@"str: %f %d", sender.value, value);
    sender.value = value--;
    self.strengthLabel.text = [NSString stringWithFormat:l10n(@"Strength: %@"), value == -1 ? l10n(@"All") : [@(value) stringValue]];
    [self.cardList filterByStrength:value];
    [self updatePreview];
}

-(void) muApChanged:(UISlider*)sender
{
    int value = round(sender.value);
    // NSLog(@"mu: %f %d", sender.value, value);
    sender.value = value--;
    self.muApLabel.text = [NSString stringWithFormat:self.role == NRRoleRunner ? l10n(@"MU: %@") : l10n(@"AP: %@"), value == -1 ? l10n(@"All") : [@(value) stringValue]];
    
    if (self.role == NRRoleRunner)
    {
        [self.cardList filterByMU:value];
    }
    else
    {
        [self.cardList filterByAgendaPoints:value];
    }
    [self updatePreview];
}

-(void) costChanged:(UISlider*)sender
{
    int value = round(sender.value);
    // NSLog(@"cost: %f %d", sender.value, value);
    sender.value = value--;
    self.costLabel.text = [NSString stringWithFormat:l10n(@"Cost: %@"), value == -1 ? l10n(@"All") : [@(value) stringValue]];
    [self.cardList filterByCost:value];
    [self updatePreview];
}

-(void) influenceChanged:(UISlider*)sender
{
    int value = round(sender.value);
    // NSLog(@"inf: %f %d", sender.value, value);
    sender.value = value--;
    self.influenceLabel.text = [NSString stringWithFormat:l10n(@"Influence: %@"), value == -1 ? l10n(@"All") : [@(value) stringValue]];
    
    if (self.identity)
    {
        [self.cardList filterByInfluence:value forFaction:self.identity.faction];
    }
    else
    {
        [self.cardList filterByInfluence:value];
    }
    [self updatePreview];
}

#pragma mark - multi select delegate

-(void)multiSelect:(MultiSelectSegmentedControl *)control didChangeValue:(BOOL)value atIndex:(NSUInteger)index
{
    NSArray* values = control.tag == TAG_TYPE ? self.typeNames : self.factionNames;
    
    NSMutableSet* set = [NSMutableSet set];

    if (control.tag == TAG_TYPE)
    {
        [control.selectedSegmentIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            [set addObject:values[idx]];
        }];
        [self.cardList filterByTypes:set];
    }
    else
    {
        [self.factionControl.selectedSegmentIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            [set addObject:values[idx]];
        }];
        if (self.role == NRRoleRunner)
        {
            [self.miniFactionControl.selectedSegmentIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                [set addObject:values[idx+4]];
            }];
        }
        
        [self.cardList filterByFactions:set];
    }
    [self updatePreview];
}

#pragma mark - table view

-(void) updatePreview
{
    self.cards = self.cardList.allCards;
    
    NSInteger count = self.cards.count;
    NSString* fmt = count == 1 ? l10n(@"%lu matching card") : l10n(@"%lu matching cards");
    NSString* text = @"  ";
    text = [text stringByAppendingString:[NSString stringWithFormat:fmt, count]];
    self.previewHeader.text = text;
    
    [self.previewTable reloadData];
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.showPreviewTable ? self.cards.count : 0;
}

-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* cellIdentifier = @"previewCell";
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.font = [UIFont systemFontOfSize:13];
    }
    
    Card* card = self.cards[indexPath.row];
    cell.textLabel.text = card.name;
    
    return cell;
}

@end
