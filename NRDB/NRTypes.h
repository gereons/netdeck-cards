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
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

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

typedef NS_ENUM(NSInteger, NRDeckState)
{
    NRDeckStateNone = -1,
    NRDeckStateActive,
    NRDeckStateTesting,
    NRDeckStateRetired
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

typedef NS_ENUM(NSInteger, NRDeckSearchScope) {
    NRDeckSearchAll,
    NRDeckSearchName,
    NRDeckSearchIdentity,
    NRDeckSearchCard
};

typedef NS_ENUM(NSInteger, NRDeckSortType) {
    NRDeckSortDate,
    NRDeckSortFaction,
    NRDeckSortA_Z
};

typedef NS_ENUM(NSInteger, NRCycle)
{
    NRCycleNone = -1,
    NRCycleCoreDeluxe,
    NRCycleGenesis,
    NRCycleSpin,
    NRCycleLunar
};

typedef NS_ENUM(NSInteger, NRImportSource)
{
    NRImportSourceNone,
    NRImportSourceDropbox,
    NRImportSourceNetrunnerDb
};

typedef NS_ENUM(NSInteger, NRFilterType) {
    NRFilterAll,
    NRFilterRunner,
    NRFilterCorp
};

#endif
