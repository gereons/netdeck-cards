//
//  CardCounter.h
//  NRDB
//
//  Created by Gereon Steffens on 24.11.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Card.h"

// a Card in a Deck: the card itself, a counter and a "show alt art" toggle
@interface CardCounter : NSObject <NSCoding>

@property (readonly) Card* card;
@property (nonatomic) NSUInteger count;
@property BOOL showAltArt;

+(CardCounter*) initWithCard:(Card*)card;
+(CardCounter*) initWithCard:(Card*)card andCount:(int)count;

@end
