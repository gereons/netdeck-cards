//
//  CardSets.h
//  NRDB
//
//  Created by Gereon Steffens on 14.12.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "TableData.h"

@class Deck;
@interface CardSets : NSObject

#define CORE_SET_CODE       @"core"
#define DRAFT_SET_CODE      @"draft"
#define SPECIAL_SET_CODE    @"special"

#define DRAFT_SET_NAME      @"Draft"
#define SPECIAL_SET_NAME    @"Special"
#define CORE_SET_NAME       @"Core"

#define UNKNOWN_SET         @"unknown"

// all sets that the user has enabled
+(TableData*) allEnabledSetsForTableview;
// all sets that we know about
+(TableData*) allKnownSetsForTableview;

// all sets that the user wants to ignore
+(NSSet*) disabledSetCodes;
+(void) clearDisabledSets;

// all sets we know about
+(NSSet*) knownSetCodes;

+(NSDictionary*) settingsDefaults;

+(NSString*) mostRecentSetUsedInDeck:(Deck*)deck;
+(NSArray*) setsUsedInDeck:(Deck*) deck;
+(NSString*) nameForKey:(NSString*) key;
+(int) setNumForCode:(NSString*)code;

+(BOOL) setupFromNrdbApi:(NSArray*)json;
+(BOOL) setupFromFiles;
+(void) removeFiles;

@end
