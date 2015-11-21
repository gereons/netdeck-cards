//
//  DeckChange.swift
//  NetDeck
//
//  Created by Gereon Steffens on 14.11.15.
//  Copyright © 2015 Gereon Steffens. All rights reserved.
//

import Foundation

@objc(DeckChange) class DeckChange: NSObject, NSCoding {
    private(set) var code: String
    private(set) var count: Int = 0
    
    init(code: String, count: Int) {
        assert(count != 0, "count can't be 0")
        self.code = code
        self.count = count
    }

    var card: Card {
        return CardManager.cardByCode(code)
    }

    //MARK: NSCoding
    
    convenience required init?(coder aDecoder: NSCoder) {
        let count = aDecoder.decodeIntegerForKey("count")
        let code = aDecoder.decodeObjectForKey("code") as! String
        self.init(code: code, count: count)
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.code, forKey:"code");
        aCoder.encodeInteger(self.count, forKey:"count");
    }
}