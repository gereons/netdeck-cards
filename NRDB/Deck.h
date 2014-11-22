//
//  Deck.h
//  NRDB
//
//  Created by Gereon Steffens on 24.11.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "CardCounter.h"
#import "TableData.h"

@interface Deck : NSObject <NSCoding>

@property (readonly) CardCounter* identityCc;
@property (readonly) NSArray* cards;        // array of CardCounter, all cards except identity
@property (readonly) NSArray* allCards;     // array of CardCounter, all cards including identity, id is first element

@property (nonatomic) Card* identity;       // convenience accessor

@property NSString* name;
@property NRRole role;
@property NRDeckState state;
@property NSString* netrunnerDbId;

@property (readonly) int size;
@property (readonly) int influence;
@property (readonly) int agendaPoints;
@property (readonly) BOOL isDraft;

@property NSString* filename;
@property NSDate* lastModified;

@property NSArray* tags;    // array of strings
@property NSString* notes;

@property NSArray* revisions;   // array of DeckChangeSet, in reverse chronological order

-(NSArray*) checkValidity;  // returns array of reasons, deck is ok if count==0

-(CardCounter*) findCard:(Card*)card;
-(void) addCard:(Card*) card copies:(int)copies;
-(void) removeCard:(Card*) card;
-(void) removeCard:(Card*) card copies:(int)copies;

-(NSUInteger) influenceFor:(CardCounter*)cc;

-(Deck*) duplicate;

-(TableData*) dataForTableView:(NRDeckSort)sortType;

@end
