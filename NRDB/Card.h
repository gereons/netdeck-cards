//
//  Card.h
//  NRDB
//
//  Created by Gereon Steffens on 24.11.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

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
#define UTOPIA_FRAGMENT         @"06110"    // max 1 per deck
#define GOVERNMENT_TAKEOVER     @"07006"    // max 1 per deck

#define MAX_1_PER_DECK          @[ DIRECTOR_HAAS_PET_PROJ, PHILOTIC_ENTANGLEMENT, UTOPIA_SHARD, UTOPIA_FRAGMENT, HADES_SHARD, \
                                   HADES_FRAGMENT, EDEN_SHARD, EDEN_FRAGMENT, GOVERNMENT_TAKEOVER ]

// draft ids
#define THE_MASQUE              @"00006"
#define THE_SHADOW              @"00005"
#define DRAFT_IDS               @[ THE_MASQUE, THE_SHADOW ]

// plugged-in and chronos protocol identities
#define LARAMY_FISK             @"00002"
#define THE_COLLECTIVE          @"00001"
#define CHRONOS_PROTOCOL_HB     @"00004"
#define CHRONOS_PROTOCOL_JIN    @"00003"
#define SPECIAL_IDS             @[ LARAMY_FISK, THE_COLLECTIVE, CHRONOS_PROTOCOL_HB, CHRONOS_PROTOCOL_JIN ]

// data for a single card

@interface Card : NSObject

@property (readonly) NSString* code;
@property (readonly) NSString* name;
@property (readonly) NSString* text;
@property (readonly) NSString* flavor;
@property (readonly) NRCardType type;
@property (readonly) NSString* typeStr;
@property (readonly) NSString* subtype;     // full subtype string like "Fracter - Icebreaker - AI"
@property (readonly) NSArray* subtypes;     // array of subtypes like @[ @"Fracter", @"Icebreaker", @"AI" ]
@property (readonly) NSString* iceType;     // special for ICE: return primary subtype (Barrier, CG, Sentry, Trap, Mythic) or "Multi"
@property (readonly) NSString* programType; // special for Programs: return "Icebreaker" for icebreakers, "Program" for other programs
@property (readonly) NRFaction faction;
@property (readonly) NSString* factionStr;
@property (readonly) NRRole role;
@property (readonly) NSString* roleStr;
@property (readonly) int influenceLimit;    // for id
@property (readonly) int minimumDecksize;   // for id
@property (readonly) int baseLink;          // for runner id
@property (readonly) int influence;
@property (readonly) int mu;
@property (readonly) int strength;
@property (readonly) int cost;
@property (readonly) int advancementCost;   // agenda
@property (readonly) int agendaPoints;      // agenda
@property (readonly) int trash;
@property (readonly) int quantity;          // number of cards in set
@property (readonly) int number;            // card no. in set
@property (readonly) NSString* setName;
@property (readonly) NSString* setCode;
@property (readonly) int setNumber;         // our own internal set number, for sorting by set release
@property (readonly) BOOL unique;
@property (readonly) int maxPerDeck;        // limited cards
@property (readonly) NSString* imageSrc;

@property (readonly) UIColor* factionColor;
@property (readonly) NSUInteger factionHexColor;
@property (nonatomic, readonly) NSAttributedString* attributedText;    // html rendered
@property (readonly) NSString* octgnCode;
@property (readonly) int cropY;
@property (readonly, getter = isValid) BOOL valid;
@property (readonly) BOOL isCore;       // card is from core set
@property (readonly) NSInteger owned;   // how many copies owned

+(Card*) cardByCode:(NSString*)code;

+(Card*) cardFromJson:(NSDictionary*) json;

+(NSArray*) draftIds;

@end
