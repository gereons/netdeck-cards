//
//  Faction.m
//  Net Deck
//
//  Created by Gereon Steffens on 15.12.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "Faction.h"
#import "CardManager.h"
#import "TableData.h"
#import "SettingsKeys.h"

@implementation Faction

static NSMutableDictionary* faction2name;

static NSMutableArray* runnerFactions;
static NSMutableArray* runnerFactionsPreDAD;
static NSMutableArray* corpFactions;
static NSDictionary* code2faction;
static TableData* allFactions;

+(void) initialize
{
    faction2name = [NSMutableDictionary dictionary];
    faction2name[@(NRFactionNone)] = kANY;
    
    code2faction = @{
                     @"anarch": @(NRFactionAnarch),
                     @"shaper": @(NRFactionShaper),
                     @"criminal": @(NRFactionCriminal),
                     @"weyland-consortium": @(NRFactionWeyland),
                     @"haas-bioroid": @(NRFactionHaasBioroid),
                     @"nbn": @(NRFactionNBN),
                     @"jinteki": @(NRFactionJinteki),
                     @"adam": @(NRFactionAdam),
                     @"apex": @(NRFactionApex),
                     @"sunny-lebeau": @(NRFactionSunnyLebeau),
                     @"neutral": @(NRFactionNeutral)
                     };
}

+(void) initializeFactionNames:(NSArray*)cards
{
    [faction2name removeAllObjects];
    faction2name[@(NRFactionNone)] = kANY;
    
    for (Card* c in cards)
    {
        [faction2name setObject:c.factionStr forKey:@(c.faction)];
    }
    [faction2name setObject:@"Adam" forKey:@(NRFactionAdam)];
    [faction2name setObject:@"Apex" forKey:@(NRFactionApex)];
    [faction2name setObject:@"Sunny Lebeau" forKey:@(NRFactionSunnyLebeau)];
    
    NRFaction rf_all[] = { NRFactionAnarch, NRFactionCriminal, NRFactionShaper, NRFactionAdam, NRFactionApex, NRFactionSunnyLebeau };
    NRFaction rf_preDaD[] = { NRFactionAnarch, NRFactionCriminal, NRFactionShaper };
    NRFaction cf[] = { NRFactionHaasBioroid, NRFactionJinteki, NRFactionNBN, NRFactionWeyland };
    NSArray* common = @[ [Faction name:NRFactionNone ], [Faction name:NRFactionNeutral ]];
    
    runnerFactions = [NSMutableArray array];
    for (int i=0; i<DIM(rf_all); ++i)
    {
        [runnerFactions addObject:[Faction name:rf_all[i]]];
    }
    
    runnerFactionsPreDAD = [NSMutableArray array];
    for (int i=0; i<DIM(rf_preDaD); ++i)
    {
        [runnerFactionsPreDAD addObject:[Faction name:rf_preDaD[i]]];
    }
    
    corpFactions = [NSMutableArray array];
    for (int i=0; i<DIM(cf); ++i)
    {
        [corpFactions addObject:[Faction name:cf[i]]];
    }

    NSArray* factionSections = @[ @"", l10n(@"Runner"), l10n(@"Corp") ];
    // NB copy is important, both faction arrays are modified below
    NSArray* factions = @[ common, runnerFactions.copy, corpFactions.copy ];
    allFactions = [[TableData alloc] initWithSections:factionSections andValues:factions];
    
    NSMutableIndexSet* indexes = [NSMutableIndexSet indexSetWithIndex:0];
    [indexes addIndex:1];
    [runnerFactions insertObjects:common atIndexes:indexes];
    [runnerFactionsPreDAD insertObjects:common atIndexes:indexes];
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
        case NRFactionSunnyLebeau:
            return @"Sunny";
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
    NSNumber* f = [code2faction objectForKey:[faction lowercaseString]];
    return f == nil ? NRFactionNone : (NRFaction)f.integerValue;
}

+(NSArray*) factionsForRole:(NRRole)role
{
    NSAssert(role != NRRoleNone, @"no role");
    BOOL dataDestinyAllowed = [[NSUserDefaults standardUserDefaults] boolForKey:USE_DATA_DESTINY];
    
    if (role == NRRoleRunner)
    {
        return dataDestinyAllowed ? runnerFactions : runnerFactionsPreDAD;
    }
    return corpFactions;
}

+(TableData*) allFactions
{
    return allFactions;
}

@end
