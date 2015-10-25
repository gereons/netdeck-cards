//
//  Card.h
//  Net Deck
//
//  Created by Gereon Steffens on 24.11.13.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

// identities we need to handle
#define CUSTOM_BIOTICS          @"03002"    // no jinteki cards
#define THE_PROFESSOR           @"03029"    // first copy of each program has influence 0
#define ANDROMEDA               @"02083"    // 9 card starting hand

// alliance cards with weird influence rules

#define PAD_FACTORY             @"00000"    // code tbd; 0 inf if 3 pad campaigns in deck
#define MUMBA_TEMPLE            @"10018"    // 0 inf if <= 15 ice in deck
#define JEEVES_MODEL_BIOROID    @"10067"    // 0 inf if >=6 non-alliance HB cards in deck
#define RAMAN_RAI               @"10068"    // 0 inf if >=6 non-alliance Jinteki cards in deck
#define SALEMS_HOSPITALITY      @"10071"    // 0 inf if >=6 non-alliance NBN cards in deck
#define EXECUTIVE_SEARCH_FIRM   @"10072"    // 0 inf if >=6 non-alliance Weyland cards in deck
#define MUMBAD_VIRTUAL_TOUR     @"10075"    // 0 inf if >= 7 assets in deck

#define PAD_CAMPAIGN            @"01109"    // needed for pad factory

// "limit 1 per deck" cards
#define DIRECTOR_HAAS_PET_PROJ  @"03004"
#define PHILOTIC_ENTANGLEMENT   @"05006"
#define UTOPIA_SHARD            @"06100"
#define HADES_SHARD             @"06059"
#define EDEN_SHARD              @"06020"
#define EDEN_FRAGMENT           @"06030"
#define HADES_FRAGMENT          @"06071"
#define UTOPIA_FRAGMENT         @"06110"
#define GOVERNMENT_TAKEOVER     @"07006"
#define _15_MINUTES             @"09004"
#define MAX_1_PER_DECK          @[ DIRECTOR_HAAS_PET_PROJ, PHILOTIC_ENTANGLEMENT, UTOPIA_SHARD, UTOPIA_FRAGMENT, HADES_SHARD, \
                                   HADES_FRAGMENT, EDEN_SHARD, EDEN_FRAGMENT, GOVERNMENT_TAKEOVER, _15_MINUTES ]
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
@property (readonly) BOOL isAlliance;

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

// NB: not part of the public API!
-(void) setAlliance:(NSString*)subtype;

@end
