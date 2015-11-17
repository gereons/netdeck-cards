//
//  Deck.h
//  Net Deck
//
//  Created by Gereon Steffens on 24.11.13.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

@class DeckChangeSet;

@interface Deck : NSObject <NSCoding>

@property (readonly) NSArray<CardCounter*>* cards;        // array of CardCounter, all cards except identity
@property (readonly) NSArray<CardCounter*>* allCards;     // array of CardCounter, all cards including identity, id is first element

@property (readonly) CardCounter* identityCc;   // a CardCounter with the deck's identity
@property (readonly) Card* identity;            // convenience accessor

@property (readonly) BOOL modified;  // has this deck been modified since we last saved it?

// calling any of the -addCard: methods sets modified=YES
// assigning to any of these 5 properties also sets modified=YES
@property (nonatomic) NSString* name;
@property (nonatomic) NRRole role;
@property (nonatomic) NRDeckState state;
@property (nonatomic) NSString* netrunnerDbId;
@property (nonatomic) NSString* notes;

// calling -(void)saveToDisk set modified=NO

@property (readonly) int size;
@property (readonly) int influence;
@property (readonly) int agendaPoints;
@property (readonly) BOOL isDraft;

@property NSString* filename;
@property NSDate* dateCreated;
@property NSDate* lastModified;

@property NSArray<NSString*>* tags;        // array of strings
@property NSArray<DeckChangeSet*>* revisions;   // array of DeckChangeSet, in reverse chronological order

-(NSArray<NSString*>*) checkValidity;  // returns array of reasons, deck is ok if count==0

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
-(void) resetToCards:(NSDictionary<NSString*, NSNumber*>*)cards;

-(NSUInteger) influenceFor:(CardCounter*)cc;

-(Deck*) duplicate;

-(void) mergeRevisions;

-(void) saveToDisk;

-(TableData*) dataForTableView:(NRDeckSort)sortType;

@end
