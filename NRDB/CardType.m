//
//  CardType.m
//  NRDB
//
//  Created by Gereon Steffens on 15.12.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "CardType.h"
#import "CardData.h"

@implementation CardType

static NSDictionary* code2type;
static NSDictionary* type2name;
static NSMutableArray* runnerTypes;
static NSMutableArray* corpTypes;

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

    type2name = @{
        @(NRCardTypeIdentity): @"Identity",
        @(NRCardTypeAsset): @"Asset",
        @(NRCardTypeAgenda): @"Agenda",
        @(NRCardTypeIce): @"ICE",
        @(NRCardTypeUpgrade): @"Upgrade",
        @(NRCardTypeOperation): @"Operation",
        @(NRCardTypeProgram): @"Program",
        @(NRCardTypeHardware): @"Hardware",
        @(NRCardTypeResource): @"Resource",
        @(NRCardTypeEvent): @"Event",
        @(NRCardTypeNone): kANY
    };
    
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
    return role == NRRoleRunner ? runnerTypes : corpTypes;
}

+(NSArray*) subtypesForRole:(NRRole)role andType:(NSString*)type
{
    return [CardData subtypesForRole:role andType:type];
}

+(NSArray*) subtypesForRole:(NRRole)role andTypes:(NSSet*)types
{
    return [CardData subtypesForRole:role andTypes:types];
}

@end
