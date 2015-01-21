//
//  CardCounter.h
//  NRDB
//
//  Created by Gereon Steffens on 24.11.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "Card.h"

// a Card in a Deck: the card itself, and a count
@interface CardCounter : NSObject <NSCoding>

@property (readonly, nonatomic) Card* card;
@property (nonatomic) NSInteger count;

+(CardCounter*) initWithCard:(Card*)card;
+(CardCounter*) initWithCard:(Card*)card andCount:(NSInteger)count;

@end
