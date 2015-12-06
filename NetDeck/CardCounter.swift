//
//  CardCounter.swift
//  NetDeck
//
//  Created by Gereon Steffens on 14.11.15.
//  Copyright © 2015 Gereon Steffens. All rights reserved.
//

import Foundation

@objc(CardCounter) class CardCounter: NSObject, NSCoding {
    private(set) var card: Card
    var count: Int
    
    static let nullInstance = CardCounter(card: Card.null(), andCount: 0)
    
    init(card: Card, andCount: Int) {
        self.card = card
        self.count = andCount
    }
    
    class func null() -> CardCounter {
        return nullInstance
    }
    
    var isNull: Bool {
        return self == CardCounter.nullInstance
    }
    
    // MARK: NSCoding
    convenience required init?(coder aDecoder: NSCoder) {
        let code = aDecoder.decodeObjectForKey("card") as! String
        let card = CardManager.cardByCode(code)
        let count = aDecoder.decodeIntegerForKey("count")
        
        self.init(card: card!, andCount: count)

    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeInteger(self.count, forKey:"count");
        aCoder.encodeObject(self.card.code, forKey:"card");
    }
}
