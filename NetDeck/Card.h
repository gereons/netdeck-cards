//
//  Card.h
//  Net Deck
//
//  Created by Gereon Steffens on 24.11.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

// some identities/cards we need to handle
#define CUSTOM_BIOTICS          @"03002"    // no jinteki cards
#define THE_PROFESSOR           @"03029"    // first copy of each program has influence 0
#define ANDROMEDA               @"02083"    // 9 card starting hand
#define PAD_FACTORY             @"00000"    // code tbd; 0 inf if 3 pad campaigns in deck
#define MUMBAD_TEMPLE           @"10018"    // 0 inf if <= 15 ice in deck
#define MUMBAD_VIRTUAL_TOUR     @"00000"    // code tbd; 0 inf if >= 7 assets in deck

#define PAD_CAMPAIGN            @"01109"    // for pad factory

#define DIRECTOR_HAAS_PET_PROJ  @"03004"    // max 1 per deck
#define PHILOTIC_ENTANGLEMENT   @"05006"    // max 1 per deck
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

// data for a single card
@interface Card : NSObject

@property (readonly) NSString* code;
@property (readonly) NSString* name;
@property NSString* name_en;
@property NSString* alias;
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
@property (readonly) NSString* ancurLink;

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

@end
