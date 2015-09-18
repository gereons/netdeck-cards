//
//  CardList.h
//  Net Deck
//
//  Created by Gereon Steffens on 29.11.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "TableData.h"

@class Card;
@interface CardList : NSObject

@property (readonly) NSUInteger count;

-(CardList*) initForRole:(NRRole)role;
+(CardList*) browserInitForRole:(NRRole)role;

-(void) preFilterForCorp:(Card*)identity;

-(void) filterByName:(NSString*) name;
-(void) filterByText:(NSString*) text;
-(void) filterByTextOrName:(NSString*) text;

-(void) filterByCost:(int) cost;
-(void) filterByType:(NSString*) type;
-(void) filterByTypes:(NSSet*) types;
-(void) filterBySubtype:(NSString*) subtype;
-(void) filterBySubtypes:(NSSet*) subtypes;
-(void) filterByMU:(int)mu;
-(void) filterByTrash:(int)trash;
-(void) filterByFaction:(NSString*) faction;
-(void) filterByFactions:(NSSet*) factions;
-(void) filterByInfluence:(int)influence;
-(void) filterByInfluence:(int)influence forFaction:(NRFaction)faction;
-(void) filterBySet:(NSString*)set;
-(void) filterBySets:(NSSet*)sets;
-(void) filterByStrength:(int)strength;
-(void) filterByAgendaPoints:(int)ap;
-(void) filterByUniqueness:(BOOL)unique;
-(void) filterByLimited:(BOOL)limited;

-(void) clearFilters;

-(void) sortBy:(NRBrowserSort)sortType;

-(TableData*) dataForTableView;
-(NSArray*) allCards;

@end
