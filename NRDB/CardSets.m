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
static NSMutableDictionary* setNames;
static NSMutableSet* setCodes;
static NSMutableDictionary* releases;

static NSArray* setGroups;
static NSArray* setsPerGroup;

static struct cardSetData {
    int setNum;
    char* settingsKey;
    char* setCode;
    NRCycle cycle;
    BOOL released;
} cardSetData[] = {
    {  1, "use_coreset", "core", NRCycleCoreDeluxe, YES },
    {  8, "use_creation_and_control", "cac", NRCycleCoreDeluxe, YES },
    { 15, "use_honor_and_profit", "hap", NRCycleCoreDeluxe, YES },
    
    // genesis
    { 2, "use_what_lies_ahead", "wla", NRCycleGenesis, YES },
    { 3, "use_trace_amount", "ta", NRCycleGenesis, YES },
    { 4, "use_cyber_exodus", "ce", NRCycleGenesis, YES },
    { 5, "use_study_in_static", "asis", NRCycleGenesis, YES },
    { 6, "use_humanitys_shadow", "hs", NRCycleGenesis, YES },
    { 7, "use_future_proof", "fp", NRCycleGenesis, YES },
    
    // spin
    {  9, "use_opening_moves", "om", NRCycleSpin, YES },
    { 10, "use_second_thoughts", "st", NRCycleSpin, YES},
    { 11, "use_mala_tempora", "mt", NRCycleSpin, YES },
    { 12, "use_true_colors", "tc", NRCycleSpin, YES },
    { 13, "use_fear_and_loathing", "fal", NRCycleSpin, YES },
    { 14, "use_double_time", "dt", NRCycleSpin, YES },
    
    // lunar
    { 16, "use_upstalk", "up", NRCycleLunar, YES },
    { 17, "use_spaces_between", "tsb", NRCycleLunar, YES },
    { 18, "use_first_contact", "fc", NRCycleLunar, NO },
    { 19, "use_up_and_over", "uao", NRCycleLunar, NO },
    { 20, "use_all_that_remains", "atr", NRCycleLunar, NO },
    { 21, "use_the_source", "ts", NRCycleLunar, NO },
    
    { 0 }
};

+(void) initialize
{
    cardSets = [NSMutableArray array];
    releases = [NSMutableDictionary dictionary];
    setNames = [NSMutableDictionary dictionary];
    setCodes = [NSMutableSet set];
    
    struct cardSetData* c = cardSetData;
    while (c->setNum > 0)
    {
        CardSets* csd = [CardSets new];
        csd.setNum = c->setNum;
        csd.setCode = [NSString stringWithUTF8String:c->setCode];
        csd.settingsKey = [NSString stringWithUTF8String:c->settingsKey];
        csd.cycle = c->cycle;
        csd.released = c->released;
        
        [setCodes addObject:csd.setCode];
        
        [releases setObject:@(csd.setNum) forKey:csd.setCode];
        
        [cardSets addObject:csd];
        ++c;
    }
    
    setGroups = @[ @"", l10n(@"Core / Deluxe"), l10n(@"Genesis Cycle"), l10n(@"Spin Cycle"), l10n(@"Lunar Cycle") ];
    setsPerGroup = @[
        @[ @"" ],
        @[ @"core", @"cac", @"hap" ],
        @[ @"wla", @"ta", @"ce", @"asis", @"hs", @"fp" ],
        @[ @"om", @"st", @"mt", @"tc", @"fal", @"dt" ],
        @[ @"up", @"tsb", @"fc", @"uao", @"atr", @"ts" ]
    ];
    
    NSAssert(setGroups.count == setsPerGroup.count, @"set group mismatch");
}

+(void) initializeSetNames:(NSArray*)cards
{
    [setNames removeAllObjects];
    for (Card* c in cards)
    {
        [setNames setObject:c.setName forKey:c.setCode];
    }
}

+(NSDictionary*) settingsDefaults
{
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    dict[USE_UNPUBLISHED_IDS] = @(NO);
    dict[USE_DRAFT_IDS] = @(NO);
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
    
    if (![settings boolForKey:USE_UNPUBLISHED_IDS])
    {
        [set addObject:@"special"];
    }
    if (![settings boolForKey:USE_DRAFT_IDS])
    {
        [set addObject:@"draft"];
    }
    return set;
}

+(TableData*) allSetsForTableview
{
    NSSet* disabledSets = [CardSets disabledSetCodes];
    NSMutableArray* sections = [setGroups mutableCopy];
    NSMutableArray* sets = [NSMutableArray array];
    
    for (NSArray* arr in setsPerGroup)
    {
        NSMutableArray* names = [NSMutableArray array];
        for (NSString* setCode in arr)
        {
            if (setCode.length == 0)
            {
                [names addObject:kANY];
            }
            else if (![disabledSets containsObject:setCode])
            {
                NSString* name = [setNames objectForKey:setCode];
                if (name)
                {
                    [names addObject:name];
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

+(NSSet*) allKnownSets
{
    return setCodes;
}

+(NSArray*) setsUsedInDeck:(Deck*) deck
{
    NSMutableDictionary* sets = [NSMutableDictionary dictionary];
    NSMutableDictionary* setNums = [NSMutableDictionary dictionary];
    
    for (CardCounter* cc in deck.allCards)
    {
        NSNumber*n = [sets objectForKey:cc.card.setCode];
        BOOL isCore = [cc.card.setCode isEqualToString:@"core"];
        
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
