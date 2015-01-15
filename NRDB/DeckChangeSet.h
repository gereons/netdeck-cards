//
//  DeckChangeSet.h
//  NRDB
//
//  Created by Gereon Steffens on 22.11.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

@class Card;

@interface DeckChangeSet : NSObject <NSCoding>

@property NSDate* timestamp;
@property NSMutableArray* changes;
@property BOOL initial;
@property NSMutableDictionary* cards;

-(void) addCardCode:(NSString*)code copies:(NSInteger)copies;
-(void) coalesce;
-(void) sort;
-(void) dump;

@end