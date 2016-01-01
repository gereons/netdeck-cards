//
//  Hypergeometric.swift
//  NetDeck
//
//  Created by Gereon Steffens on 13.12.15.
//  Copyright © 2015 Gereon Steffens. All rights reserved.
//

@objc class Hypergeometric: NSObject {
    class func getProbabilityFor(desiredCards: UInt, cardsInDeck: UInt, desiredCardsInDeck: UInt, cardsDrawn: UInt) -> Double {
        var r = 0.0
        for dc in desiredCards ... cardsDrawn {
            r += probabilityFor(dc, cardsInDeck, desiredCardsInDeck, cardsDrawn)
        }
        return min(r, 1.0)
    }
    
    class func probabilityFor(desiredCards: UInt, _ cardsInDeck: UInt, _ desiredCardsInDeck: UInt, _ cardsDrawn: UInt) -> Double {
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
    
    class func coefficientFor(n: UInt, over k: UInt) -> Double {
        if k == 0 { return 1.0 }
        if n == 0 || k > n { return 0.0 }
        
        if 2*k > n {
            return coefficientFor(n, over: n-k)
        } else {
            var result = UInt64(n-k+1)
            if k > 1 {
                for i in 2 ... k {
                    result *= UInt64(n-k+i)
                    result /= UInt64(i)
                }
            }
            return Double(result)
        }
    }
}