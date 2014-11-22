//
//  DeckChangeSet.h
//  NRDB
//
//  Created by Gereon Steffens on 22.11.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Card;

@interface DeckChangeSet : NSObject <NSCoding>

@property NSDate* timestamp;
@property NSMutableArray* changes;

-(void) addCard:(Card*)card copies:(int)copies;
-(void) removeCard:(Card*)card copies:(int)copies;

-(void) coalesce;

@end
