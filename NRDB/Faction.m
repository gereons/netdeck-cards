//
//  Faction.m
//  NRDB
//
//  Created by Gereon Steffens on 15.12.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "Faction.h"
#import "CardManager.h"
#import "TableData.h"

@implementation Faction

static NSDictionary* code2faction;
static NSMutableDictionary* faction2name;

static NSMutableArray* runnerFactions;
static NSMutableArray* corpFactions;
static TableData* allFactions;

+(void) initialize
{
    code2faction = @{
        @"haas-bioroid": @(NRFactionHaasBioroid),
        @"weyland-consortium": @(NRFactionWeyland),
        @"jinteki": @(NRFactionJinteki),
        @"nbn": @(NRFactionNBN),
        @"anarch": @(NRFactionAnarch),
        @"shaper": @(NRFactionShaper),
        @"criminal": @(NRFactionCriminal),
        @"neutral": @(NRFactionNeutral)
    };
    
    faction2name = [NSMutableDictionary dictionary];
    faction2name[@(NRFactionNone)] = kANY;
}

+(void) initializeFactionNames:(NSArray*)cards
{
    [faction2name removeAllObjects];
    faction2name[@(NRFactionNone)] = kANY;
    
    for (Card* c in cards)
    {
        [faction2name setObject:c.factionStr forKey:@(c.faction)];
        
        if (faction2name.count == code2faction.count + 1)
        {
            break;
        }
    }
    
    NRFaction rf[] = { NRFactionAnarch, NRFactionCriminal, NRFactionShaper };
    NRFaction cf[] = { NRFactionHaasBioroid, NRFactionJinteki, NRFactionNBN, NRFactionWeyland };
    NSArray* common = @[ [Faction name:NRFactionNone ], [Faction name:NRFactionNeutral ]];
    
    runnerFactions = [NSMutableArray array];
    for (int i=0; i<DIM(rf); ++i)
    {
        [runnerFactions addObject:[Faction name:rf[i]]];
    }
    
    corpFactions = [NSMutableArray array];
    for (int i=0; i<DIM(cf); ++i)
    {
        [corpFactions addObject:[Faction name:cf[i]]];
    }

    NSArray* factionSections = @[ @"", l10n(@"Runner"), l10n(@"Corp") ];
    NSMutableArray* factions = [NSMutableArray array];
    factions = [NSMutableArray array];
    [factions addObject:common];
    [factions addObject:runnerFactions];
    [factions addObject:corpFactions];
    allFactions = [[TableData alloc] initWithSections:factionSections andValues:factions];
    
    NSMutableIndexSet* indexes = [NSMutableIndexSet indexSetWithIndex:0];
    [indexes addIndex:1];
    [runnerFactions insertObjects:common atIndexes:indexes];
    [corpFactions insertObjects:common atIndexes:indexes];
}

+(NSString*) name:(NRFaction)faction
{
    return [faction2name objectForKey:@(faction)];
}

+(NRFaction) faction:(NSString*)code
{
    return [[code2faction objectForKey:code] intValue];
}

+(NSArray*) factionsForRole:(NRRole)role
{
    NSAssert(role != NRRoleNone, @"no role");
    return role == NRRoleRunner ? runnerFactions : corpFactions;
}

+(TableData*) allFactions
{
    return allFactions;
}

@end
