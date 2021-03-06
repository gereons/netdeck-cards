//
//  DeckChange.swift
//  NetDeck
//
//  Created by Gereon Steffens on 14.11.15.
//  Copyright © 2021 Gereon Steffens. All rights reserved.
//

import Foundation

@objc(DeckChange) class DeckChange: NSObject, NSCoding, NSCopying {
    private(set) var code: String
    private(set) var count: Int
    
    init(code: String, count: Int) {
        // assert(count != 0, "count can't be 0")
        self.code = code
        self.count = count
    }

    var card: Card {
        return CardManager.cardBy(code) ?? Card.null()
    }

    //MARK: NSCoding
    
    convenience required init?(coder aDecoder: NSCoder) {
        let count = aDecoder.decodeInteger(forKey: "count")
        let code = aDecoder.decodeObject(forKey: "code") as! String
        self.init(code: code, count: count)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.code, forKey:"code")
        aCoder.encode(self.count, forKey:"count")
    }
    
    // MARK: NSCopying
    
    func copy(with zone: NSZone?) -> Any {
        return DeckChange(code: self.code, count: self.count)
    }
}
