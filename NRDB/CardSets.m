//
//  CardSets.m
//  NRDB
//
//  Created by Gereon Steffens on 14.12.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "CardSets.h"
#import "CardManager.h"
#import "Deck.h"
#import "SettingsKeys.h"

@interface CardSets()
@property int setNum;
@property NSString* setCode;
@property NSString* settingsKey;
@property NRCycle cycle;
@property BOOL released;
@end

@implementation CardSets

static NSMutableArray* cardSets;
static NSMutableDictionary* releases;
static NSMutableDictionary* setNames;
static NSArray* setGroups;
static NSArray* setsPerGroup;
static NSMutableSet* newSetCodes;
static NSMutableDictionary* cgdbToNrdbMap;

static struct cardSetData {
    int setNum;
    char* nrdbCode;
    char* cgdbCode;
    NRCycle cycle;
    BOOL released;
} cardSetData[] = {
    {  1, "core", "223", NRCycleCoreDeluxe, YES },
    
    // genesis
    { 2, "wla", "241", NRCycleGenesis, YES },
    { 3, "ta", "242", NRCycleGenesis, YES },
    { 4, "ce", "260", NRCycleGenesis, YES },
    { 5, "asis", "264", NRCycleGenesis, YES },
    { 6, "hs", "278", NRCycleGenesis, YES },
    { 7, "fp", "279", NRCycleGenesis, YES },
    // c&c
    { 8, "cac", "280", NRCycleCoreDeluxe, YES },
    
    // spin
    {  9, "om", "307", NRCycleSpin, YES },
    { 10, "st", "308", NRCycleSpin, YES},
    { 11, "mt", "309", NRCycleSpin, YES },
    { 12, "tc", "310", NRCycleSpin, YES },
    { 13, "fal", "311", NRCycleSpin, YES },
    { 14, "dt", "312", NRCycleSpin, YES },
    // h&p
    { 15, "hap", "342", NRCycleCoreDeluxe, YES },
    
    // lunar
    { 16, "up", "333", NRCycleLunar, YES },
    { 17, "tsb", "358", NRCycleLunar, YES },
    { 18, "fc", "359", NRCycleLunar, YES },
    { 19, "uao", "360", NRCycleLunar, YES },
    { 20, "atr", "", NRCycleLunar, NO },
    { 21, "ts", "", NRCycleLunar, NO },
    // o&c
    { 22, "oac", "", NRCycleCoreDeluxe, NO },
    
    { 0 }
};

+(void) initialize
{
    cardSets = [NSMutableArray array];
    releases = [NSMutableDictionary dictionary];
    setNames = [NSMutableDictionary dictionary];
    newSetCodes = [NSMutableSet set];
    cgdbToNrdbMap = [NSMutableDictionary dictionary];
    
    struct cardSetData* c = cardSetData;
    while (c->setNum > 0)
    {
        CardSets* csd = [CardSets new];
        csd.setNum = c->setNum;
        csd.setCode = [NSString stringWithUTF8String:c->nrdbCode];
        NSString* nrdbCode = [NSString stringWithUTF8String:c->nrdbCode];
        csd.settingsKey = [NSString stringWithFormat:@"use_%@", nrdbCode];
        csd.cycle = c->cycle;
        csd.released = c->released;
        cgdbToNrdbMap[@(c->cgdbCode)] = csd.setCode;
        
        [releases setObject:@(csd.setNum) forKey:csd.setCode];
        [cardSets addObject:csd];
        ++c;
    }
    
    setGroups = @[ @"", l10n(@"Core / Deluxe"), l10n(@"Cycle #1"), l10n(@"Cycle #2"), l10n(@"Cycle #3") ];
    setsPerGroup = @[
        @[  @0 ],
        @[  @1,  @8, @15, @22 ],
        @[  @2,  @3,  @4,  @5,  @6,  @7 ],
        @[  @9, @10, @11, @12, @13, @14 ],
        @[ @16, @17, @18, @19, @20, @21 ]
    ];
    
    NSAssert(setGroups.count == setsPerGroup.count, @"set group mismatch");
}

+(void) setupSetNames
{
    NSArray* cards = [CardManager allCards];
    NSSet* knownCodes = [CardSets knownSetCodes];
    for (Card* card in cards)
    {
        [setNames setObject:card.setName forKey:card.setCode];
        
        if (![knownCodes containsObject:card.setCode])
        {
            [newSetCodes addObject:card.setCode];
        }
    }
}

+(NSString*) nameForKey:(NSString *)key
{
    for (CardSets* cs in cardSets)
    {
        if ([cs.settingsKey isEqualToString:key])
        {
            return [setNames objectForKey:cs.setCode];
        }
    }
    return nil;
}

+(NSDictionary*) settingsDefaults
{
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    for (CardSets* cs in cardSets)
    {
        [dict setObject:@(cs.released) forKey:cs.settingsKey];
    }
    return dict;
}

+(NSSet*) disabledSetCodes
{
    NSMutableSet* sets = [NSMutableSet set];
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    for (CardSets* cs in cardSets)
    {
        if (![settings boolForKey:cs.settingsKey])
        {
            [sets addObject:cs.setCode];
        }
    }
    
    if ([settings boolForKey:IGNORE_UNKNOWN_SETS])
    {
        [sets addObjectsFromArray:newSetCodes.allObjects];
    }
    if (![settings boolForKey:USE_DRAFT_IDS])
    {
        [sets addObject:DRAFT_SET_CODE];
    }
    if (![settings boolForKey:USE_UNPUBLISHED_IDS])
    {
        [sets addObject:SPECIAL_SET_CODE];
    }
    
    return sets;
}

+(NSSet*) knownSetCodes
{
    NSMutableSet* knownSets = [NSMutableSet set];
    for (CardSets* cs in cardSets)
    {
        [knownSets addObject:cs.setCode];
    }
    [knownSets addObject:DRAFT_SET_CODE];
    
    return knownSets;
}

+(NSString*) setCodeForCgdbCode:(NSString*)setCode
{
    return cgdbToNrdbMap[setCode];
}

+(void) registerNrdbCode:(NSString *)setCode andName:(NSString *)setName
{
    setNames[setCode] = setName;
}

+(TableData*) allSetsForTableview
{
    NSSet* disabledSetCodes = [CardSets disabledSetCodes];
    NSMutableArray* sections = [setGroups mutableCopy];
    NSMutableArray* sets = [NSMutableArray array];
    
    for (NSArray* arr in setsPerGroup)
    {
        NSMutableArray* names = [NSMutableArray array];
        for (NSNumber* setNumber in arr)
        {
            NSInteger setNum = setNumber.intValue;
            
            if (setNum == 0)
            {
                [names addObject:kANY];
            }
            else if (setNum <= cardSets.count)
            {
                CardSets* cs = [cardSets objectAtIndex:setNum-1];
                NSString* setName = [setNames objectForKey:cs.setCode];
                if (setName && ![disabledSetCodes containsObject:cs.setCode])
                {
                    [names addObject:setName];
                }
            }
        }
        [sets addObject:names];
    }
    
    for (int i=0; i<sets.count; )
    {
        NSArray* arr = [sets objectAtIndex:i];
        if (arr.count == 0)
        {
            [sets removeObjectAtIndex:i];
            [sections removeObjectAtIndex:i];
        }
        else
        {
            ++i;
        }
    }
    
    return [[TableData alloc] initWithSections:sections andValues:sets];
}

+(NSArray*) setsUsedInDeck:(Deck*) deck
{
    NSMutableDictionary* sets = [NSMutableDictionary dictionary];
    NSMutableDictionary* setNums = [NSMutableDictionary dictionary];
    
    for (CardCounter* cc in deck.allCards)
    {
        NSNumber*n = [sets objectForKey:cc.card.setName];
        BOOL isCore = cc.card.isCore;
        
        if (n == nil)
        {
            n = @1;
        }
        
        if (isCore && cc.count > cc.card.quantity)
        {
            int needed = (int)(0.5 + (float)cc.count / cc.card.quantity);
            if (needed > [n intValue])
            {
                n = @(needed);
            }
        }
        
        [sets setObject:n forKey:cc.card.setCode];
        int rel = [[releases objectForKey:cc.card.setCode] intValue];
        if (rel > 0)
        {
            [setNums setObject:@(rel) forKey:cc.card.setCode];
        }
    }
    
    // NSLog(@"%@ %@", sets, setNums);
    
    NSArray* sorted = [[setNums allKeys] sortedArrayUsingComparator:^NSComparisonResult(NSString* s1, NSString* s2) {
        NSNumber* n1 = [setNums objectForKey:s1];
        NSNumber* n2 = [setNums objectForKey:s2];
        return [n1 compare:n2];
    }];
    
    NSMutableArray* result = [NSMutableArray array];
    for (NSString* s in sorted)
    {
        if ([s isEqualToString:@"core"])
        {
            NSNumber* needed = [sets objectForKey:s];
            [result addObject:[NSString stringWithFormat:@"%@×%@", needed, [setNames objectForKey:s]]];
        }
        else
        {
            [result addObject:[setNames objectForKey:s]];
        }
    }
    // NSLog(@"%@", result);
    return result;
}

+(NSString*) mostRecentSetUsedInDeck:(Deck *)deck
{
    int maxRelease = 0;
        
    for (CardCounter* cc in deck.allCards)
    {
        int rel = [[releases objectForKey:cc.card.setCode] intValue];
        maxRelease = MAX(maxRelease, rel);
    }

    for (CardSets* cs in cardSets)
    {
        if (cs.setNum == maxRelease)
        {
            return [setNames objectForKey:cs.setCode];
        }
    }
    return @"?";
}

@end
