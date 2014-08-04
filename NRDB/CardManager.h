//
//  CardManager.h
//  NRDB
//
//  Created by Gereon Steffens on 22.06.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Card.h"

@interface CardManager : NSObject

+(Card*) cardByCode:(NSString*)code;
+(Card*) altCardFor:(NSString*)code;

+(NSArray*) allCards;
+(NSArray*) altCards;
+(NSArray*) allForRole:(NRRole)role;
+(NSArray*) identitiesForRole:(NRRole)role;

+(NSArray*) subtypesForRole:(NRRole)role andType:(NSString*)type includeIdentities:(BOOL)includeIdentities;
+(NSArray*) subtypesForRole:(NRRole)role andTypes:(NSSet*)types includeIdentities:(BOOL)includeIdentities;

+(int) maxStrength;
+(int) maxRunnerCost;
+(int) maxCorpCost;
+(int) maxMU;
+(int) maxInfluence;
+(int) maxAgendaPoints;

// initialization
+(BOOL) cardsAvailable;

+(BOOL) setupFromFiles;
+(void) removeFiles;
+(BOOL) setupFromNetrunnerDbApi:(NSArray*)json;
+(void) addEnglishNames:(NSArray*)json;

@end
