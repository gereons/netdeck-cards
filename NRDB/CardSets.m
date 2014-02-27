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
    { 14, "use_double_time", "dt", NRCycleSpin, NO },
    
    // lunar
    { 16, "use_upstalk", "up", NRCycleLunar, NO },
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

#define NAME(x) [setNames objectForKey:x]
+(TableData*) allSetsForTableview
{
    NSArray* sections = @[ @"", @"Core / Deluxe", @"Genesis Cycle", @"Spin Cycle", @"Lunar Cycle" ];
    NSArray* sets = @[
        @[ kANY ],
        @[ NAME(@"core"), NAME(@"cac"), NAME(@"hap") ],
        @[ NAME(@"wla"), NAME(@"ta"), NAME(@"ce"), NAME(@"asis"), NAME(@"hs"), NAME(@"fp") ],
        @[ NAME(@"om"), NAME(@"st"), NAME(@"mt"), NAME(@"tc"), NAME(@"fal"), NAME(@"dt") ],
        @[ NAME(@"up") ]
    ];
    
    return [[TableData alloc] initWithSections:sections andValues:sets];
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
