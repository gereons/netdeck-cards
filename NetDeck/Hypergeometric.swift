//
//  Hypergeometric.swift
//  NetDeck
//
//  Created by Gereon Steffens on 13.12.15.
//  Copyright © 2021 Gereon Steffens. All rights reserved.
//

import Foundation

final class Hypergeometric {
    static func getProbabilityFor(_ desiredCards: Int, cardsInDeck: Int, desiredCardsInDeck: Int, cardsDrawn: Int) -> Double {
        assert(desiredCards>0 && cardsInDeck>0 && desiredCardsInDeck>0 && cardsDrawn>0)
        var r = 0.0
        for dc in desiredCards ... cardsDrawn {
            r += probabilityFor(dc, cardsInDeck, desiredCardsInDeck, cardsDrawn)
        }
        return min(r, 1.0)
    }
    
    private static func probabilityFor(_ desiredCards: Int, _ cardsInDeck: Int, _ desiredCardsInDeck: Int, _ cardsDrawn: Int) -> Double {
        if desiredCards==0 || cardsInDeck==0 || desiredCardsInDeck==0 || cardsDrawn==0 {
            return 0.0
        }
        let d = coefficient(for: cardsInDeck, over: cardsDrawn)
        if d == 0.0 {
            return 0.0
        }
        
        let b1 = coefficient(for: desiredCardsInDeck, over: desiredCards)
        let b2 = coefficient(for: cardsInDeck-desiredCardsInDeck, over: cardsDrawn-desiredCards)
        return b1 * b2 / d
    }
    
    private static func coefficient(for n: Int, over k: Int) -> Double {
        assert(n>=0 && k>=0)
        
        if k == 0 { return 1.0 }
        if n == 0 || k > n { return 0.0 }
        
        if 2*k > n {
            return coefficient(for: n, over: n-k)
        } else {
            var result = Double(n - k + 1)
            if k > 1 {
                for i in 2 ... k {
                    result *= Double(n - k + i)
                    result /= Double(i)
                }
            }
            return result
        }
    }
}
