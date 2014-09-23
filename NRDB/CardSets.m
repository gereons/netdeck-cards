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

#warning use /sets API to get names!

@interface CardSets()
@property int setNum;
@property NSString* setName;
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

static struct cardSetData {
    int setNum;
    char* settingsKey;
    char* setName;
    NRCycle cycle;
    BOOL released;
} cardSetData[] = {
    {  1, "use_coreset", "Core", NRCycleCoreDeluxe, YES },
    
    // genesis
    { 2, "use_what_lies_ahead", "What Lies Ahead", NRCycleGenesis, YES },
    { 3, "use_trace_amount", "Trace Amount", NRCycleGenesis, YES },
    { 4, "use_cyber_exodus", "Cyber Exodus", NRCycleGenesis, YES },
    { 5, "use_study_in_static", "A Study In Static", NRCycleGenesis, YES },
    { 6, "use_humanitys_shadow", "Humanity's Shadow", NRCycleGenesis, YES },
    { 7, "use_future_proof", "Future Proof", NRCycleGenesis, YES },
    // creation and control
    { 8, "use_creation_and_control", "Creation and Control", NRCycleCoreDeluxe, YES },
    
    // spin
    {  9, "use_opening_moves", "Opening Moves", NRCycleSpin, YES },
    { 10, "use_second_thoughts", "Second Thoughts", NRCycleSpin, YES},
    { 11, "use_mala_tempora", "Mala Tempora", NRCycleSpin, YES },
    { 12, "use_true_colors", "True Colors", NRCycleSpin, YES },
    { 13, "use_fear_and_loathing", "Fear and Loathing", NRCycleSpin, YES },
    { 14, "use_double_time", "Double Time", NRCycleSpin, YES },
    // honor and profit
    { 15, "use_honor_and_profit", "Honor and Profit", NRCycleCoreDeluxe, YES },
    
    // lunar
    { 16, "use_upstalk", "Upstalk", NRCycleLunar, YES },
    { 17, "use_spaces_between", "The Spaces Between", NRCycleLunar, YES },
    { 18, "use_first_contact", "First Contact", NRCycleLunar, YES },
    { 19, "use_up_and_over", "Up and Over", NRCycleLunar, NO },
    { 20, "use_all_that_remains", "All That Remains", NRCycleLunar, NO },
    { 21, "use_the_source", "The Source", NRCycleLunar, NO },
    // order and chaos
    { 22, "use_order_and_chaos", "Order and Chaos", NRCycleCoreDeluxe, NO },
    
    { 0 }
};

+(void) initialize
{
    cardSets = [NSMutableArray array];
    releases = [NSMutableDictionary dictionary];
    setNames = [NSMutableDictionary dictionary];
    
    struct cardSetData* c = cardSetData;
    while (c->setNum > 0)
    {
        CardSets* csd = [CardSets new];
        csd.setNum = c->setNum;
        csd.setName = [NSString stringWithUTF8String:c->setName];
        csd.settingsKey = [NSString stringWithUTF8String:c->settingsKey];
        csd.cycle = c->cycle;
        csd.released = c->released;
        
        [releases setObject:@(csd.setNum) forKey:csd.setName];
        [setNames setObject:csd.setName forKey:@(csd.setNum)];
        [cardSets addObject:csd];
        ++c;
    }
    
    setGroups = @[ @"", l10n(@"Core / Deluxe"), l10n(@"Genesis Cycle"), l10n(@"Spin Cycle"), l10n(@"Lunar Cycle") ];
    setsPerGroup = @[
        @[  @0 ],
        @[  @1,  @8, @15, @22 ],
        @[  @2,  @3,  @4,  @5,  @6,  @7 ],
        @[  @9, @10, @11, @12, @13, @14 ],
        @[ @16, @17, @18, @19, @20, @21 ]
    ];
    
    NSAssert(setGroups.count == setsPerGroup.count, @"set group mismatch");
}

+(BOOL) setupFromDatasuckerApi:(NSArray *)json
{
#warning fixme
    return YES;
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

+(NSSet*) disabledSets
{
    NSMutableSet* set = [NSMutableSet set];
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    for (CardSets* cs in cardSets)
    {
        if (![settings boolForKey:cs.settingsKey])
        {
            [set addObject:cs.setName];
        }
    }
    
    return set;
}

+(TableData*) allSetsForTableview
{
    NSSet* disabledSets = [CardSets disabledSets];
    NSMutableArray* sections = [setGroups mutableCopy];
    NSMutableArray* sets = [NSMutableArray array];
    
    for (NSArray* arr in setsPerGroup)
    {
        NSMutableArray* names = [NSMutableArray array];
        for (NSNumber* setNum in arr)
        {
            NSString* setName = [setNames objectForKey:setNum];
            if (setNum.integerValue == 0)
            {
                [names addObject:kANY];
            }
            else if (![disabledSets containsObject:setName])
            {
                [names addObject:setName];
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
        
        [sets setObject:n forKey:cc.card.setName];
        int rel = [[releases objectForKey:cc.card.setName] intValue];
        if (rel > 0)
        {
            [setNums setObject:@(rel) forKey:cc.card.setName];
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
        int rel = [[releases objectForKey:cc.card.setName] intValue];
        maxRelease = MAX(maxRelease, rel);
    }

    for (CardSets* cs in cardSets)
    {
        if (cs.setNum == maxRelease)
        {
            return [setNames objectForKey:cs.setName];
        }
    }
    return @"?";
}

@end
