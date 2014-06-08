//
//  CardData.h
//  NRDB
//
//  Created by Gereon Steffens on 09.12.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CardData : NSObject <NSCoding>

+(BOOL) setupFromFile;
+(BOOL) setupFromNetrunnerDbApi:(NSArray*)array;
+(void) addEnglishNames:(NSArray*)array;
+(void) removeFile;

+(CardData*) cardByCode:(NSString*)code;
+(NSArray*) allRunnerCards;
+(NSArray*) allCorpCards;
+(NSArray*) altCards;

+(NSArray*) subtypesForRole:(NRRole)role andType:(NSString*)type;
+(NSArray*) subtypesForRole:(NRRole)role andTypes:(NSSet*)types;
+(NSArray*) identitiesForRole:(NRRole)role;

+(NSArray*) allSets;
+(CardData*) altFor:(NSString*) name;

+(int) maxStrength;
+(int) maxRunnerCost;
+(int) maxCorpCost;
+(int) maxMU;
+(int) maxInfluence;
+(int) maxAgendaPoints;

+(BOOL) cardsAvailable;

@property (readonly) BOOL isValid;

@property NSString* code;       // unique id of the card
@property NSString* name;       // name
@property (nonatomic) NSString* name_en;    // name in english
@property NSString* text;
@property NSString* flavor;

@property NSString* factionStr;
@property NRFaction faction;

@property NSString* roleStr;    // Runner/Corp
@property NRRole role;

@property NSString* typeStr;
@property NRCardType type;

@property NSString* subtype;
@property NSArray* subtypes;     // array of strings

@property NSString* subtypeCode;
@property NSArray* subtypeCodes; // array of strings

@property NSString* setName;
@property NSString* setCode;
@property int number;                     // number in set
@property int quantity;                   // quantity in set

@property BOOL unique;

@property int influenceLimit;             // identity only
@property int minimumDecksize;
@property int baseLink;

@property int advancementCost;            // agenda only
@property int agendaPoints;

@property int strength;                   // ice only

@property int mu;                         // programs only

@property int cost;                       // cost to install
@property int trash;                      // -1: not trashable

@property int influence;

@property NSString* url;
@property NSString* imageSrc;
@property NSString* artist ;

@property NSString* lastModified;

@property BOOL limited;                 // has a '1 per deck' limit
@property int maxCopies;

@end
