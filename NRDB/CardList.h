//
//  CardList.h
//  NRDB
//
//  Created by Gereon Steffens on 29.11.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TableData.h"

@class Card;
@interface CardList : NSObject

-(CardList*) initForRole:(NRRole)role;
+(CardList*) browserInitForRole:(NRRole)role;

-(void) filterAgendas:(Card*)identity;

-(void) filterByName:(NSString*) name;
-(void) filterByText:(NSString*) text;
-(void) filterByTextOrName:(NSString*) text;

-(void) filterByCost:(int) cost;
-(void) filterByType:(NSString*) type;
-(void) filterByTypes:(NSSet*) types;
-(void) filterBySubtype:(NSString*) subtype;
-(void) filterBySubtypes:(NSSet*) subtypes;
-(void) filterByMU:(int)mu;
-(void) filterByFaction:(NSString*) faction;
-(void) filterByFactions:(NSSet*) factions;
-(void) filterByInfluence:(int)influence;
-(void) filterBySet:(NSString*)set;
-(void) filterBySets:(NSSet*)sets;
-(void) filterByStrength:(int)strength;
-(void) filterByAgendaPoints:(int)ap;
-(void) filterByUniqueness:(BOOL)unique;
-(void) filterByLimited:(BOOL)limited;
-(void) filterByAltArt:(BOOL)altart;

-(void) clearFilters;

-(TableData*) dataForTableView;

@end
