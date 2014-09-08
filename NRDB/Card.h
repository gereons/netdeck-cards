//
//  Card.h
//  NRDB
//
//  Created by Gereon Steffens on 24.11.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <Foundation/Foundation.h>

// some identities/cards we need to handle
#define CUSTOM_BIOTICS          @"03002"    // no jinteki cards
#define THE_PROFESSOR           @"03029"    // first copy of each program has influence 0
#define DIRECTOR_HAAS_PET_PROJ  @"03004"    // max 1 per deck
#define PHILOTIC_ENTANGLEMENT   @"05006"    // max 1 per deck
#define ANDROMEDA               @"02083"    // 9 card starting hand
#define UTOPIA_SHARD            @"06100"    // max 1 per deck
#define HADES_SHARD             @"06059"    // max 1 per deck
#define EDEN_SHARD              @"06020"    // max 1 per deck
#define EDEN_FRAGMENT           @"06030"    // max 1 per deck
#define HADES_FRAGMENT          @"06071"    // max 1 per deck
// #define UTOPIA_FRAGMENT         @""         // max 1 per deck

// draft ids
#define THE_MASQUE              @"00006"
#define THE_SHADOW              @"00005"

// plugged-in and chronos protocol identities
#define LARAMY_FISK             @"00002"
#define THE_COLLECTIVE          @"00001"
#define CHRONOS_PROTOCOL_HB     @"00004"
#define CHRONOS_PROTOCOL_JIN    @"00003"

// data for a single card

@interface Card : NSObject

@property (readonly) NSString* code;
@property (readonly) NSString* name;
@property (nonatomic) NSString* name_en;
@property (readonly) NSString* text;
@property (readonly) NSString* flavor;
@property (readonly) NRCardType type;
@property (readonly) NSString* typeStr;
@property (readonly) NSString* subtype;     // full subtype string like "Fracter - Icebreaker - AI"
@property (readonly) NSArray* subtypes;     // array of subtypes like @[ @"Fracter", @"Icebreaker", @"AI" ]
@property (readonly) NSString* subtypeCode; // full subtype codes
@property (readonly) NSArray* subtypeCodes; // array of subtype codes
@property (readonly) NRFaction faction;
@property (readonly) NSString* factionStr;
@property (readonly) NRRole role;
@property (readonly) int number;
@property (readonly) int influenceLimit;
@property (readonly) int minimumDecksize;
@property (readonly) int baseLink;
@property (readonly) int influence;
@property (readonly) int mu;
@property (readonly) int strength;
@property (readonly) int cost;
@property (readonly) int advancementCost;
@property (readonly) int agendaPoints;
@property (readonly) int trash;
@property (readonly) int quantity;
@property (readonly) NSString* setName;
@property (readonly) NSString* setCode;
@property (readonly) NSString* artist;
@property (readonly) BOOL unique;
@property (readonly) BOOL limited;
@property (readonly) NSString* imageSrc;
@property (readonly) NSString* url;

@property (readonly) Card* altCard;
@property (readonly) UIColor* factionColor;
@property (readonly) NSUInteger factionHexColor;
@property (nonatomic, readonly) NSAttributedString* attributedText;    // html rendered
@property (readonly) NSString* octgnCode;
@property (readonly) int maxCopies;
@property (readonly) int cropY;
@property (readonly, getter = isValid) BOOL valid;

+(Card*) cardByCode:(NSString*)code;

+(Card*) cardFromJson:(NSDictionary*) json;

@end
