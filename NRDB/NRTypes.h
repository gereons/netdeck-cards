//
//  NRTypes.h
//  NRDB
//
//  Created by Gereon Steffens on 29.11.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#ifndef NRTypes_h
#define NRTypes_h

#define DIM(x)  (sizeof(x) / sizeof(x[0]))
#define ISNULL(x)   [x isKindOfClass:[NSNull class]]

extern NSString* const kANY;

typedef NS_ENUM(NSInteger, NRCardType)
{
    NRCardTypeNone = -1,
    NRCardTypeIdentity,
    
    // corp
    NRCardTypeAgenda,
    NRCardTypeAsset,
    NRCardTypeUpgrade,
    NRCardTypeOperation,
    NRCardTypeIce,
    
    // runner
    NRCardTypeEvent,
    NRCardTypeHardware,
    NRCardTypeResource,
    NRCardTypeProgram
};

typedef NS_ENUM(NSInteger, NRRole)
{
    NRRoleNone = -1,
    NRRoleRunner,
    NRRoleCorp
};

typedef NS_ENUM(NSInteger, NRFaction)
{
    NRFactionNone = -1,
    NRFactionNeutral,
    NRFactionHaasBioroid,
    NRFactionWeyland,
    NRFactionNBN,
    NRFactionJinteki,
    
    NRFactionAnarch,
    NRFactionShaper,
    NRFactionCriminal
};

typedef NS_ENUM(NSInteger, FieldType)
{
    StringField,
    IntField,
    BooleanField
};

typedef NS_ENUM(NSInteger, NRSearchScope)
{
    NRSearchAll,
    NRSearchName,
    NRSearchText
};

typedef NS_ENUM(NSInteger, NRCycle)
{
    NRCycleNone = -1,
    NRCycleCoreDeluxe,
    NRCycleGenesis,
    NRCycleSpin,
    NRCycleLunar
};

#endif
