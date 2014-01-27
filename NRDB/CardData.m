//
//  CardData.m
//  NRDB
//
//  Created by Gereon Steffens on 09.12.13.
//  Copyright (c) 2013 Gereon Steffens. All rights reserved.
//

#import <AFNetworking.h>

#import "Card.h"
#import "CardData.h"
#import "Faction.h"
#import "CardType.h"
#import "SettingsKeys.h"

#define JSON_INT(key, attr)          c->_##key = [[json objectForKey:attr] intValue]
#define JSON_BOOL(key, attr)         c->_##key = [[json objectForKey:attr] boolValue]
#define JSON_STR(key, attr)          c->_##key = [json objectForKey:attr]

#define CARDSFILE_JSON      @"nrcards.json"
// #define CARDSFILE_ARCHIVE   @"nrcards.archive"

@implementation CardData

static NSDictionary* roleCodes;

static NSArray* subtypes;       // array of dictionary type->array
static NSArray* sortedSubtypes; // array of dictionary type->array
static NSArray* subtypeCodes;   // array of array
static NSArray* strengths;      // array of sets
static NSMutableArray* sortedIdentities;

static NSMutableDictionary* allCards;   // code -> card
static NSMutableArray* allRunnerCards;
static NSMutableArray* allCorpCards;
static NSMutableArray* allIdentities;

static NSMutableSet* allSets;

static int maxMU;
static int maxStrength;
static int maxCost;
static int maxInf;
static int maxAgendaPoints;

NSString* const kANY = @"Any";

+(void) initialize
{
    [CardData resetData];
}

+(void) resetData
{
    allCards = [NSMutableDictionary dictionary];
    
    allRunnerCards = [NSMutableArray array];
    allCorpCards = [NSMutableArray array];
    allIdentities = [@[ [NSMutableArray array], [NSMutableArray array] ] mutableCopy];
    
    subtypes = @[ [NSMutableDictionary dictionary], [NSMutableDictionary dictionary] ];
    sortedSubtypes = @[ [NSMutableDictionary dictionary], [NSMutableDictionary dictionary] ];
    sortedIdentities = [@[ [NSMutableArray array], [NSMutableArray array] ] mutableCopy];
    subtypeCodes = @[ [NSMutableArray array], [NSMutableArray array] ];
    strengths = @[ [NSMutableSet set], [NSMutableSet set] ];
    
    allSets = [NSMutableSet set];

    roleCodes = @{ @"runner": @(NRRoleRunner), @"corp": @(NRRoleCorp) };
}

+(NSString*) filename
{
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:CARDSFILE_JSON];
}

+(void) removeFile
{
    NSString* filename = [CardData filename];
    
    NSFileManager* fileMgr = [NSFileManager defaultManager];
    [fileMgr removeItemAtPath:filename error:nil];
    [CardData initialize];
}

+(BOOL) setupFromFile
{
    NSString* cardsFile = [CardData filename];
    
    NSFileManager* fileMgr = [NSFileManager defaultManager];
    if ([fileMgr fileExistsAtPath:cardsFile])
    {
        [CardData resetData];
        NSError* error;
        NSData* data = [NSData dataWithContentsOfFile:cardsFile options:NSDataReadingMappedIfSafe error:&error];
        return [self setupFromJsonData:data];
    }
    return NO;
}

+(BOOL) setupFromNetrunnerDbApi
{
    if (![AFNetworkReachabilityManager sharedManager].reachable)
    {
        return NO;
    }
    
    NSURL* url = [NSURL URLWithString:@"http://netrunnerdb.com/api/cards"];
    NSData* data = [NSData dataWithContentsOfURL:url];
    
    if (data == nil)
    {
        return NO;
    }
    
    NSString* cardsFile = [CardData filename];
    [data writeToFile:cardsFile atomically:YES];
    
    NSDateFormatter *fmt = [NSDateFormatter new];
    [fmt setDateStyle:NSDateFormatterShortStyle]; // z.B. 08.10.2008
    [fmt setTimeStyle:NSDateFormatterNoStyle];
    NSDate* now = [NSDate date];
    [[NSUserDefaults standardUserDefaults] setObject:[fmt stringFromDate:now] forKey:LAST_DOWNLOAD];
    
    NSDate* next = [NSDate dateWithTimeIntervalSinceNow:7*24*60*60];
    [[NSUserDefaults standardUserDefaults] setObject:[fmt stringFromDate:next] forKey:NEXT_DOWNLOAD];
    
    [CardData resetData];
    return [self setupFromJsonData:data];
}

+(BOOL) setupFromJsonData:(NSData*)jsonData
{
    NSError* error;
    NSArray* json = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableLeaves error:&error];
    
    if (json)
    {
        for (NSDictionary* obj in json)
        {
            CardData* card = [CardData cardFromJson:obj];
            if (card)
            {
                [CardData addCard:card manually:NO];
            }
        }
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
    if ([c.setCode isEqualToString:@"alt"] || [c.setCode isEqualToString:@"special"])
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
    JSON_INT(influenceLimit, @"influencelimit");
    JSON_INT(minimumDecksize, @"minimumdecksize");
    JSON_INT(baseLink, @"baselink");
    JSON_INT(advancementCost, @"advancementcost");
    NSString* ap = [json objectForKey:@"agendapoints"];
    c->_agendaPoints = ap ? [ap intValue] : -1;
    
    NSString* strength = [json objectForKey:@"strength"];
    c->_strength = strength ? [strength intValue] : -1;
    [strengths[c.role] addObject:@(c.strength)];
    
    NSString* mu = [json objectForKey:@"memoryunits"];
    c->_mu = mu ? [mu intValue] : -1;
    
    NSString* cost = [json objectForKey:@"cost"];
    c->_cost = cost ? [cost intValue] : -1;
    
    NSString* influence = [json objectForKey:@"factioncost"];
    c->_influence = influence ? [influence intValue] : -1;
    
    NSString* trash = [json objectForKey:@"trash"];
    c->_trash = trash ? [trash intValue] : -1;
    
    JSON_STR(url, @"url");
    JSON_STR(imageSrc, @"imagesrc");
    JSON_STR(artist, @"illustrator");
    c->_lastModified = [json objectForKey:@"last-modified"];
    
    if (c.mu > maxMU) maxMU = c.mu;
    if (c.strength > maxStrength) maxStrength = c.strength;
    if (c.influence > maxInf) maxInf = c.influence;
    if (c.cost > maxCost) maxCost = c.cost;
    if (c.agendaPoints > maxAgendaPoints) maxAgendaPoints = c.agendaPoints;
    
    c.maxCopies = 3;
    if ([c.code isEqualToString:DIR_HAAS_PET_PROJ])
    {
        c.maxCopies = 1;
    }
    
    return c;
}

-(void) synthesizeMissingFields
{
    self.faction = [Faction faction:[self.factionStr lowercaseString]];
    
    self.role = [[roleCodes objectForKey:[self.roleStr lowercaseString]] integerValue];
    
    self.type = [CardType type:[self.typeStr lowercaseString]];

    if (self.subtype)
    {
        self.subtypes = [self.subtype componentsSeparatedByString:@" - "];
        NSMutableArray* arr = subtypes[self.role];
        for (NSString* st in self.subtypes)
        {
            if (![arr containsObject:st])
            {
                [arr addObject:st];
            }
        }
    }
    self.subtypeCode = [self.subtype lowercaseString];
    if (self.subtype.length == 0)
    {
        self.subtypeCode = nil;
    }
    if (self.subtypeCode)
    {
        self.subtypeCodes = [self.subtypeCode componentsSeparatedByString:@" - "];
        NSMutableArray* arr = subtypeCodes[self.role];
        for (NSString* st in self.subtypeCodes)
        {
            if (![arr containsObject:st])
            {
                [arr addObject:st];
            }
        }
    }
}

+(void) addCard:(CardData*)c manually:(BOOL)manually
{
    NSAssert(c != nil, @"invalid card");
    
    if (manually)
    {
        [c synthesizeMissingFields];
    }
    
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

+(void) deleteCard:(CardData *)c
{
    NSAssert(c != nil, @"invalid card");
    [allCards removeObjectForKey:c.code];
    
    NSMutableArray* arr = allIdentities[c.role];
    [arr removeObject:c];
    
    arr = c.role == NRRoleRunner ? allRunnerCards : allCorpCards;
    [arr removeObject:c];
}

+(CardData*) cardByCode:(NSString *)code
{
    return [allCards objectForKey:code];
}

+(NSArray*) allRunnerCards
{
    return allRunnerCards;
}

+(NSArray*) allCorpCards
{
    return allCorpCards;
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
        [setsArray addObject:@"Any"];
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
+(int) maxCost { return maxCost; }
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
#define DECODE_INT(attr) self.attr = [decoder decodeIntegerForKey:@#attr]

-(id) initWithCoder:(NSCoder *)decoder
{
    if ((self = [super init]))
    {
        DECODE_OBJ(code);
        DECODE_OBJ(name);
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
