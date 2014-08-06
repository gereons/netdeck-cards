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
    
    NRCardType rt[] = { NRCardTypeEvent, NRCardTypeHardware, NRCardTypeResource, NRCardTypeProgram };
    NRCardType ct[] = { NRCardTypeAgenda, NRCardTypeAsset, NRCardTypeUpgrade, NRCardTypeOperation, NRCardTypeIce };
    
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
    
    NSArray* typeSections = @[ @"", l10n(@"Runner"), l10n(@"Corp") ];
    NSMutableArray* types = [NSMutableArray array];
    [types addObject:@[ [CardType name:NRCardTypeNone ], [CardType name:NRCardTypeIdentity] ]];
    [types addObject:runnerTypes];
    [types addObject:corpTypes];
    
    allTypes = [[TableData alloc] initWithSections:typeSections andValues:types];

    [runnerTypes insertObject:[CardType name:NRCardTypeNone] atIndex:0];
    [corpTypes insertObject:[CardType name:NRCardTypeNone] atIndex:0];
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

+(TableData*) allTypes
{
    return allTypes;
}

@end
