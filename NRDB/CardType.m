//
//  CardType.m
//  NRDB
//
//  Created by Gereon Steffens on 15.12.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "CardType.h"
#import "CardManager.h"
#import "TableData.h"

@implementation CardType

static NSDictionary* code2type;
static NSMutableDictionary* type2name;
static NSMutableArray* runnerTypes;
static NSMutableArray* corpTypes;
static TableData* allTypes;

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
    
    NSMutableArray* types = [NSMutableArray array];
    types = [NSMutableArray array];
    [types addObject:@[ [CardType name:NRCardTypeNone ], [CardType name:NRCardTypeIdentity] ]];
    
    NSRange range = { 1, runnerTypes.count-1 };
    NSIndexSet* runnerSet = [NSIndexSet indexSetWithIndexesInRange:range];
    [types addObject:[NSArray arrayWithArray:[runnerTypes objectsAtIndexes:runnerSet]]];
    
    range.length = corpTypes.count-1;
    NSIndexSet* corpSet = [NSIndexSet indexSetWithIndexesInRange:range];
    [types addObject:[NSArray arrayWithArray:[corpTypes objectsAtIndexes:corpSet]]];
    
    NSArray* typeSections = @[ @"", l10n(@"Runner"), l10n(@"Corp") ];
    
    allTypes = [[TableData alloc] initWithSections:typeSections andValues:types];

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
    NSAssert(role != NRRoleNone, @"no role");
    return role == NRRoleRunner ? runnerTypes : corpTypes;
}

+(NSArray*) subtypesForRole:(NRRole)role andType:(NSString*)type
{
    NSAssert(role != NRRoleNone, @"no role");
    return [CardManager subtypesForRole:role andType:type];
}

+(NSArray*) subtypesForRole:(NRRole)role andTypes:(NSSet*)types
{
    NSAssert(role != NRRoleNone, @"no role");
    return [CardManager subtypesForRole:role andTypes:types];
}

+(TableData*) allTypes
{
    return allTypes;
}

@end
