//
//  CardData.m
//  NRDB
//
//  Created by Gereon Steffens on 09.12.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <AFNetworking.h>

#import "Card.h"
#import "CardData.h"
#import "Faction.h"
#import "CardType.h"
#import "CardSets.h"
#import "SettingsKeys.h"

#define JSON_INT(key, attr)          do { NSString*tmp = [json objectForKey:attr]; c->_##key = tmp ? [tmp intValue] : -1; } while (0)
#define JSON_BOOL(key, attr)         c->_##key = [[json objectForKey:attr] boolValue]
#define JSON_STR(key, attr)          c->_##key = [json objectForKey:attr]

@implementation CardData

static NSDictionary* roleCodes;

static NSArray* subtypes;       // array of dictionary type->array
static NSArray* sortedSubtypes; // array of dictionary type->array
static NSArray* subtypeCodes;   // array of array
static NSMutableArray* sortedIdentities;

static NSMutableDictionary* allCards;   // code -> card
static NSMutableDictionary* altCards;   // name -> card (!)
static NSMutableDictionary* altCardMap; // code -> code
static NSMutableArray* allRunnerCards;
static NSMutableArray* allCorpCards;
static NSMutableArray* allIdentities;

static NSMutableSet* allSets;
static NSArray* max1InDeck;
static NSArray* specialIds;

static int maxMU;
static int maxStrength;
static int maxRunnerCost;
static int maxCorpCost;
static int maxInf;
static int maxAgendaPoints;

NSString* const kANY = @"Any";

+(void) initialize
{
    [CardData resetData];
    
    max1InDeck = @[ DIRECTOR_HAAS_PET_PROJ, PHILOTIC_ENTANGLEMENT,
                    UTOPIA_SHARD,
                    HADES_SHARD, HADES_FRAGMENT,
                    EDEN_SHARD, EDEN_FRAGMENT ];
    
    specialIds = @[ THE_SHADOW, THE_MASQUE, LARAMY_FISK, THE_COLLECTIVE, CHRONOS_PROTOCOL_HB, CHRONOS_PROTOCOL_JIN ];
}

+(void) resetData
{
    allCards = [NSMutableDictionary dictionary];
    altCards = [NSMutableDictionary dictionary];
    altCardMap = [NSMutableDictionary dictionary];
    
    allRunnerCards = [NSMutableArray array];
    allCorpCards = [NSMutableArray array];
    allIdentities = [@[ [NSMutableArray array], [NSMutableArray array] ] mutableCopy];
    
    subtypes = @[ [NSMutableDictionary dictionary], [NSMutableDictionary dictionary] ];
    sortedSubtypes = @[ [NSMutableDictionary dictionary], [NSMutableDictionary dictionary] ];
    sortedIdentities = [@[ [NSMutableArray array], [NSMutableArray array] ] mutableCopy];
    subtypeCodes = @[ [NSMutableArray array], [NSMutableArray array] ];
    allSets = [NSMutableSet set];

    roleCodes = @{ @"runner": @(NRRoleRunner), @"corp": @(NRRoleCorp) };
}

+(NSString*) filenameForLanguage:(NSString*)language
{
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentsDirectory = [paths objectAtIndex:0];
    NSString* filename = [NSString stringWithFormat:@"nrcards_%@.json", language];
    
    return [documentsDirectory stringByAppendingPathComponent:filename];
}

+(void) removeFile
{
    NSString* language = [[NSUserDefaults standardUserDefaults] objectForKey:LANGUAGE];
    NSFileManager* fileMgr = [NSFileManager defaultManager];
    [fileMgr removeItemAtPath:[CardData filenameForLanguage:language] error:nil];
    [fileMgr removeItemAtPath:[CardData filenameForLanguage:@"en"] error:nil];
    
    [CardData initialize];
}

+(BOOL) setupFromFile
{
    NSString* language = [[NSUserDefaults standardUserDefaults] objectForKey:LANGUAGE];
    NSString* cardsFile = [CardData filenameForLanguage:language];
    
    NSFileManager* fileMgr = [NSFileManager defaultManager];
    if ([fileMgr fileExistsAtPath:cardsFile])
    {
        [CardData resetData];
        NSArray* data = [NSArray arrayWithContentsOfFile:cardsFile];
        BOOL ok = NO;
        if (data)
        {
            ok = [self setupFromJsonData:data];
        }
        
        if (![language isEqualToString:@"en"])
        {
            cardsFile = [CardData filenameForLanguage:@"en"];
            if ([fileMgr fileExistsAtPath:cardsFile])
            {
                data = [NSArray arrayWithContentsOfFile:cardsFile];
                [CardData addEnglishNames:data];
            }
        }
        else
        {
            [CardData addEnglishNames:nil];
        }
        return ok;
    }
    return NO;
}

+(BOOL) setupFromNetrunnerDbApi:(NSArray*)array
{
    NSString* language = [[NSUserDefaults standardUserDefaults] objectForKey:LANGUAGE];
    NSString* cardsFile = [CardData filenameForLanguage:language];
    [array writeToFile:cardsFile atomically:YES];
    
    NSDateFormatter *fmt = [NSDateFormatter new];
    [fmt setDateStyle:NSDateFormatterShortStyle]; // e.g. 08.10.2008 for locale=de
    [fmt setTimeStyle:NSDateFormatterNoStyle];
    NSDate* now = [NSDate date];
    [[NSUserDefaults standardUserDefaults] setObject:[fmt stringFromDate:now] forKey:LAST_DOWNLOAD];
    
    NSDate* next = [NSDate dateWithTimeIntervalSinceNow:7*24*60*60];
    [[NSUserDefaults standardUserDefaults] setObject:[fmt stringFromDate:next] forKey:NEXT_DOWNLOAD];
    
    [CardData resetData];
    return [self setupFromJsonData:array];
}

+(void) addEnglishNames:(NSArray *)json
{
    if (json == nil)
    {
        // we already have the english names, just copy them over
        for (CardData* cd in [allCards allValues])
        {
            cd.name_en = cd.name;
        }
    }
    else
    {
        NSString* cardsFile = [CardData filenameForLanguage:@"en"];
        [json writeToFile:cardsFile atomically:YES];
        
        for (NSDictionary* obj in json)
        {
            NSString* code = [obj objectForKey:@"code"];
            NSString* name = [obj objectForKey:@"title"];
            
            CardData* cd = [allCards objectForKey:code];
            cd.name_en = name;
        }
    }
}

+(BOOL) setupFromJsonData:(NSArray*)json
{
    if (json)
    {
        for (NSDictionary* obj in json)
        {
            CardData* card = [CardData cardFromJson:obj];
            if (card)
            {
                [CardData addCard:card];
            }
        }
        
        // build the card-to-altcard mapping
        for (CardData* cd in [allCards allValues])
        {
            CardData* alt = [altCards objectForKey:cd.name];
            if (alt)
            {
                [altCardMap setObject:alt.code forKey:cd.code];
            }
        }
        
        [Faction initializeFactionNames:allCards];
        [CardSets initializeSetNames:allCards];
        [CardType initializeCardTypes:allCards];
        
        return YES;
    }
    else
    {
        return NO;
    }
}

+(CardData*) cardFromJson:(NSDictionary*)json
{
    CardData* c = [CardData new];
    
    JSON_STR(code, @"code");
    JSON_STR(name, @"title");
    JSON_STR(text, @"text");
    JSON_STR(flavor, @"flavor");
    JSON_STR(factionStr, @"faction");
    NSString* factionCode = [json objectForKey:@"faction_code"];
    c.faction = [Faction faction:factionCode];
    if (c.faction == NRFactionNone) NSLog(@"oops: %@", json);
    
    JSON_STR(roleStr, @"side");
    NSString* roleCode = [json objectForKey:@"side_code"];
    c.role = [[roleCodes objectForKey:roleCode] integerValue];
    if (c.role == NRRoleNone) NSLog(@"oops: %@", json);
    
    JSON_STR(typeStr, @"type");
    NSString* typeCode = [json objectForKey:@"type_code"];
    c.type = [CardType type:typeCode];
    if (c.type == NRCardTypeNone) NSLog(@"oops %@", json);
    
    JSON_STR(setCode, @"set_code");
    if ([c.setCode isEqualToString:@"special"] && ![specialIds containsObject:c.code])
    {
        return nil;
    }
    
    JSON_STR(setName, @"setname");
    [allSets addObject:c.setName];

    JSON_STR(subtype, @"subtype");
    if (c.subtype && c.type != NRCardTypeIdentity)
    {
        // NSLog(@"%@", c.subtype);
        c.subtypes = [c.subtype componentsSeparatedByString:@" - "];
        NSMutableDictionary* dict = subtypes[c.role];
        
        if (dict[c.typeStr] == nil)
        {
            dict[c.typeStr] = [NSMutableArray array];
        }
        if (dict[kANY] == nil)
        {
            dict[kANY] = [NSMutableArray array];
        }
        for (NSString* st in c.subtypes)
        {
            for (NSMutableArray* arr in @[ dict[c.typeStr], dict[kANY]])
            {
                if (![arr containsObject:st])
                {
                    [arr addObject:st];
                }
            }
        }
    }
    c.subtypeCode = [json objectForKey:@"subtype_code"];
    if (c.subtype.length == 0)
    {
        c->_subtypeCode = nil;
    }
    if (c.subtypeCode && c.type != NRCardTypeIdentity)
    {
        c.subtypeCodes = [c.subtypeCode componentsSeparatedByString:@" - "];
        NSMutableArray* arr = subtypeCodes[c.role];
        for (NSString* st in c.subtypeCodes)
        {
            if (![arr containsObject:st])
            {
                [arr addObject:st];
            }
        }
    }
    
    JSON_INT(number, @"number");
    JSON_INT(quantity, @"quantity");
    JSON_BOOL(unique, @"uniqueness");
    JSON_BOOL(limited, @"limited");
    JSON_INT(influenceLimit, @"influencelimit");
    JSON_INT(minimumDecksize, @"minimumdecksize");
    JSON_INT(baseLink, @"baselink");
    JSON_INT(advancementCost, @"advancementcost");
    JSON_INT(agendaPoints, @"agendapoints");
    JSON_INT(mu, @"memoryunits");
    JSON_INT(strength, @"strength");
    JSON_INT(cost, @"cost");
    JSON_INT(influence, @"factioncost");
    JSON_INT(trash, @"trash");
    
    JSON_STR(url, @"url");
    JSON_STR(imageSrc, @"imagesrc");
    JSON_STR(artist, @"illustrator");
    c->_lastModified = [json objectForKey:@"last-modified"];
    
    maxMU = MAX(c.mu, maxMU);
    maxStrength = MAX(c.strength, maxStrength);
    maxInf = MAX(c.influence, maxInf);
    maxAgendaPoints = MAX(c.agendaPoints, maxAgendaPoints);
    if (c.role == NRRoleRunner)
    {
        maxRunnerCost = MAX(c.cost, maxRunnerCost);
    }
    else
    {
        maxCorpCost = MAX(c.cost, maxCorpCost);
    }
    
    c.maxCopies = 3;
    if ([max1InDeck containsObject:c.code] || c.limited || c.type == NRCardTypeIdentity)
    {
        c.maxCopies = 1;
    }
    
    // if this is an alt card, store it separately
    if ([c.setCode isEqualToString:@"alt"])
    {
        if (c.imageSrc.length > 0)
        {
            [altCards setObject:c forKey:c.name];
        }
        return nil;
    }

    return c;
}

+(void) addCard:(CardData*)c
{
    NSAssert(c != nil, @"invalid card");
    
    if (c.isValid)
    {
        [allCards setObject:c forKey:c.code];
        
        if (c.type == NRCardTypeIdentity)
        {
            NSMutableArray* arr = allIdentities[c.role];
            [arr addObject:c];
        }
        else
        {
            NSMutableArray* arr = c.role == NRRoleRunner ? allRunnerCards : allCorpCards;
            [arr addObject:c];
        }
    }
}

-(NSString*) name_en
{
    return self->_name_en ? self->_name_en : self->_name;
}

+(CardData*) cardByCode:(NSString *)code
{
    return [allCards objectForKey:code];
}

+(CardData*)altFor:(NSString *)name
{
    return [altCards objectForKey:name];
}

+(NSArray*) allRunnerCards
{
    return allRunnerCards;
}

+(NSArray*) allCorpCards
{
    return allCorpCards;
}

+(NSArray*) altCards
{
    return [altCards allValues];
}

+(BOOL) cardsAvailable
{
    return allRunnerCards.count > 0 && allCorpCards.count > 0;
}

+(NSArray*) identitiesForRole:(NRRole)role
{
    NSMutableArray* sorted = sortedIdentities[role];
    
    if (sorted.count == 0)
    {
        NSMutableArray* arr = allIdentities[role];
        
        sorted = [[arr sortedArrayUsingComparator:^(CardData* c1, CardData* c2) {
            
            if (c1.faction > c2.faction) {
                return NSOrderedDescending;
            }
            
            if (c1.faction < c2.faction) {
                return NSOrderedAscending;
            }
            return [c1.name compare:c2.name];
        }] mutableCopy];
        
        sortedIdentities[role] = sorted;
    }
    return sorted;
}

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
        NSMutableArray* arr = [NSMutableArray arrayWithArray:[CardData subtypesForRole:role andType:type]];
        [arr removeObjectAtIndex:0]; // remove "Any" entry
        [subtypes addObjectsFromArray:arr];
    }
    
    NSMutableArray* result = [[[subtypes allObjects] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] mutableCopy];
    [result insertObject:kANY atIndex:0];
    return result;
}

+(NSArray*) allSets
{
    static NSMutableArray* setsArray;
    
    if (setsArray == nil)
    {
        setsArray = [NSMutableArray array];
        [setsArray addObject:l10n(kANY)];
        NSArray* arr = [[allSets allObjects] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
        [setsArray addObjectsFromArray:arr];
    }
    return setsArray;
}

-(BOOL) isValid
{
    return self.code.length > 0 && self.name.length > 0 && self.faction != NRFactionNone && self.role != NRRoleNone;
}

+(int) maxMU { return maxMU; }
+(int) maxStrength { return maxStrength; }
+(int) maxInfluence { return maxInf; }
+(int) maxRunnerCost { return maxRunnerCost; }
+(int) maxCorpCost { return maxCorpCost; }
+(int) maxAgendaPoints { return maxAgendaPoints; }

#pragma mark NSObject

-(BOOL) isEqual:(id)object
{
    if (self == object) return YES;
    if (object == nil) return NO;
    CardData* c = (CardData*)object;
    return [self.code compare:c.code] == NSOrderedSame;
}

-(NSUInteger) hash
{
    return [self.code hash];
}

#pragma mark NSCoding

#define ENCODE_OBJ(attr) [coder encodeObject:self.attr forKey:@#attr]
#define ENCODE_INT(attr) [coder encodeInteger:self.attr forKey:@#attr]

-(void) encodeWithCoder:(NSCoder *)coder
{
    ENCODE_OBJ(code);
    ENCODE_OBJ(name);
    ENCODE_OBJ(name_en);
    ENCODE_OBJ(text);
    ENCODE_OBJ(flavor);
    ENCODE_OBJ(factionStr);
    ENCODE_INT(faction);
    ENCODE_OBJ(roleStr);
    ENCODE_INT(role);
    ENCODE_OBJ(typeStr);
    ENCODE_INT(type);
    ENCODE_OBJ(subtype);
    ENCODE_OBJ(subtypes);
    ENCODE_OBJ(subtypeCode);
    ENCODE_OBJ(subtypeCodes);
    ENCODE_OBJ(setName);
    ENCODE_OBJ(setCode);
    ENCODE_INT(number);
    ENCODE_INT(quantity);
    ENCODE_INT(unique);
    ENCODE_INT(influenceLimit);
    ENCODE_INT(minimumDecksize);
    ENCODE_INT(baseLink);
    ENCODE_INT(advancementCost);
    ENCODE_INT(agendaPoints);
    ENCODE_INT(strength);
    ENCODE_INT(mu);
    ENCODE_INT(cost);
    ENCODE_INT(trash);
    ENCODE_INT(influence);
    ENCODE_OBJ(url);
    ENCODE_OBJ(imageSrc);
    ENCODE_OBJ(artist);
    ENCODE_OBJ(lastModified);
}

#define DECODE_OBJ(attr) self.attr = [decoder decodeObjectForKey:@#attr]
#define DECODE_INT(attr) self.attr = [decoder decodeIntForKey:@#attr]

-(id) initWithCoder:(NSCoder *)decoder
{
    if ((self = [super init]))
    {
        DECODE_OBJ(code);
        DECODE_OBJ(name);
        DECODE_OBJ(name_en);
        DECODE_OBJ(text);
        DECODE_OBJ(flavor);
        DECODE_OBJ(factionStr);
        DECODE_INT(faction);
        DECODE_OBJ(roleStr);
        DECODE_INT(role);
        DECODE_OBJ(typeStr);
        DECODE_INT(type);
        DECODE_OBJ(subtype);
        DECODE_OBJ(subtypes);
        DECODE_OBJ(subtypeCode);
        DECODE_OBJ(subtypeCodes);
        DECODE_OBJ(setName);
        DECODE_OBJ(setCode);
        DECODE_INT(number);
        DECODE_INT(quantity);
        DECODE_INT(unique);
        DECODE_INT(influenceLimit);
        DECODE_INT(minimumDecksize);
        DECODE_INT(baseLink);
        DECODE_INT(advancementCost);
        DECODE_INT(agendaPoints);
        DECODE_INT(strength);
        DECODE_INT(mu);
        DECODE_INT(cost);
        DECODE_INT(trash);
        DECODE_INT(influence);
        DECODE_OBJ(url);
        DECODE_OBJ(imageSrc);
        DECODE_OBJ(artist);
        DECODE_OBJ(lastModified);
    }
    return self;
}

@end
