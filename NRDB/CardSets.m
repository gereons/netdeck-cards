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

static struct cardSetData {
    int setNum;
    char* settingsKey;
    char* setCode;
    NRCycle cycle;
    BOOL released;
} cardSetData[] = {
    {  1, "use_coreset", "223", NRCycleCoreDeluxe, YES },
    
    // genesis
    { 2, "use_wla", "241", NRCycleGenesis, YES },
    { 3, "use_ta", "242", NRCycleGenesis, YES },
    { 4, "use_ce", "260", NRCycleGenesis, YES },
    { 5, "use_asis", "264", NRCycleGenesis, YES },
    { 6, "use_hs", "278", NRCycleGenesis, YES },
    { 7, "use_fp", "279", NRCycleGenesis, YES },
    // creation and control
    { 8, "use_cac", "280", NRCycleCoreDeluxe, YES },
    
    // spin
    {  9, "use_om", "307", NRCycleSpin, YES },
    { 10, "use_st", "308", NRCycleSpin, YES},
    { 11, "use_mt", "309", NRCycleSpin, YES },
    { 12, "use_tc", "310", NRCycleSpin, YES },
    { 13, "use_fal", "311", NRCycleSpin, YES },
    { 14, "use_dt", "312", NRCycleSpin, YES },
    // honor and profit
    { 15, "use_hap", "342", NRCycleCoreDeluxe, YES },
    
    // lunar
    { 16, "use_us", "333", NRCycleLunar, YES },
    { 17, "use_tsb", "358", NRCycleLunar, YES },
    { 18, "use_fc", "359", NRCycleLunar, YES },
    // { 19, "use_uao", "", NRCycleLunar, NO },
    // { 20, "use_atr", "", NRCycleLunar, NO },
    // { 21, "use_ts", "", NRCycleLunar, NO },
    // order and chaos
    // { 22, "use_oac", "", NRCycleCoreDeluxe, NO },
    
    { 0 }
};

+(void) initialize
{
    cardSets = [NSMutableArray array];
    releases = [NSMutableDictionary dictionary];
    setNames = [NSMutableDictionary dictionary];
    newSetCodes = [NSMutableSet set];
    
    struct cardSetData* c = cardSetData;
    while (c->setNum > 0)
    {
        CardSets* csd = [CardSets new];
        csd.setNum = c->setNum;
        csd.setCode = [NSString stringWithUTF8String:c->setCode];
        csd.settingsKey = [NSString stringWithUTF8String:c->settingsKey];
        csd.cycle = c->cycle;
        csd.released = c->released;
        
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
    NSMutableSet* set = [NSMutableSet set];
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    for (CardSets* cs in cardSets)
    {
        if (![settings boolForKey:cs.settingsKey])
        {
            [set addObject:cs.setCode];
        }
    }
    
    if ([settings boolForKey:IGNORE_UNKNOWN_SETS])
    {
        [set addObjectsFromArray:newSetCodes.allObjects];
    }
    
    return set;
}

+(NSSet*) knownSetCodes
{
    NSMutableSet* knownSets = [NSMutableSet set];
    for (CardSets* cs in cardSets)
    {
        [knownSets addObject:cs.setCode];
    }
    
    return knownSets;
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
