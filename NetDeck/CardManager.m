//
//  CardManager.m
//  Net Deck
//
//  Created by Gereon Steffens on 22.06.14.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

#import "CardManager.h"
#import "SettingsKeys.h"
#import "CardSets.h"
#import "ImageCache.h"
#import "AppDelegate.h"
#import <DTCoreText.h>

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

static NSDictionary* cardAliases;   // code -> alias

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
    
    cardAliases = @{
        @"08034": @"Franklin",  // crick
        @"02085": @"HQI",       // hq interface
        @"02107": @"RDI",       // r&d interface
        @"06033": @"David",     // d4v1d
        @"05039": @"SW35",      // unreg. s&w '35
        @"03035": @"LARLA",     // levy ar lab access
        @"04029": @"PPVP",      // prepaid voicepad
        @"01092": @"SSCG",      // sansan city grid
        @"04034": @"SFSS",      // shipment from sansan
        @"03049": @"ProCo",     // professional contacts
        @"02079": @"OAI",       // oversight AI
        @"08009": @"Baby",      // symmetrical visage
        @"08003": @"Pancakes",  // adjusted chronotype
        @"09022": @"ASI",       // the all-seeing i
    };
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
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString* supportDirectory = [paths objectAtIndex:0];
    
    return [supportDirectory stringByAppendingPathComponent:CARDS_FILENAME];
}

+(NSString*) filenameEn
{
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString* supportDirectory = [paths objectAtIndex:0];
    
    return [supportDirectory stringByAppendingPathComponent:CARDS_FILENAME_EN];
}

+(void) removeFiles
{
    NSFileManager* fileMgr = [NSFileManager defaultManager];
    [fileMgr removeItemAtPath:[CardManager filename] error:nil];
    [fileMgr removeItemAtPath:[CardManager filenameEn] error:nil];
    
    [CardManager initialize];
}

+(BOOL) setupFromFiles
{
    NSString* cardsFile = [CardManager filename];
    NSString* cardsEnFile = [CardManager filenameEn];
    BOOL ok = NO;
    
    NSFileManager* fileMgr = [NSFileManager defaultManager];
    if ([fileMgr fileExistsAtPath:cardsFile])
    {
        NSArray* data = [NSArray arrayWithContentsOfFile:cardsFile];
        if (data)
        {
            ok = [self setupFromJsonData:data];
        }
    }
    
    if (ok && [fileMgr fileExistsAtPath:cardsEnFile])
    {
        NSArray* data = [NSArray arrayWithContentsOfFile:cardsEnFile];
        if (data)
        {
            [self addAdditionalNames:data saveFile:NO];
        }
    }
    
    return ok;
}

+(BOOL) setupFromNrdbApi:(NSArray*)json
{
    [CardManager setNextDownloadDate];
    
    NSString* cardsFile = [CardManager filename];
    [json writeToFile:cardsFile atomically:YES];
    [AppDelegate excludeFromBackup:cardsFile];
    
    [CardManager initialize];
    return [self setupFromJsonData:json];
}

+(void) setNextDownloadDate
{
    NSDateFormatter *fmt = [NSDateFormatter new];
    [fmt setDateStyle:NSDateFormatterShortStyle]; // e.g. 08.10.2008 for locale=de
    [fmt setTimeStyle:NSDateFormatterNoStyle];
    NSDate* now = [NSDate date];
    
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    [settings setObject:[fmt stringFromDate:now] forKey:LAST_DOWNLOAD];
    
    NSInteger interval = [settings integerForKey:UPDATE_INTERVAL];

    NSString* nextDownload;
    switch (interval)
    {
        case 30: {
            NSCalendar *cal = [NSCalendar currentCalendar];
            NSDate *next = [cal dateByAddingUnit:NSCalendarUnitMonth value:1 toDate:[NSDate date] options:0];
            nextDownload = [fmt stringFromDate:next];
            break;
        }
        case 0:
            nextDownload = l10n(@"never");
            break;
        default: {
            NSDate* next = [NSDate dateWithTimeIntervalSinceNow:interval*24*60*60];
            nextDownload = [fmt stringFromDate:next];
            break;
        }
    }
    
    [settings setObject:nextDownload forKey:NEXT_DOWNLOAD];
}

+(void) addAdditionalNames:(NSArray *)json saveFile:(BOOL)saveFile
{
    // add english names from json
    if (saveFile)
    {
        NSString* cardsFile = [CardManager filenameEn];
        [json writeToFile:cardsFile atomically:YES];
        
        [AppDelegate excludeFromBackup:cardsFile];
    }
    
    for (NSDictionary* obj in json)
    {
        NSString* code = obj[@"code"];
        NSString* name_en = obj[@"title"];
        NSString* subtype = obj[@"subtype"];
        
        Card* card = [Card cardByCode:code];
        if (card)
        {
            card.name_en = [name_en stringByReplacingHTMLEntities];
            [card setAlliance:subtype];
            [card setVirtual:subtype];
        }
    }
    
    // add automatic aliases like "Self Modifying Code" -> "SMC"
    for (Card* card in allCards.allValues)
    {
        NSString* regexPattern = @"^|[- ]\\w";
        NSRegularExpression* regex = [[NSRegularExpression alloc] initWithPattern:regexPattern options:0 error:nil];
        
        NSMutableString* alias = [NSMutableString string];
        NSArray* matches = [regex matchesInString:card.name options:0 range:NSMakeRange(0, card.name.length)];
        for (NSTextCheckingResult* match in matches)
        {
            NSRange range = match.range;
            range.length = 1;
            if (range.location > 0)
            {
                range.location++;
            }
            NSString* ch = [card.name substringWithRange:range];
            [alias appendString:ch];
        }
        
        if (card.name.length > 2 && alias.length > 1)
        {
            card.alias = alias;
        }
        
        // NSLog(@"%@ -> %@", card.name, alias);
    }
    
    // add hard-coded aliases
    for (NSString* code in cardAliases.allKeys)
    {
        Card* card = [Card cardByCode:code];
        card.alias = [cardAliases objectForKey:code];
    }
}

+(BOOL) setupFromJsonData:(NSArray*)json
{
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

@end
