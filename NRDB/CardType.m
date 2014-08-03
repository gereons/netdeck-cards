//
//  CardType.m
//  NRDB
//
//  Created by Gereon Steffens on 15.12.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "CardType.h"
#import "CardManager.h"

@implementation CardType

static NSDictionary* code2type;
static NSMutableDictionary* type2name;
static NSMutableArray* runnerTypes;
static NSMutableArray* corpTypes;
static NSMutableArray* allTypes;

+(void) initialize
{
    code2type = @{
        @"identity": @(NRCardTypeIdentity),
        @"asset": @(NRCardTypeAsset),
        @"agenda": @(NRCardTypeAgenda),
        @"ice": @(NRCardTypeIce),
        @"upgrade": @(NRCardTypeUpgrade),
        @"operation": @(NRCardTypeOperation),
        @"program": @(NRCardTypeProgram),
        @"hardware": @(NRCardTypeHardware),
        @"resource": @(NRCardTypeResource),
        @"event": @(NRCardTypeEvent),
    };

    type2name = [NSMutableDictionary dictionary];
}
    
+(void) initializeCardTypes:(NSArray*)cards
{
    [type2name removeAllObjects];
    [type2name setObject:kANY forKey:@(NRCardTypeNone)];
    for (Card* c in cards)
    {
        [type2name setObject:c.typeStr forKey:@(c.type)];
        
        if (type2name.count == code2type.count + 1)
        {
            break;
        }
    }
    
    NRCardType rt[] = { NRCardTypeNone, NRCardTypeEvent, NRCardTypeHardware, NRCardTypeResource, NRCardTypeProgram };
    NRCardType ct[] = { NRCardTypeNone, NRCardTypeAgenda, NRCardTypeAsset, NRCardTypeUpgrade, NRCardTypeOperation, NRCardTypeIce };
    NRCardType at[] = { NRCardTypeIdentity,
                            NRCardTypeEvent, NRCardTypeHardware, NRCardTypeResource, NRCardTypeProgram,
                            NRCardTypeAgenda, NRCardTypeAsset, NRCardTypeUpgrade, NRCardTypeOperation, NRCardTypeIce };
    
    runnerTypes = [NSMutableArray array];
    for (int i=0; i<DIM(rt); ++i)
    {
        [runnerTypes addObject:[CardType name:rt[i]]];
    }
    
    corpTypes = [NSMutableArray array];
    for (int i=0; i<DIM(ct); ++i)
    {
        [corpTypes addObject:[CardType name:ct[i]]];
    }
    
    // allTypes is sorted, with "Any" as the first entry
    allTypes = [NSMutableArray array];
    for (int i=0; i<DIM(at); ++i)
    {
        [allTypes addObject:[CardType name:at[i]]];
    }
    [allTypes sortUsingComparator:^NSComparisonResult(NSString* s1, NSString* s2) {
        return [s1 compare:s2];
    }];
    [allTypes insertObject:[CardType name:NRCardTypeNone] atIndex:0];
}

+(NRCardType) type:(NSString*)code
{
    return [[code2type objectForKey:code] intValue];
}

+(NSString*) name:(NRCardType)type
{
    return [type2name objectForKey:@(type)];
}

+(NSArray*) typesForRole:(NRRole)role
{
    switch (role)
    {
        case NRRoleRunner: return runnerTypes;
        case NRRoleCorp: return corpTypes;
        case NRRoleNone: return allTypes;
    }
}

+(NSArray*) subtypesForRole:(NRRole)role andType:(NSString*)type
{
    return [CardManager subtypesForRole:role andType:type];
}

+(NSArray*) subtypesForRole:(NRRole)role andTypes:(NSSet*)types
{
    return [CardManager subtypesForRole:role andTypes:types];
}

@end
