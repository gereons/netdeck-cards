//
//  Faction.m
//  NRDB
//
//  Created by Gereon Steffens on 15.12.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "Faction.h"
#import "CardData.h"

@implementation Faction

static NSDictionary* code2faction;
static NSMutableDictionary* faction2code;
static NSMutableDictionary* faction2name;

static NSMutableArray* runnerFactions;
static NSMutableArray* corpFactions;

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
    
    faction2code = [NSMutableDictionary dictionary];
    for (NSString* s in [code2faction allKeys])
    {
        NSNumber* n = [code2faction objectForKey:s];
        [faction2code setObject:s forKey:n];
    }
    
    faction2name = [NSMutableDictionary dictionary];
    faction2name[@(NRFactionNone)] = l10n(kANY);
}

+(void) initializeFactionNames:(NSDictionary*)cards
{
    for (CardData* cd in [cards allValues])
    {
        faction2name[@(cd.faction)] = cd.factionStr;
        
        if (faction2name.count == code2faction.count + 1)
        {
            break;
        }
    }
    NSLog(@"%@", faction2name);
    
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
    return role == NRRoleRunner ? runnerFactions : corpFactions;
}

@end
