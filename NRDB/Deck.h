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

@property (readonly) NSArray* cards;        // array of CardCounter, all cards except identity
@property (readonly) NSArray* allCards;     // array of CardCounter, all cards including identity, id is first element

@property (readonly) CardCounter* identityCc;   // a CardCounter with the deck's identity
@property (readonly) Card* identity;            // convenience accessor

@property NSString* name;
@property NRRole role;
@property NRDeckState state;
@property NSString* netrunnerDbId;

@property (readonly) int size;
@property (readonly) int influence;
@property (readonly) int agendaPoints;
@property (readonly) BOOL isDraft;

@property NSString* filename;
@property NSDate* dateCreated;
@property NSDate* lastModified;

@property NSArray* tags;    // array of strings
@property NSString* notes;

@property NSArray* revisions;   // array of DeckChangeSet, in reverse chronological order

-(NSArray*) checkValidity;  // returns array of reasons, deck is ok if count==0

/**
 * find a card in this deck
 * @param card the card to search for
 * @return the CardCounter for this card, or null if not found
 */
-(CardCounter*) findCard:(Card*)card;

// add (copies>0) or remove (copies<0) a copy of a card from the deck
// if copies==0, removes ALL copies of the card
-(void) addCard:(Card*)card copies:(NSInteger)copies history:(BOOL)history;

// convenience method with history:YES
-(void) addCard:(Card*)card copies:(NSInteger)copies;

// revert to a given set of cards
-(void) resetToCards:(NSDictionary*)cards;

-(NSUInteger) influenceFor:(CardCounter*)cc;

-(Deck*) duplicate;

-(void) mergeRevisions;

-(TableData*) dataForTableView:(NRDeckSort)sortType;

@end
