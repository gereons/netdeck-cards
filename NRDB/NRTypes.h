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

extern NSString* const kANY;

typedef NS_ENUM(int, NRCardType)
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

typedef NS_ENUM(int, NRRole)
{
    NRRoleNone = -1,
    NRRoleRunner,
    NRRoleCorp
};

typedef NS_ENUM(int, NRFaction)
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

typedef NS_ENUM(int, FieldType)
{
    StringField,
    IntField,
    BooleanField
};

typedef NS_ENUM(int, NRSearchScope)
{
    NRSearchAll,
    NRSearchName,
    NRSearchText
};

typedef NS_ENUM(int, NRCycle)
{
    NRCycleNone = -1,
    NRCycleCoreDeluxe,
    NRCycleGenesis,
    NRCycleSpin,
    NRCycleLunar
};

#endif
