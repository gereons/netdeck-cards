//
//  Hypergeometric.m
//  NRDB
//
//  Created by Gereon Steffens on 06.03.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "Hypergeometric.h"

@interface Binominal: NSObject
@end

@implementation  Binominal

// calculate the binominal coefficient (n over k)

+(unsigned long long) coefficientWithN:(int)n over:(int)k
{
    NSAssert(n>=0 && k>=0, @"negative");
    if (k == 0)
    {
        return 1;
    }
    if (n == 0 || k > n)
    {
        return 0;
    }

    if ((2*k) > n)
    {
        return [Binominal coefficientWithN:n over:n-k];
    }
    else
    {
        unsigned long long result = n - k + 1;
        for (int i=2; i<=k; ++i)
        {
            result *= (n-k+i);
            result /= i;
        }
        return result;
    }
}

@end

@implementation Hypergeometric

+(double) getProbabilityFor:(int)desiredCards cardsInDeck:(int)cardsInDeck desiredCardsInDeck:(int)desiredCardsInDeck cardsDrawn:(int)cardsDrawn
{
    double r = 0;
    
    for (; desiredCards<=cardsDrawn; desiredCards++)
    {
        r += [Hypergeometric get:desiredCards cardsInDeck:cardsInDeck desiredCardsInDeck:desiredCardsInDeck cardsDrawn:cardsDrawn];
    }
    return r;
}

+(double) get:(int)desiredCards cardsInDeck:(int)cardsInDeck desiredCardsInDeck:(int)desiredCardsInDeck cardsDrawn:(int)cardsDrawn
{
    if (desiredCards==0 || cardsInDeck==0 || desiredCardsInDeck==0 || cardsDrawn==0)
    {
        return 0;
    }

    double d = [Binominal coefficientWithN:cardsInDeck over:cardsDrawn];
    if (d == 0)
    {
        return 0;
    }

    double b1 = [Binominal coefficientWithN:desiredCardsInDeck over:desiredCards];
    double b2 = [Binominal coefficientWithN:cardsInDeck-desiredCardsInDeck over:cardsDrawn-desiredCards];
    return b1 * b2 / d;
}


@end
