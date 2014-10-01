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

static NSMutableDictionary* faction2name;

static NSMutableArray* runnerFactions;
static NSMutableArray* corpFactions;
static TableData* allFactions;

+(void) initialize
{
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

+(NSString*) shortName:(NRFaction)faction
{
    switch (faction)
    {
        case NRFactionHaasBioroid:
            return @"H-B";
        case NRFactionWeyland:
            return @"Weyland";
        default:
            return [Faction name:faction];
    }
}

+(NSString*) name:(NRFaction)faction
{
    return [faction2name objectForKey:@(faction)];
}

+(NRFaction) faction:(NSString*)faction
{
    unichar ch = [faction characterAtIndex:0];
    switch (ch)
    {
        case 'A': return NRFactionAnarch;
        case 'C': return NRFactionCriminal;
        case 'S': return NRFactionShaper;
        case 'H': return NRFactionHaasBioroid;
        case 'J': return NRFactionJinteki;
        case 'W':
        case 'T': return NRFactionWeyland;  // catch both "W..." and "The W..."
        case 'N':
            return [faction isEqualToString:@"Neutral"] ? NRFactionNeutral : NRFactionNBN;
    }
    return NRFactionNone;
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
