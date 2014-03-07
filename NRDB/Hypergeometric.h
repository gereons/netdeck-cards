//
//  Hypergeometric.h
//  NRDB
//
//  Created by Gereon Steffens on 06.03.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Hypergeometric : NSObject

+(double) getProbabilityFor:(int)desiredCards cardsInDeck:(int)cardsInDeck desiredCardsInDeck:(int)desiredCardsInDeck cardsDrawn:(int)cardsDrawn;

@end
