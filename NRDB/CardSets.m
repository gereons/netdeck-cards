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

@interface CardSet : NSObject
@property NSString* name;
@property int setNum;
@property NSString* setCode;
@property NSString* settingsKey;
@property NRCycle cycle;
@property BOOL released;
@end
@implementation CardSet
@end

@implementation CardSets

static NSMutableArray* cardSets;
static NSMutableDictionary* releases;
static NSMutableDictionary* setNames;
static NSArray* setGroups;
static NSArray* setsPerGroup;
static NSMutableSet* newSetCodes;
static NSSet* disabledSets;

static struct cardSetData {
    int setNum;
    char* nrdbCode;
    NRCycle cycle;
    BOOL released;
} cardSetData[] = {
    {  1, "core", NRCycleCoreDeluxe, YES },
    
    // genesis
    { 2, "wla", NRCycleGenesis, YES },
    { 3, "ta", NRCycleGenesis, YES },
    { 4, "ce", NRCycleGenesis, YES },
    { 5, "asis", NRCycleGenesis, YES },
    { 6, "hs", NRCycleGenesis, YES },
    { 7, "fp", NRCycleGenesis, YES },
    // c&c
    { 8, "cac", NRCycleCoreDeluxe, YES },
    
    // spin
    {  9, "om", NRCycleSpin, YES },
    { 10, "st", NRCycleSpin, YES},
    { 11, "mt", NRCycleSpin, YES },
    { 12, "tc", NRCycleSpin, YES },
    { 13, "fal", NRCycleSpin, YES },
    { 14, "dt", NRCycleSpin, YES },
    // h&p
    { 15, "hap", NRCycleCoreDeluxe, YES },
    
    // lunar
    { 16, "up", NRCycleLunar, YES },
    { 17, "tsb", NRCycleLunar, YES },
    { 18, "fc", NRCycleLunar, YES },
    { 19, "uao", NRCycleLunar, YES },
    { 20, "atr", NRCycleLunar, YES },
    { 21, "ts", NRCycleLunar, YES },
    // o&c
    { 22, "oac", NRCycleCoreDeluxe, YES },
    
    // sansan
    { 23, "val", NRCycleSanSan, NO },
    { 24, "bb", NRCycleSanSan, NO },
    { 25, "cc", NRCycleSanSan, NO },
    { 26, "uw", NRCycleSanSan, NO },
    // { 27, "", NRCycleSanSan, NO },
    // { 28, "", NRCycleSanSan, NO },
    
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
        CardSet* cs = [CardSet new];
        cs.setNum = c->setNum;
        NSString* nrdbCode = [NSString stringWithUTF8String:c->nrdbCode];
        cs.setCode = nrdbCode;
        cs.settingsKey = [NSString stringWithFormat:@"use_%@", nrdbCode];
        cs.cycle = c->cycle;
        cs.released = c->released;
        
        [releases setObject:@(cs.setNum) forKey:cs.setCode];
        [cardSets addObject:cs];
        ++c;
    }
    
    setGroups = @[ @"", l10n(@"Core / Deluxe"), l10n(@"Cycle #1"), l10n(@"Cycle #2"), l10n(@"Cycle #3"), l10n(@"Cycle #4") ];
    setsPerGroup = @[
        @[  @0 ],
        @[  @1,  @8, @15, @22 ],
        @[  @2,  @3,  @4,  @5,  @6,  @7 ],
        @[  @9, @10, @11, @12, @13, @14 ],
        @[ @16, @17, @18, @19, @20, @21 ],
        @[ @23, @24, @25, @26 /*, @27, @28 */ ]
    ];
    
    NSAssert(setGroups.count == setsPerGroup.count, @"set group mismatch");
}

+(NSString*) filename
{
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString* documentsDirectory = [paths objectAtIndex:0];
    
    return [documentsDirectory stringByAppendingPathComponent:@"nrsets.json"];
}

+(void) removeFiles
{
    NSFileManager* fileMgr = [NSFileManager defaultManager];
    [fileMgr removeItemAtPath:[CardSets filename] error:nil];
    
    [CardManager initialize];
}

+(BOOL) setupFromFiles
{
    NSString* setsFile = [CardSets filename];
    
    NSFileManager* fileMgr = [NSFileManager defaultManager];
    if ([fileMgr fileExistsAtPath:setsFile])
    {
        NSArray* data = [NSArray arrayWithContentsOfFile:setsFile];
        BOOL ok = NO;
        if (data)
        {
            ok = [self setupFromJsonData:data];
        }
        
        return ok;
    }
    return NO;
}

+(BOOL) setupFromNrdbApi:(NSArray *)json
{
    NSString* cardsFile = [CardSets filename];
    [json writeToFile:cardsFile atomically:YES];
    
    return [self setupFromJsonData:json];
}

+(BOOL) setupFromJsonData:(NSArray*)json
{
    int maxCycle = 0;
    NSMutableArray* cardSets = [NSMutableArray array];
    for (NSDictionary* set in json)
    {
        CardSet* cs = [CardSet new];
        
        cs.setCode = set[@"code"];
        if ([cs.setCode isEqualToString:SPECIAL_SET])
        {
            continue;
        }
        cs.name = set[@"name"];
        cs.settingsKey = [NSString stringWithFormat:@"use_%@", cs.setCode];

        NSNumber* cycleNumber = set[@"cyclenumber"];
        int cycle = cycleNumber.intValue;
        
        if ((cycle % 2) == 0)
        {
            cs.cycle = cycle / 2;
            maxCycle = MAX(cs.cycle, maxCycle);
            NSNumber* number = set[@"number"];
            cs.setNum = (cycle-2) / 2 * 7 + 1 + number.intValue;
        }
        else
        {
            cs.cycle = NRCycleCoreDeluxe;
            cs.setNum = (cycle-1) / 2 * 7 + 1;
        }
        NSString* available = set[@"available"];
        cs.released = available.length > 0;
    
        [cardSets addObject:cs];
    }
    
    [cardSets sortUsingComparator:^NSComparisonResult(CardSet* cs1, CardSet* cs2) {
        return [@(cs1.setNum) compare:@(cs2.setNum)];
    }];
    
    for (CardSet* cs in cardSets)
    {
        NSLog(@"%@ %d %d %@ %d", cs.name, cs.setNum, cs.cycle, cs.settingsKey, cs.released);
    }
    
    /*
     setGroups = @[ @"", l10n(@"Core / Deluxe"), l10n(@"Cycle #1"), l10n(@"Cycle #2"), l10n(@"Cycle #3"), l10n(@"Cycle #4") ];
    setsPerGroup = @[
                     @[  @0 ],
                     @[  @1,  @8, @15, @22 ],
                     @[  @2,  @3,  @4,  @5,  @6,  @7 ],
                     @[  @9, @10, @11, @12, @13, @14 ],
                     @[ @16, @17, @18, @19, @20, @21 ],
                     @[ @23, @24, @25, @26
                     ];
    */
    
    NSMutableArray* setGroups = [NSMutableArray array];
    NSMutableArray* setsPerGroup = [NSMutableArray array];
    [setsPerGroup addObject:@[ @0 ]];
    for (int i=0; i<=maxCycle; ++i)
    {
        [setsPerGroup addObject:[NSMutableArray array]];
    }
    
    for (CardSet* cs in cardSets)
    {
        NSMutableArray* arr = setsPerGroup[cs.cycle+1];
        [arr addObject:@(cs.setNum)];
        
        if (cs.cycle > setGroups.count)
        {
            NSString* cycle = [NSString stringWithFormat:@"Cycle #%d", cs.cycle];
            [setGroups addObject:l10n(cycle)];
        }
    }
    [setGroups insertObject:@"" atIndex:0];
    [setGroups insertObject:l10n(@"Core / Deluxe") atIndex:1];
    
    NSAssert(setGroups.count == setsPerGroup.count, @"count mismatch");
    return YES;
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
    for (CardSet* cs in cardSets)
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
    for (CardSet* cs in cardSets)
    {
        [dict setObject:@(cs.released) forKey:cs.settingsKey];
    }
    return dict;
}

+(int) setNumForCode:(NSString*)code
{
    NSNumber* n = [releases objectForKey:code];
    return [n intValue];
}

+(NSSet*) disabledSetCodes
{
    if (disabledSets == nil)
    {
        NSMutableSet* sets = [NSMutableSet set];
        NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
        for (CardSet* cs in cardSets)
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
        disabledSets = sets;
    }
    
    return disabledSets;
}

+(void) clearDisabledSets
{
    disabledSets = nil;
}

+(NSSet*) knownSetCodes
{
    NSMutableSet* knownSets = [NSMutableSet set];
    for (CardSet* cs in cardSets)
    {
        [knownSets addObject:cs.setCode];
    }
    [knownSets addObject:DRAFT_SET_CODE];
    
    return knownSets;
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
                CardSet* cs = [cardSets objectAtIndex:setNum-1];
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

    for (CardSet* cs in cardSets)
    {
        if (cs.setNum == maxRelease)
        {
            return [setNames objectForKey:cs.setCode];
        }
    }
    return @"?";
}

@end
