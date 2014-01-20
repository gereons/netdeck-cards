//
//  Card.h
//  NRDB
//
//  Created by Gereon Steffens on 24.11.13.
//  Copyright (c) 2013 Gereon Steffens. All rights reserved.
//

#import <Foundation/Foundation.h>

// some identities/cards we need to handle
#define CUSTOM_BIOTICS      @"03002"    // no jinteki cards
#define THE_PROFESSOR       @"03029"    // first copy of each program has influence 0
#define DIR_HAAS_PET_PROJ   @"03004"    // max 1 per deck
#define ANDROMEDA           @"02083"    // 9 card starting hand

// data for a single card

@interface Card : NSObject

@property (readonly) NSString* code;
@property (readonly) NSString* name;
@property (readonly) NSString* text;
@property (readonly) NSString* flavor;
@property (readonly) NRCardType type;
@property (readonly) NSString* typeStr;
@property (readonly) NSString* subtype; // full subtype string like "Fracter - Icebreaker - AI"
@property (readonly) NSArray* subtypes; // array of subtypes like @[ @"Fracter", @"Icebreaker", @"AI" ]
@property (readonly) NRFaction faction;
@property (readonly) NSString* factionStr;
@property (readonly) NRRole role;
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
@property (readonly) NSString* setName;
@property (readonly) NSString* setCode;
@property (readonly) NSString* artist;
@property (readonly) BOOL unique;
@property (readonly) NSString* imageSrc;
@property (readonly) NSString* url;

@property (readonly) NSString* detailText;
@property (readonly) UIColor* factionColor;
@property (readonly) NSUInteger factionHexColor;

@property (nonatomic, readonly) NSString* filteredText;                // html removed
@property (nonatomic, readonly) NSAttributedString* attributedText;    // html rendered
@property (nonatomic, readonly) CGFloat attributedTextHeight;
@property (readonly) NSString* octgnCode;

+(NSArray*) allForRole:(NRRole)role;
+(NSArray*) identitiesForRole:(NRRole)role;

+(Card*) cardByCode:(NSString*)code;

@end
