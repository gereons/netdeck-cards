//
//  CardCounter.swift
//  NetDeck
//
//  Created by Gereon Steffens on 14.11.15.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import Foundation

@objc(CardCounter) class CardCounter: NSObject, NSCoding {
    private(set) var card: Card
    var count: Int
    
    private static let nullInstance = CardCounter(card: Card.null(), count: 0)
    
    init(card: Card, count: Int) {
        self.card = card
        self.count = count
    }
    
    class func null() -> CardCounter {
        return nullInstance
    }
    
    var isNull: Bool {
        return self === CardCounter.nullInstance || self.card.isNull
    }
    
    // MARK: NSCoding
    convenience required init?(coder aDecoder: NSCoder) {
        let code = aDecoder.decodeObjectForKey("card") as! String
        let count = aDecoder.decodeIntegerForKey("count")
        let card = CardManager.cardByCode(code) ?? Card.null()
        
        self.init(card: card, count: card.isNull ? 0 : count)
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeInteger(self.count, forKey: "count")
        aCoder.encodeObject(self.card.code, forKey: "card")
    }
}
