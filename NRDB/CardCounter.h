//
//  CardCounter.h
//  NRDB
//
//  Created by Gereon Steffens on 24.11.13.
//  Copyright (c) 2013 Gereon Steffens. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Card.h"

// a Card in a Deck: pointer to the card and a count
@interface CardCounter : NSObject <NSCoding>

@property (readonly) Card* card;
@property (nonatomic) int count;

+(CardCounter*) initWithCard:(Card*)card;
+(CardCounter*) initWithCard:(Card*)card andCount:(int)count;

@end
