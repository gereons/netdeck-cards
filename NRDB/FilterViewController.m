//
//  FilterViewController.m
//  NRDB
//
//  Created by Gereon Steffens on 24.08.15.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

#import "FilterViewController.h"
#import "ImageCache.h"
#import "Faction.h"
#import "CardType.h"
#import "CardList.h"
#import "SettingsKeys.h"

@interface FilterViewController ()

@property NSArray* factionNames;
@property NSArray* typeNames;

@end

@implementation FilterViewController 

enum { TAG_FACTION, TAG_TYPE };

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Filter";
    
    self.factionLabel.text = l10n(@"Faction");
    self.typeLabel.text = l10n(@"Type");
    
    if (self.role == NRRoleRunner)
    {
        BOOL dataDestinyAllowed = [[NSUserDefaults standardUserDefaults] boolForKey:USE_DATA_DESTINY];
        
        if (dataDestinyAllowed)
        {
            self.factionNames = @[ [Faction name:NRFactionAnarch], [Faction name:NRFactionCriminal], [Faction name:NRFactionShaper], [Faction name:NRFactionAdam], [Faction name:NRFactionApex], [Faction name:NRFactionSunnyLebeau], [Faction name:NRFactionNeutral]];
        }
        else
        {
            self.factionNames = @[ [Faction name:NRFactionAnarch], [Faction name:NRFactionCriminal], [Faction name:NRFactionShaper], [Faction name:NRFactionNeutral]];
        }
        
        self.typeNames = @[ [CardType name:NRCardTypeEvent], [CardType name:NRCardTypeHardware], [CardType name:NRCardTypeResource], [CardType name:NRCardTypeProgram] ];
    }
    else
    {
        self.factionNames = @[ [Faction name:NRFactionHaasBioroid], [Faction name:NRFactionNBN], [Faction name:NRFactionJinteki], [Faction name:NRFactionWeyland], [Faction name:NRFactionNeutral]];

        self.typeNames = @[ [CardType name:NRCardTypeAgenda], [CardType name:NRCardTypeAsset], [CardType name:NRCardTypeUpgrade], [CardType name:NRCardTypeOperation], [CardType name:NRCardTypeIce]];
    }
    
    self.factionControl.delegate = self;
    self.factionControl.tag = TAG_FACTION;
    [self.factionControl removeAllSegments];
    
    for (NSInteger i = 0; i<self.factionNames.count; ++i)
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
}

-(void) viewDidAppear:(BOOL)animated
{
    UINavigationItem* topItem = self.navigationController.navigationBar.topItem;
    UIBarButtonItem* clearButton = [[UIBarButtonItem alloc] initWithTitle:@"Reset" style:UIBarButtonItemStylePlain target:self action:@selector(clearFilters:)];
    topItem.rightBarButtonItem = clearButton;
}

-(void) clearFilters:(id)sender
{
    [self.cardList clearFilters];
    
    [self.factionControl selectAllSegments:YES];
    [self.typeControl selectAllSegments:YES];
}

#pragma mark - multi select delegate

-(void)multiSelect:(MultiSelectSegmentedControl *)control didChangeValue:(BOOL)value atIndex:(NSUInteger)index
{
    NSArray* values = control.tag == TAG_FACTION ? self.factionNames : self.typeNames;
    
    NSMutableSet* set = [NSMutableSet set];
    [control.selectedSegmentIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [set addObject:values[idx]];
    }];
    
    if (control.tag == TAG_FACTION)
    {
        [self.cardList filterByFactions:set];
    }
    else
    {
        [self.cardList filterByTypes:set];
    }
}

@end
