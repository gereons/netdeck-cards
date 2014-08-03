//
//  Faction.m
//  NRDB
//
//  Created by Gereon Steffens on 15.12.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "Faction.h"
#import "CardManager.h"

@implementation Faction

static NSDictionary* code2faction;
static NSMutableDictionary* faction2name;

static NSMutableArray* runnerFactions;
static NSMutableArray* corpFactions;
static NSMutableArray* allFactions;

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
    NRFaction af[] = { NRFactionNeutral,
        NRFactionAnarch, NRFactionCriminal, NRFactionShaper,
        NRFactionHaasBioroid, NRFactionJinteki, NRFactionNBN, NRFactionWeyland };
    
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

    allFactions = [NSMutableArray array];
    for (int i=0; i<DIM(af); ++i)
    {
        [allFactions addObject:[Faction name:af[i]]];
    }
    [allFactions sortUsingComparator:^NSComparisonResult(NSString* s1, NSString* s2) {
        return [s1 compare:s2];
    }];
    [allFactions insertObject:[Faction name:NRFactionNone] atIndex:0];
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
    switch (role)
    {
        case NRRoleRunner: return runnerFactions;
        case NRRoleCorp: return corpFactions;
        case NRRoleNone: return allFactions;
    }
}

@end
