//
//  Hypergeometric.h
//  Net Deck
//
//  Created by Gereon Steffens on 06.03.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

@interface Hypergeometric : NSObject

+(double) getProbabilityFor:(NSUInteger)desiredCards cardsInDeck:(NSUInteger)cardsInDeck desiredCardsInDeck:(NSUInteger)desiredCardsInDeck cardsDrawn:(NSUInteger)cardsDrawn;

@end
