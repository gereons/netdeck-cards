//
//  NRTypes.h
//  Net Deck
//
//  Created by Gereon Steffens on 29.11.13.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

#ifndef NRTypes_h
#define NRTypes_h

#define DIM(x)      (sizeof(x) / sizeof(x[0]))
// #define ISNULL(x)   [x isKindOfClass:[NSNull class]]
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define CHECKED_TITLE(str, cond)    [NSString stringWithFormat:@"%@%@", str, cond ? @" ✓" : @""]

#define OCTGN_CODE_PREFIX   @"bc0f047c-01b1-427f-a439-d451eda"

#define IS_IPAD         ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
#define IS_IPHONE       ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)

#define SCREEN_WIDTH        ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT       ([[UIScreen mainScreen] bounds].size.height)
#define SCREEN_MAX_LENGTH   (MAX(SCREEN_WIDTH, SCREEN_HEIGHT))
#define SCREEN_MIN_LENGTH   (MIN(SCREEN_WIDTH, SCREEN_HEIGHT))

#define IS_IPHONE_4         (IS_IPHONE && SCREEN_MAX_LENGTH < 568.0)

#define CARDS_FILENAME      @"nrcards.json"
#define CARDS_FILENAME_EN   @"nrcards_en.json"
#define SETS_FILENAME       @"nrsets.json"
#define IMAGES_DIRNAME      @"images"

#define BG_FETCH_INTERVAL   (12*60*60)   // 12 hrs

#define IOS9_KEYCMD         [[UIKeyCommand class] respondsToSelector:@selector(keyCommandWithInput:modifierFlags:action:discoverabilityTitle:)]
#define KEYCMD(letter, modifiers, sel, title) ((IOS9_KEYCMD) ? \
    [UIKeyCommand keyCommandWithInput:letter modifierFlags:modifiers action:@selector(sel) discoverabilityTitle:title] : \
    [UIKeyCommand keyCommandWithInput:letter modifierFlags:modifiers action:@selector(sel)])

extern NSString* const kANY;

/*
typedef NS_ENUM(NSInteger, NRRole)
{
    NRRoleNone = -1,
    NRRoleRunner,
    NRRoleCorp
};

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
    NRFactionCriminal,
    
    NRFactionAdam,
    NRFactionApex,
    NRFactionSunnyLebeau
};

typedef NS_ENUM(NSInteger, NRDeckState)
{
    NRDeckStateNone = -1,
    NRDeckStateActive,
    NRDeckStateTesting,
    NRDeckStateRetired
};

typedef NS_ENUM(NSInteger, NRDeckSort)
{
    NRDeckSortType,         // sort by type, then alpha
    NRDeckSortFactionType,  // sort by faction, then type, then alpha
    NRDeckSortSetType,      // sort by set, then type, then alpha
    NRDeckSortSetNum,       // sort by set, then number in set
};

typedef NS_ENUM(NSInteger, NRSearchScope)
{
    NRSearchScopeAll,
    NRSearchScopeName,
    NRSearchScopeText
};

typedef NS_ENUM(NSInteger, NRDeckSearchScope) {
    NRDeckSearchScopeAll,
    NRDeckSearchScopeName,
    NRDeckSearchScopeIdentity,
    NRDeckSearchScopeCard
};

typedef NS_ENUM(NSInteger, NRDeckListSort) {
    NRDeckListSortDate,
    NRDeckListSortFaction,
    NRDeckListSortA_Z
};

typedef NS_ENUM(NSInteger, NRCardView) {
    NRCardViewImage,
    NRCardViewLargeTable,
    NRCardViewSmallTable
};

typedef NS_ENUM(NSInteger, NRBrowserSort) {
    NRBrowserSortType,
    NRBrowserSortFaction,
    NRBrowserSortTypeFaction,
    NRBrowserSortSet,
    NRBrowserSortSetFaction,
    NRBrowserSortSetType,
    NRBrowserSortSetNumber
};

typedef NS_ENUM(NSInteger, NRCycle)
{
    NRCycleNone = -1,
    NRCycleCoreDeluxe,
    NRCycleGenesis,
    NRCycleSpin,
    NRCycleLunar,
    NRCycleSanSan,
    NRCycleMumbad
};

typedef NS_ENUM(NSInteger, NRImportSource)
{
    NRImportSourceNone,
    NRImportSourceDropbox,
    NRImportSourceNetrunnerDb
};

typedef NS_ENUM(NSInteger, NRFilter) {
    NRFilterAll,
    NRFilterRunner,
    NRFilterCorp
};
*/

#endif
