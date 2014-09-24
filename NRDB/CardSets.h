//
//  CardSets.h
//  NRDB
//
//  Created by Gereon Steffens on 14.12.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TableData.h"

@class Deck;
@interface CardSets : NSObject

#define CORE_SET    @"core"

+(void) setupSetNames;

// all sets that the user has enabled
+(TableData*) allSetsForTableview;

// all sets that the user wants to ignore
+(NSSet*) disabledSetCodes;
// all sets we know about
+(NSSet*) knownSetCodes;

+(NSDictionary*) settingsDefaults;

+(NSString*) mostRecentSetUsedInDeck:(Deck*)deck;
+(NSArray*) setsUsedInDeck:(Deck*) deck;
+(NSString*) nameForKey:(NSString*) key;

@end
