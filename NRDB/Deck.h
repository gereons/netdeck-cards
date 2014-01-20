//
//  Deck.h
//  NRDB
//
//  Created by Gereon Steffens on 24.11.13.
//  Copyright (c) 2013 Gereon Steffens. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CardCounter.h"
#import "TableData.h"

@interface Deck : NSObject <NSCoding>

@property (strong) Card* identity;
@property (readonly) NSArray* cards; // array of CardCounter

@property (strong) NSString* name;
@property NRRole role;

@property (readonly) int size;
@property (readonly) int influence;
@property (readonly) int agendaPoints;

@property NSString* filename;

-(BOOL) valid:(NSString**)reason;

-(void) addCard:(Card*) card copies:(int)copies;
-(void) removeCard:(Card*) card;
-(void) removeCard:(Card*) card copies:(int)copies;

-(int) influenceFor:(CardCounter*)cc;

-(Deck*) copy;

-(TableData*) dataForTableView;

@end
