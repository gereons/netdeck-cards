//
//  Deck.h
//  NRDB
//
//  Created by Gereon Steffens on 24.11.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CardCounter.h"
#import "TableData.h"

@interface Deck : NSObject <NSCoding>

@property (strong) CardCounter* identityCc;
@property (readonly) NSArray* cards;        // array of CardCounter, all cards except identity
@property (readonly) NSArray* allCards;     // array of CardCounter, all cards including identity, id is first element

@property (nonatomic) Card* identity;        // convenience accessor

@property (strong) NSString* name;
@property NRRole role;
@property NRDeckState state;

@property (readonly) int size;
@property (readonly) int influence;
@property (readonly) int agendaPoints;

@property NSString* filename;
@property NSDate* lastModified;

@property NSString* notes;

-(NSArray*) checkValidity; // returns array of reasons, deck is ok if count==0

-(CardCounter*) findCard:(Card*)card;
-(void) addCard:(Card*) card copies:(int)copies;
-(void) removeCard:(Card*) card;
-(void) removeCard:(Card*) card copies:(int)copies;

-(int) influenceFor:(CardCounter*)cc;

-(Deck*) duplicate;

-(TableData*) dataForTableView;

@end
