//
//  Hypergeometric.swift
//  NetDeck
//
//  Created by Gereon Steffens on 13.12.15.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

@objc class Hypergeometric: NSObject {
    class func getProbabilityFor(desiredCards: Int, cardsInDeck: Int, desiredCardsInDeck: Int, cardsDrawn: Int) -> Double {
        assert(desiredCards>0 && cardsInDeck>0 && desiredCardsInDeck>0 && cardsDrawn>0)
        var r = 0.0
        for dc in desiredCards ... cardsDrawn {
            r += probabilityFor(dc, cardsInDeck, desiredCardsInDeck, cardsDrawn)
        }
        return min(r, 1.0)
    }
    
    private class func probabilityFor(desiredCards: Int, _ cardsInDeck: Int, _ desiredCardsInDeck: Int, _ cardsDrawn: Int) -> Double {
        assert(desiredCards>0 && cardsInDeck>0 && desiredCardsInDeck>0 && cardsDrawn>0)
        if desiredCards==0 || cardsInDeck==0 || desiredCardsInDeck==0 || cardsDrawn==0 {
            return 0.0
        }
        let d = coefficientFor(cardsInDeck, over: cardsDrawn)
        if d == 0.0 {
            return 0.0
        }
        
        let b1 = coefficientFor(desiredCardsInDeck, over: desiredCards)
        let b2 = coefficientFor(cardsInDeck-desiredCardsInDeck, over: cardsDrawn-desiredCards)
        return b1 * b2 / d
    }
    
    private class func coefficientFor(n: Int, over k: Int) -> Double {
        assert(n>=0 && k>=0)
        if k == 0 { return 1.0 }
        if n == 0 || k > n { return 0.0 }
        
        if 2*k > n {
            return coefficientFor(n, over: n-k)
        } else {
            var result = UInt64(n - k + 1)
            // for var i:UInt=2; i<=k; ++i {
            for i in 2 ... k {
                result *= UInt64(n-k+i)
                result /= UInt64(i)
            }
            return Double(result)
        }
    }
}