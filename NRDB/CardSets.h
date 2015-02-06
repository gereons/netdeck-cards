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

#define CORE_SET            @"core"
#define DRAFT_SET           @"Draft"
#define SPECIAL_SET         @"special"

#define DRAFT_SET_CODE      @"000"
#define SPECIAL_SET_CODE    @"001"
#define UNKNOWN_SET_CODE    @"002"

+(void) setupSetNames;

// all sets that the user has enabled
+(TableData*) allSetsForTableview;

// all sets that the user wants to ignore
+(NSSet*) disabledSetCodes;
+(void) clearDisabledSets;

// all sets we know about
+(NSSet*) knownSetCodes;
+(void) registerNrdbCode:(NSString*)setCode andName:(NSString*)setName;

+(NSDictionary*) settingsDefaults;

+(NSString*) mostRecentSetUsedInDeck:(Deck*)deck;
+(NSArray*) setsUsedInDeck:(Deck*) deck;
+(NSString*) nameForKey:(NSString*) key;
+(int) setNumForCode:(NSString*)code;

+(BOOL) setupFromNrdbApi:(NSArray*)json;

@end
