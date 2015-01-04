//
//  DeckChange.h
//  NRDB
//
//  Created by Gereon Steffens on 22.11.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

@class Card;

@interface DeckChange : NSObject <NSCoding>

@property (readonly) NSString* code;
@property (readonly) NSInteger count;

@property (readonly) Card* card;

+(DeckChange*) forCode:(NSString*)code copies:(NSInteger)copies;

@end
