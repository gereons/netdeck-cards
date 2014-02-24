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
static NSDictionary* faction2name;
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
    
    faction2name = @{
        @(NRFactionHaasBioroid): @"Haas-Bioroid",
        @(NRFactionWeyland): @"Weyland Consortium",
        @(NRFactionJinteki): @"Jinteki",
        @(NRFactionNBN): @"NBN",
        @(NRFactionAnarch): @"Anarch",
        @(NRFactionShaper): @"Shaper",
        @(NRFactionCriminal): @"Criminal",
        @(NRFactionNeutral): @"Neutral",
        @(NRFactionNone): kANY
    };
    
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
