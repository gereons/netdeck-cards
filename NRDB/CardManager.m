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
#import "ImageCache.h"

@implementation CardManager

static NSMutableArray* allRunnerCards;          // all non-identity runner cards
static NSMutableArray* allCorpCards;            // all non-identity corp cards
static NSMutableArray* allRunnerIdentities;     // all runner ids
static NSMutableArray* allCorpIdentities;       // all corp ids

static NSArray* subtypes;       // array[role] of dictionary type->array
static NSArray* identitySubtypes; // array[role] of set of strings
static NSString* identityKey;

static NSMutableArray* sortedIdentities;

static NSMutableDictionary* allCards;   // code -> card

static int maxMU;
static int maxStrength;
static int maxRunnerCost;
static int maxCorpCost;
static int maxInf;
static int maxAgendaPoints;
static int maxTrash;
static NSString* iceBreakerType;

static BOOL initializing;

+(void) initialize
{
    allCards = [NSMutableDictionary dictionary];
    
    allRunnerCards = [NSMutableArray array];
    allCorpCards = [NSMutableArray array];
    
    allRunnerIdentities = [NSMutableArray array];
    allCorpIdentities = [NSMutableArray array];
    
    subtypes = @[ [NSMutableDictionary dictionary], [NSMutableDictionary dictionary] ];
    identitySubtypes = @[ [NSMutableSet set], [NSMutableSet set] ];
    sortedIdentities = [@[ [NSMutableArray array], [NSMutableArray array] ] mutableCopy];
    
    iceBreakerType = l10n(@"Icebreaker");
    
    initializing = NO;
}

+(Card*) cardByCode:(NSString*)code
{
    return [allCards objectForKey:code];
}

+(NSArray*) allCards
{
    NSMutableArray* cards = allCards.allValues.mutableCopy;

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

+(NSMutableArray*) subtypesForRole:(NRRole)role andType:(NSString*)type includeIdentities:(BOOL)includeIds
{
    NSMutableArray* arr = [NSMutableArray arrayWithArray:subtypes[role][type]];
    
    includeIds = includeIds && ([type isEqualToString:kANY] || [type isEqualToString:identityKey]);
    if (includeIds)
    {
        if (!arr)
        {
            arr = [NSMutableArray array];
        }
        NSSet* set = identitySubtypes[role];
        for (NSString* s in set)
        {
            [arr addObject:s];
        }
    }
    
    if (arr)
    {
        [arr sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
        return arr;
    }
    return nil;
}

+(NSMutableArray*) subtypesForRole:(NRRole)role andTypes:(NSSet*)types includeIdentities:(BOOL)includeIds
{
    NSMutableSet* subtypes = [NSMutableSet set];
    for (NSString* type in types)
    {
        NSMutableArray* arr = [NSMutableArray arrayWithArray:[CardManager subtypesForRole:role andType:type includeIdentities:includeIds]];
        if (arr.count > 0)
        {
            [subtypes addObjectsFromArray:arr];
        }
    }
    
    return [[[subtypes allObjects] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] mutableCopy];
}

#pragma mark initalization

+(BOOL) cardsAvailable
{
    return allRunnerCards.count > 0 && allCorpCards.count > 0;
}

+(NSString*) filename
{
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString* documentsDirectory = [paths objectAtIndex:0];
    
    return [documentsDirectory stringByAppendingPathComponent:@"nrcards.json"];
}

+(void) removeFiles
{
    NSFileManager* fileMgr = [NSFileManager defaultManager];
    [fileMgr removeItemAtPath:[CardManager filename] error:nil];
    
    [CardManager initialize];
}

+(BOOL) setupFromFiles
{
    NSString* cardsFile = [CardManager filename];
    
    NSFileManager* fileMgr = [NSFileManager defaultManager];
    if ([fileMgr fileExistsAtPath:cardsFile])
    {
        NSArray* data = [NSArray arrayWithContentsOfFile:cardsFile];
        BOOL ok = NO;
        if (data)
        {
            initializing = YES;
            ok = [self setupFromJsonData:data];
            initializing = NO;
        }
        
        return ok;
    }
    return NO;
}

+(BOOL) setupFromNrdbApi:(NSArray*)json
{
    NSString* cardsFile = [CardManager filename];
    [json writeToFile:cardsFile atomically:YES];
    
    NSDateFormatter *fmt = [NSDateFormatter new];
    [fmt setDateStyle:NSDateFormatterShortStyle]; // e.g. 08.10.2008 for locale=de
    [fmt setTimeStyle:NSDateFormatterNoStyle];
    NSDate* now = [NSDate date];
    [[NSUserDefaults standardUserDefaults] setObject:[fmt stringFromDate:now] forKey:LAST_DOWNLOAD];
    
    NSDate* next = [NSDate dateWithTimeIntervalSinceNow:7*24*60*60];
    [[NSUserDefaults standardUserDefaults] setObject:[fmt stringFromDate:next] forKey:NEXT_DOWNLOAD];
    
    [CardManager initialize];
    initializing = YES;
    BOOL ok = [self setupFromJsonData:json];
    initializing = NO;
    return ok;
}

+(BOOL) setupFromJsonData:(NSArray*)json
{
    NSAssert(initializing, @"oops");
    
    if (json)
    {
        for (NSDictionary* obj in json)
        {
            Card* card = [Card cardFromJson:obj];
            if (card)
            {
                NSAssert(card.isValid, @"invalid card from %@", obj);
            
                [CardManager addCard:card];
            }
        }
        
        // add built-in draft IDs if not already present
        for (Card* c in [Card draftIds])
        {
            Card* c2 = [Card cardByCode:c.code];
            if (c2 == nil)
            {
                [CardManager addCard:c];
            }
        }
        
        NSArray* cards = [allCards allValues];
        [Faction initializeFactionNames:cards];
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
    NSAssert(initializing, @"oops");
    
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
    maxTrash = MAX(card.trash, maxTrash);
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
    if (card.subtype)
    {
        // NSLog(@"%@", card.subtype);
        if (card.type == NRCardTypeIdentity)
        {
            identityKey = card.typeStr;
            NSMutableSet* set = identitySubtypes[card.role];
            for (NSString* st in card.subtypes)
            {
                [set addObject:st];
            }
        }
        else
        {
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
    }
}

#pragma mark max values

+(int) maxMU { return maxMU; }
+(int) maxStrength { return maxStrength; }
+(int) maxInfluence { return maxInf; }
+(int) maxRunnerCost { return maxRunnerCost; }
+(int) maxCorpCost { return maxCorpCost; }
+(int) maxAgendaPoints { return maxAgendaPoints; }
+(int) maxTrash { return maxTrash; }

+(NSString*) iceBreakerType { return iceBreakerType; }

@end
