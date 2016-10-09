//
//  CardCounter.swift
//  NetDeck
//
//  Created by Gereon Steffens on 14.11.15.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import Foundation

@objc(CardCounter) class CardCounter: NSObject, NSCoding, NSCopying {
    let card: Card
    var count: Int
    
    fileprivate static let nullInstance = CardCounter(card: Card.null(), count: 0)
    
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
        let code = aDecoder.decodeObject(forKey: "card") as! String
        let count = aDecoder.decodeInteger(forKey: "count")
        let card = CardManager.cardBy(code: code) ?? Card.null()
        
        self.init(card: card, count: card.isNull ? 0 : count)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.count, forKey: "count")
        aCoder.encode(self.card.code, forKey: "card")
    }
    
    func copy(with zone: NSZone?) -> Any {
        return CardCounter(card: self.card, count: self.count)
    }
}
