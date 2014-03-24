//
//  CardSets.m
//  NRDB
//
//  Created by Gereon Steffens on 14.12.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "CardSets.h"
#import "CardData.h"
#import "Deck.h"

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
    { 15, "use_honor_and_profit", "hap", NRCycleCoreDeluxe, NO },
    
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
    { 16, "use_upstalk", "up", NRCycleLunar, NO },
    { 17, "use_spaces_between", "tsb", NRCycleLunar, NO },
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
        @[ @"up", @"tsb" ]
    ];
    
    NSAssert(setGroups.count == setsPerGroup.count, @"set group mismatch");
}

+(void) initializeSetNames:(NSDictionary *)cards
{
    [setNames removeAllObjects];
    for (Card* c in [cards allValues])
    {
        [setNames setObject:c.setName forKey:c.setCode];
        
        if (setNames.count == setCodes.count)
        {
            break;
        }
    }
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
    return set;
}

+(NSArray*) allSets
{
    NSMutableArray* sets = [NSMutableArray arrayWithArray:[CardData allSets]];
    
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    for (CardSets* cs in cardSets)
    {
        if (![settings boolForKey:cs.settingsKey])
        {
            NSString* name = [setNames objectForKey:cs.setCode];
            [sets removeObject:name];
        }
    }
    
    return sets;
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
                [names addObject:[setNames objectForKey:setCode]];
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

+(NSString*) setsUsedInDeck:(Deck*) deck
{
    NSMutableDictionary* sets = [NSMutableDictionary dictionary];
    NSMutableDictionary* setNums = [NSMutableDictionary dictionary];
    
    if (deck.identity)
    {
        [sets setObject:@1 forKey:deck.identity.setCode];
        int rel = [[releases objectForKey:deck.identity.setCode] intValue];
        [setNums setObject:@(rel) forKey:deck.identity.setCode];
    }
    
    for (CardCounter* cc in deck.cards)
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
        [setNums setObject:@(rel) forKey:cc.card.setCode];
    }
    
    // NSLog(@"%@ %@", sets, setNums);
    
    NSArray* sorted = [[setNums allKeys] sortedArrayUsingComparator:^NSComparisonResult(NSString* s1, NSString* s2) {
        NSNumber* n1 = [setNums objectForKey:s1];
        NSNumber* n2 = [setNums objectForKey:s2];
        return [n1 compare:n2];
    }];
    
    NSMutableString* result = [NSMutableString string];
    NSString* sep = @"";
    for (NSString* s in sorted)
    {
        [result appendString:sep];
        if ([s isEqualToString:@"core"])
        {
            NSNumber* needed = [sets objectForKey:s];
            [result appendFormat:@"%@×%@", needed, [setNames objectForKey:s]];
        }
        else
        {
            [result appendString:[setNames objectForKey:s]];
        }
        sep = @", ";
    }
    // NSLog(@"%@", result);
    return result;
}

+(NSString*) mostRecentSetUsedInDeck:(Deck *)deck
{
    int maxRelease = 0;
    
    if (deck.identity)
    {
        int rel = [[releases objectForKey:deck.identity.setCode] intValue];
        maxRelease = MAX(maxRelease, rel);
    }
    
    for (CardCounter* cc in deck.cards)
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
    return nil;
}

@end
