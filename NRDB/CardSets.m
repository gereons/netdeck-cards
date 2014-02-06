//
//  CardSets.m
//  NRDB
//
//  Created by Gereon Steffens on 14.12.13.
//  Copyright (c) 2013 Gereon Steffens. All rights reserved.
//

#import "CardSets.h"
#import "CardData.h"

@interface CardSets()
@property NSString* setCode;
@property NSString* settingsKey;
@property NSString* setName;
@property NRCycle cycle;
@end

@implementation CardSets

static NSMutableArray* cardSets;

static struct cardSetData {
    char* settingsKey;
    char* setCode;
    char* setName;
    NRCycle cycle;
} cardSetData[] = {
    { "use_coreset", "core", "Core Set", NRCycleCoreDeluxe },
    { "use_creation_and_control", "cac", "Creation and Control", NRCycleCoreDeluxe },
    { "use_honor_and_profit", "hap", "Honor and Profit", NRCycleCoreDeluxe },
    
    // genesis
    { "use_what_lies_ahead", "wla", "What Lies Ahead", NRCycleGenesis },
    { "use_trace_amount", "ta", "Trace Amount", NRCycleGenesis },
    { "use_cyber_exodus", "ce", "Cyber Exodus", NRCycleGenesis },
    { "use_study_in_static", "asis", "A Study in Static", NRCycleGenesis },
    { "use_humanitys_shadow", "hs", "Humanity's Shadow", NRCycleGenesis },
    { "use_future_proof", "fp", "Future Proof", NRCycleGenesis },
    
    // spin
    { "use_opening_moves", "om", "Opening Moves", NRCycleSpin },
    { "use_second_thoughts", "st", "Second Thoughts", NRCycleSpin },
    { "use_mala_tempora", "mt", "Mala Tempora", NRCycleSpin },
    { "use_true_colors", "tc", "True Colors", NRCycleSpin },
    { "use_fear_and_loathing", "fal", "Fear and Loathing", NRCycleSpin },
    { "use_double_time", "dt", "Double Time", NRCycleSpin },
    
    // lunar
    { "use_upstalk", "up", "Upstalk", NRCycleLunar },
    { 0 }
};

+(void) initialize
{
    cardSets = [NSMutableArray array];
    struct cardSetData* c = cardSetData;
    while (c->settingsKey != 0)
    {
        CardSets* csd = [CardSets new];
        csd.setCode = [NSString stringWithUTF8String:c->setCode];
        csd.settingsKey = [NSString stringWithUTF8String:c->settingsKey];
        csd.setName = [NSString stringWithUTF8String:c->setName];
        csd.cycle = c->cycle;
        
        [cardSets addObject:csd];
        ++c;
    }
}

+(NSDictionary*) settingsDefaults
{
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    for (CardSets* cs in cardSets)
    {
        [dict setObject:@(YES) forKey:cs.settingsKey];
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

@end
