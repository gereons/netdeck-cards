//
//  CardManager.h
//  Net Deck
//
//  Created by Gereon Steffens on 22.06.14.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

#import "Card.h"

@interface CardManager : NSObject

+(Card*) cardByCode:(NSString*)code;

+(NSArray*) allCards;

+(NSArray*) allForRole:(NRRole)role;
+(NSArray*) identitiesForRole:(NRRole)role;

+(NSMutableArray*) subtypesForRole:(NRRole)role andType:(NSString*)type includeIdentities:(BOOL)includeIdentities;
+(NSMutableArray*) subtypesForRole:(NRRole)role andTypes:(NSSet*)types includeIdentities:(BOOL)includeIdentities;

+(int) maxStrength;
+(int) maxRunnerCost;
+(int) maxCorpCost;
+(int) maxMU;
+(int) maxInfluence;
+(int) maxAgendaPoints;
+(int) maxTrash;

// initialization
+(BOOL) cardsAvailable;

+(BOOL) setupFromFiles;
+(void) removeFiles;
+(BOOL) setupFromNrdbApi:(NSArray*)json;
+(void) addAdditionalNames:(NSArray*)json saveFile:(BOOL)saveFile;

+(void) setNextDownloadDate;

@end
