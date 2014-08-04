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
    
    NRFaction rf[] = { NRFactionNone, NRFactionNeutral, NRFactionAnarch, NRFactionCriminal, NRFactionShaper };
    NRFaction cf[] = { NRFactionNone, NRFactionNeutral, NRFactionHaasBioroid, NRFactionJinteki, NRFactionNBN, NRFactionWeyland };
    
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

    NSMutableArray* factions = [NSMutableArray array];
    factions = [NSMutableArray array];
    [factions addObject:@[ [Faction name:NRFactionNone ], [Faction name:NRFactionNeutral ]]];

    NSRange range = { 2, runnerFactions.count-2 };
    NSIndexSet* runnerSet = [NSIndexSet indexSetWithIndexesInRange:range];
    [factions addObject:[NSArray arrayWithArray:[runnerFactions objectsAtIndexes:runnerSet]]];
    
    range.length = corpFactions.count-2;
    NSIndexSet* corpSet = [NSIndexSet indexSetWithIndexesInRange:range];
    [factions addObject:[NSArray arrayWithArray:[corpFactions objectsAtIndexes:corpSet]]];
    
    NSArray* factionSections = @[ @"", l10n(@"Runner"), l10n(@"Corp") ];
    
    allFactions = [[TableData alloc] initWithSections:factionSections andValues:factions];
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
