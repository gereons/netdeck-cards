//
//  CardSets.m
//  NRDB
//
//  Created by Gereon Steffens on 14.12.13.
//  Copyright (c) 2013 Gereon Steffens. All rights reserved.
//

#import "CardSets.h"
#import "CardData.h"
#import "Deck.h"

@interface CardSets()
@property int setNum;
@property NSString* setCode;
@property NSString* settingsKey;
@property NSString* setName;
@property NRCycle cycle;
@property BOOL released;
@end

@implementation CardSets

static NSMutableArray* cardSets;
static NSMutableDictionary* releases;

static struct cardSetData {
    int setNum;
    char* settingsKey;
    char* setCode;
    char* setName;
    NRCycle cycle;
    BOOL released;
} cardSetData[] = {
    {  1, "use_coreset", "core", "Core Set", NRCycleCoreDeluxe, YES },
    {  8, "use_creation_and_control", "cac", "Creation and Control", NRCycleCoreDeluxe, YES },
    { 15, "use_honor_and_profit", "hap", "Honor and Profit", NRCycleCoreDeluxe, NO },
    
    // genesis
    { 2, "use_what_lies_ahead", "wla", "What Lies Ahead", NRCycleGenesis, YES },
    { 3, "use_trace_amount", "ta", "Trace Amount", NRCycleGenesis, YES },
    { 4, "use_cyber_exodus", "ce", "Cyber Exodus", NRCycleGenesis, YES },
    { 5, "use_study_in_static", "asis", "A Study in Static", NRCycleGenesis, YES },
    { 6, "use_humanitys_shadow", "hs", "Humanity's Shadow", NRCycleGenesis, YES },
    { 7, "use_future_proof", "fp", "Future Proof", NRCycleGenesis, YES },
    
    // spin
    {  9, "use_opening_moves", "om", "Opening Moves", NRCycleSpin, YES },
    { 10, "use_second_thoughts", "st", "Second Thoughts", NRCycleSpin, YES},
    { 11, "use_mala_tempora", "mt", "Mala Tempora", NRCycleSpin, YES },
    { 12, "use_true_colors", "tc", "True Colors", NRCycleSpin, YES },
    { 13, "use_fear_and_loathing", "fal", "Fear and Loathing", NRCycleSpin, YES },
    { 14, "use_double_time", "dt", "Double Time", NRCycleSpin, NO },
    
    // lunar
    { 16, "use_upstalk", "up", "Upstalk", NRCycleLunar, NO },
    { 0 }
};

+(void) initialize
{
    cardSets = [NSMutableArray array];
    releases = [NSMutableDictionary dictionary];
    
    struct cardSetData* c = cardSetData;
    while (c->setNum > 0)
    {
        CardSets* csd = [CardSets new];
        csd.setNum = c->setNum;
        csd.setCode = [NSString stringWithUTF8String:c->setCode];
        csd.settingsKey = [NSString stringWithUTF8String:c->settingsKey];
        csd.setName = [NSString stringWithUTF8String:c->setName];
        csd.cycle = c->cycle;
        csd.released = c->released;
        
        [releases setObject:@(csd.setNum) forKey:csd.setCode];
        
        [cardSets addObject:csd];
        ++c;
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
            [sets removeObject:cs.setName];
        }
    }
    
    return sets;
}

+(TableData*) allSetsForTableview
{
    NSArray* sections = @[ @"", @"Core / Deluxe", @"Genesis Cycle", @"Spin Cycle", @"Lunar Cycle" ];
    NSArray* sets = @[
        @[ kANY ],
        @[ @"Core Set", @"Creation and Control", @"Honor and Profit" ],
        @[ @"What Lies Ahead", @"Trace Amount", @"Cyber Exodus", @"A Study in Static", @"Humanity's Shadow", @"Future Proof",  ],
        @[ @"Opening Moves", @"Second Thoughts", @"Mala Tempora", @"True Colors", @"Fear and Loathing", @"Double Time", ],
        @[ @"Upstalk" ]
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
            return cs.setName;
        }
    }
    return nil;
}

@end
