//
//  Hypergeometric.swift
//  NetDeck
//
//  Created by Gereon Steffens on 13.12.15.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import Foundation

class Hypergeometric: NSObject {
    class func getProbabilityFor(_ desiredCards: Int, cardsInDeck: Int, desiredCardsInDeck: Int, cardsDrawn: Int) -> Double {
        assert(desiredCards>0 && cardsInDeck>0 && desiredCardsInDeck>0 && cardsDrawn>0)
        var r = 0.0
        for dc in desiredCards ... cardsDrawn {
            r += probabilityFor(dc, cardsInDeck, desiredCardsInDeck, cardsDrawn)
        }
        return min(r, 1.0)
    }
    
    private class func probabilityFor(_ desiredCards: Int, _ cardsInDeck: Int, _ desiredCardsInDeck: Int, _ cardsDrawn: Int) -> Double {
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
    
    private class func coefficientFor(_ n: Int, over k: Int) -> Double {
        assert(n>=0 && k>=0)
        
        if k == 0 { return 1.0 }
        if n == 0 || k > n { return 0.0 }
        
        if 2*k > n {
            return coefficientFor(n, over: n-k)
        } else {
            var result = Double(n - k + 1)
            if k > 1 {
                for i in 2 ... k {
                    result *= Double(n-k+i)
                    result /= Double(i)
                }
            }
            return result
        }
    }
}
