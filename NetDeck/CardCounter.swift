//
//  CardCounter.swift
//  NetDeck
//
//  Created by Gereon Steffens on 14.11.15.
//  Copyright © 2021 Gereon Steffens. All rights reserved.
//

import Foundation

@objc(CardCounter) class CardCounter: NSObject, NSCoding, NSCopying {
    @objc let card: Card
    var count: Int
    
    private static let nullInstance = CardCounter(card: Card.null(), count: 0)
    
    init(card: Card, count: Int) {
        self.card = card
        self.count = count
    }
    
    static func null() -> CardCounter {
        return nullInstance
    }
    
    var isNull: Bool {
        return self === CardCounter.nullInstance || self.card.isNull
    }

    func displayName(_ mwl: Int) -> String {
        if self.card.type == .identity {
            return self.card.displayName(mwl)
        } else {
            return self.card.displayName(mwl, count: self.count)
        }
    }
    
    // MARK: NSCoding
    convenience required init?(coder aDecoder: NSCoder) {
        let code = aDecoder.decodeObject(forKey: "card") as! String
        let count = aDecoder.decodeInteger(forKey: "count")
        let card = CardManager.cardBy(code, useReplacements: false) ?? Card.null()
        
        self.init(card: card, count: card.isNull ? 0 : count)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.count, forKey: "count")
        aCoder.encode(self.card.code, forKey: "card")
    }

    // MARK: NSCopying
    func copy(with zone: NSZone?) -> Any {
        return CardCounter(card: self.card, count: self.count)
    }
}
