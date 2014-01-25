//
//  CardData.h
//  NRDB
//
//  Created by Gereon Steffens on 09.12.13.
//  Copyright (c) 2013 Gereon Steffens. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CardData : NSObject <NSCoding>

+(BOOL) setupFromFile;
+(BOOL) setupFromNetrunnerDbApi;
+(void) removeFile;

+(void) addCard:(CardData*) card manually:(BOOL)manually;
+(void) deleteCard:(CardData*) card;

+(CardData*) cardByCode:(NSString*)code;
+(NSArray*) allRunnerCards;
+(NSArray*) allCorpCards;

+(NSArray*) subtypesForRole:(NRRole)role andType:(NSString*)type;
+(NSArray*) subtypesForRole:(NRRole)role andTypes:(NSSet*)types;
+(NSArray*) identitiesForRole:(NRRole)role;

+(NSArray*) allSets;

+(int) maxStrength;
+(int) maxCost;
+(int) maxMU;
+(int) maxInfluence;
+(int) maxAgendaPoints;

+(BOOL) cardsAvailable;

-(void) synthesizeMissingFields;

@property (readonly) BOOL isValid;

@property (strong) NSString* code;        // unique id of the card
@property (strong) NSString* name;       // name
@property (strong) NSString* text;
@property (strong) NSString* flavor;

@property (strong) NSString* factionStr;
@property NRFaction faction;

@property (strong) NSString* roleStr;    // Runner/Corp
@property NRRole role;

@property (strong) NSString* typeStr;
@property NRCardType type;

@property (strong) NSString* subtype;
@property (strong) NSArray* subtypes;     // array of strings

@property (strong) NSString* subtypeCode;
@property (strong) NSArray* subtypeCodes; // array of strings

@property (strong) NSString* setName;
@property (strong) NSString* setCode;
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

@property (strong) NSString* url;
@property (strong) NSString* imageSrc;
@property (strong) NSString* artist ;

@property (strong) NSString* lastModified;

@property int maxCopies;

@end
