//
//  CardManager.m
//  NRDB
//
//  Created by Gereon Steffens on 22.06.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "CardManager.h"
#import "SettingsKeys.h"
#import "Faction.h"
#import "CardSets.h"
#import "CardType.h"

@implementation CardManager

static NSMutableArray* allRunnerCards;          // all non-identity runner cards
static NSMutableArray* allCorpCards;            // all non-identity corp cards
static NSMutableArray* allRunnerIdentities;     // all runner ids
static NSMutableArray* allCorpIdentities;       // all corp ids

static NSArray* subtypes;       // array[role] of dictionary type->array
static NSArray* sortedSubtypes; // array[role] of dictionary type->array
static NSArray* subtypeCodes;   // array of array
static NSMutableArray* sortedIdentities;

static NSMutableDictionary* allCards;   // code -> card
static NSMutableDictionary* altCards;   // code -> alt art card
static NSMutableDictionary* altCardMap; // card code -> alt art card code
static int maxMU;
static int maxStrength;
static int maxRunnerCost;
static int maxCorpCost;
static int maxInf;
static int maxAgendaPoints;

+(void) initialize
{
    allCards = [NSMutableDictionary dictionary];
    altCards = [NSMutableDictionary dictionary];
    altCardMap = [NSMutableDictionary dictionary];
    
    allRunnerCards = [NSMutableArray array];
    allCorpCards = [NSMutableArray array];
    
    allRunnerIdentities = [NSMutableArray array];
    allCorpIdentities = [NSMutableArray array];
    
    subtypes = @[ [NSMutableDictionary dictionary], [NSMutableDictionary dictionary] ];
    sortedSubtypes = @[ [NSMutableDictionary dictionary], [NSMutableDictionary dictionary] ];
    sortedIdentities = [@[ [NSMutableArray array], [NSMutableArray array] ] mutableCopy];
    subtypeCodes = @[ [NSMutableArray array], [NSMutableArray array] ];
}

+(Card*) cardByCode:(NSString*)code
{
    return [allCards objectForKey:code];
}

+(Card*) altCardFor:(NSString *)code
{
    NSString* altCode = [altCardMap objectForKey:code];
    return [altCards objectForKey:altCode];
}

+(NSArray*) altCards
{
    return [altCards allValues];
}

+(NSArray*) allCards
{
    NSMutableArray* cards = [NSMutableArray array];
    [cards addObjectsFromArray:[CardManager allForRole:NRRoleRunner]];
    [cards addObjectsFromArray:[CardManager allForRole:NRRoleCorp]];
    [cards addObjectsFromArray:[CardManager identitiesForRole:NRRoleRunner]];
    [cards addObjectsFromArray:[CardManager identitiesForRole:NRRoleCorp]];
    
    return [cards sortedArrayUsingComparator:^(Card* c1, Card *c2) {
        NSUInteger l1 = c1.name.length;
        NSUInteger l2 = c2.name.length;
        if (l1 > l2)
        {
            return NSOrderedAscending;
        }
        else if (l1 < l2)
        {
            return NSOrderedDescending;
        }
        return NSOrderedSame;
    }];
}

+(NSArray*) allForRole:(NRRole)role
{
    return role == NRRoleRunner ? allRunnerCards : allCorpCards;

}

+(NSArray*) identitiesForRole:(NRRole)role
{
    return role == NRRoleRunner ? allRunnerIdentities : allCorpIdentities;
}

+(NSArray*) allRunnerCards
{
    return allRunnerCards;
}

+(NSArray*) allCorpCards
{
    return allCorpCards;
}

#pragma mark subtypes

+(NSArray*) subtypesForRole:(NRRole)role andType:(NSString*)type
{
    NSMutableArray* sorted = sortedSubtypes[role][type];
    
    if (sorted.count == 0)
    {
        NSArray* arr = subtypes[role][type];
        
        sorted = [[arr sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] mutableCopy];
        [sorted insertObject:kANY atIndex:0];
        sortedSubtypes[role][type] = sorted;
    }
    
    return sorted;
}

+(NSArray*) subtypesForRole:(NRRole)role andTypes:(NSSet*)types
{
    NSMutableSet* subtypes = [NSMutableSet set];
    for (NSString* type in types)
    {
        NSMutableArray* arr = [NSMutableArray arrayWithArray:[CardManager subtypesForRole:role andType:type]];
        [arr removeObjectAtIndex:0]; // remove "Any" entry
        [subtypes addObjectsFromArray:arr];
    }
    
    NSMutableArray* result = [[[subtypes allObjects] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] mutableCopy];
    [result insertObject:kANY atIndex:0];
    return result;
}

#pragma mark initalization

+(BOOL) cardsAvailable
{
    return allRunnerCards.count > 0 && allCorpCards.count > 0;
}

+(NSString*) filenameForLanguage:(NSString*)language
{
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentsDirectory = [paths objectAtIndex:0];
    NSString* filename = [NSString stringWithFormat:@"nrcards_%@.json", language];
    
    return [documentsDirectory stringByAppendingPathComponent:filename];
}

+(void) removeFiles
{
    NSString* language = [[NSUserDefaults standardUserDefaults] objectForKey:LANGUAGE];
    NSFileManager* fileMgr = [NSFileManager defaultManager];
    [fileMgr removeItemAtPath:[CardManager filenameForLanguage:language] error:nil];
    [fileMgr removeItemAtPath:[CardManager filenameForLanguage:@"en"] error:nil];
    
    [CardManager initialize];
}

+(BOOL) setupFromFiles
{
    NSString* language = [[NSUserDefaults standardUserDefaults] objectForKey:LANGUAGE];
    NSString* cardsFile = [CardManager filenameForLanguage:language];
    
    NSFileManager* fileMgr = [NSFileManager defaultManager];
    if ([fileMgr fileExistsAtPath:cardsFile])
    {
        NSArray* data = [NSArray arrayWithContentsOfFile:cardsFile];
        BOOL ok = NO;
        if (data)
        {
            ok = [self setupFromJsonData:data];
        }
        
        if (![language isEqualToString:@"en"])
        {
            cardsFile = [CardManager filenameForLanguage:@"en"];
            if ([fileMgr fileExistsAtPath:cardsFile])
            {
                data = [NSArray arrayWithContentsOfFile:cardsFile];
                [CardManager addEnglishNames:data];
            }
        }
        else
        {
            [CardManager addEnglishNames:nil];
        }
        return ok;
    }
    return NO;
}

+(BOOL) setupFromNetrunnerDbApi:(NSArray*)json
{
    NSString* language = [[NSUserDefaults standardUserDefaults] objectForKey:LANGUAGE];
    NSString* cardsFile = [CardManager filenameForLanguage:language];
    [json writeToFile:cardsFile atomically:YES];
    
    NSDateFormatter *fmt = [NSDateFormatter new];
    [fmt setDateStyle:NSDateFormatterShortStyle]; // e.g. 08.10.2008 for locale=de
    [fmt setTimeStyle:NSDateFormatterNoStyle];
    NSDate* now = [NSDate date];
    [[NSUserDefaults standardUserDefaults] setObject:[fmt stringFromDate:now] forKey:LAST_DOWNLOAD];
    
    NSDate* next = [NSDate dateWithTimeIntervalSinceNow:7*24*60*60];
    [[NSUserDefaults standardUserDefaults] setObject:[fmt stringFromDate:next] forKey:NEXT_DOWNLOAD];
    
    [CardManager initialize];
    return [self setupFromJsonData:json];
}

+(void) addEnglishNames:(NSArray *)json
{
    if (json == nil)
    {
        // we already have the english names, just copy them over
        for (Card* c in [allCards allValues])
        {
            c.name_en = c.name;
        }
    }
    else
    {
        NSString* cardsFile = [CardManager filenameForLanguage:@"en"];
        [json writeToFile:cardsFile atomically:YES];
        
        for (NSDictionary* obj in json)
        {
            NSString* code = [obj objectForKey:@"code"];
            NSString* name = [obj objectForKey:@"title"];
            
            Card* c = [allCards objectForKey:code];
            c.name_en = name;
        }
    }
    
    // now that we have english names for everything, map the alt-art cards to the regular cards
    NSArray* cards = [allCards allValues];
    for (Card* altCard in [altCards allValues])
    {
        for (Card* card in cards)
        {
            if ([altCard.name_en isEqualToString:card.name_en])
            {
                [altCardMap setObject:altCard.code forKey:card.code];
            }
        }
    }
}

+(BOOL) setupFromJsonData:(NSArray*)json
{
    if (json)
    {
        for (NSDictionary* obj in json)
        {
            Card* card = [Card cardFromJson:obj];
            NSAssert(card.isValid, @"invalid card from %@", obj);
            [CardManager addCard:card];
        }
        
        NSArray* cards = [allCards allValues];
        [Faction initializeFactionNames:cards];
        [CardSets initializeSetNames:cards];
        [CardType initializeCardTypes:cards];
        
        // sort identities by faction and name
        for (NSMutableArray* arr in @[ allRunnerIdentities, allCorpIdentities ])
        {
            [arr sortUsingComparator:^(Card* c1, Card* c2) {
                if (c1.faction > c2.faction) {
                    return NSOrderedDescending;
                }
            
                if (c1.faction < c2.faction) {
                    return NSOrderedAscending;
                }
                return [c1.name compare:c2.name];
            }];
        }
        
        return YES;
    }
    else
    {
        return NO;
    }
}

+(void) addCard:(Card*)card
{
    // alt art card?
    if ([card.setCode isEqualToString:@"alt"])
    {
        [altCards setObject:card forKey:card.code];
        return;
    }
    
    // add to dictionaries/arrays
    [allCards setObject:card forKey:card.code];
    
    if (card.type == NRCardTypeIdentity)
    {
        NSMutableArray* arr = card.role == NRRoleRunner ? allRunnerIdentities : allCorpIdentities;
        [arr addObject:card];
    }
    else
    {
        NSMutableArray* arr = card.role == NRRoleRunner ? allRunnerCards : allCorpCards;
        [arr addObject:card];
    }
    
    // calculate max values for filter sliders
    maxMU = MAX(card.mu, maxMU);
    maxStrength = MAX(card.strength, maxStrength);
    maxInf = MAX(card.influence, maxInf);
    maxAgendaPoints = MAX(card.agendaPoints, maxAgendaPoints);
    if (card.role == NRRoleRunner)
    {
        maxRunnerCost = MAX(card.cost, maxRunnerCost);
    }
    else
    {
        maxCorpCost = MAX(card.cost, maxCorpCost);
    }
    
    // fill subtypes per role
    if (card.subtype && card.type != NRCardTypeIdentity)
    {
        // NSLog(@"%@", c.subtype);
        NSMutableDictionary* dict = subtypes[card.role];
        
        if (dict[card.typeStr] == nil)
        {
            dict[card.typeStr] = [NSMutableArray array];
        }
        if (dict[kANY] == nil)
        {
            dict[kANY] = [NSMutableArray array];
        }
        for (NSString* st in card.subtypes)
        {
            for (NSMutableArray* arr in @[ dict[card.typeStr], dict[kANY]])
            {
                if (![arr containsObject:st])
                {
                    [arr addObject:st];
                }
            }
        }
    }
    
    // fill subtype codes per role
    if (card.subtypeCode && card.type != NRCardTypeIdentity)
    {
        NSMutableArray* arr = subtypeCodes[card.role];
        for (NSString* st in card.subtypeCodes)
        {
            if (![arr containsObject:st])
            {
                [arr addObject:st];
            }
        }
    }
}

#pragma mark max values

+(int) maxMU { return maxMU; }
+(int) maxStrength { return maxStrength; }
+(int) maxInfluence { return maxInf; }
+(int) maxRunnerCost { return maxRunnerCost; }
+(int) maxCorpCost { return maxCorpCost; }
+(int) maxAgendaPoints { return maxAgendaPoints; }

@end
