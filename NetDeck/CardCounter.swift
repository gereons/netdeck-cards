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
    
    init(card: Card, andCount: Int) {
        self.card = card
        self.count = andCount
    }
    
    // MARK: NSCoding
    convenience required init?(coder aDecoder: NSCoder) {
        let code = aDecoder.decodeObjectForKey("card") as! String
        let card = Card(byCode: code)
        let count = aDecoder.decodeIntegerForKey("count")
        
        self.init(card: card, andCount: count)

    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeInteger(self.count, forKey:"count");
        aCoder.encodeObject(self.card.code, forKey:"card");
    }
}
