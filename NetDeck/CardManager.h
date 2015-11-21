//
//  CardManager.h
//  Net Deck
//
//  Created by Gereon Steffens on 22.06.14.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

@class Card;

@interface yCardManager : NSObject

+(Card*) cardByCode:(NSString*)code;

+(NSArray<Card*>*) allCards;

+(NSArray<Card*>*) allForRole:(NRRole)role;
+(NSArray<Card*>*) identitiesForRole:(NRRole)role;

+(NSMutableArray<NSString*>*) subtypesForRole:(NRRole)role andType:(NSString*)type includeIdentities:(BOOL)includeIdentities;
+(NSMutableArray<NSString*>*) subtypesForRole:(NRRole)role andTypes:(NSSet*)types includeIdentities:(BOOL)includeIdentities;

+(NSInteger) maxStrength;
+(NSInteger) maxRunnerCost;
+(NSInteger) maxCorpCost;
+(NSInteger) maxMU;
+(NSInteger) maxInfluence;
+(NSInteger) maxAgendaPoints;
+(NSInteger) maxTrash;

// initialization
+(BOOL) cardsAvailable;

+(BOOL) setupFromFiles;
+(void) removeFiles;
+(BOOL) setupFromNrdbApi:(NSArray*)json;
+(void) addAdditionalNames:(NSArray*)json saveFile:(BOOL)saveFile;

+(void) setNextDownloadDate;

@end
