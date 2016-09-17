//
//  DeckChangeSet.swift
//  NetDeck
//
//  Created by Gereon Steffens on 14.11.15.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import Foundation

@objc(DeckChangeSet) class DeckChangeSet: NSObject, NSCoding, NSCopying {
    var timestamp: NSDate?
    var changes = [DeckChange]()
    var initial: Bool = false
    var cards: [String: Int]?       // code -> qty
    
    func addCardCode(code: String, copies:Int) {
        assert(copies != 0, "changing 0 copies?")
        let dc = DeckChange(code:code, count:copies)
    
        self.changes.append(dc)
    }
    
    func coalesce() {
        if (self.changes.count == 0) {
            return
        }
        
        let sorted = self.changes.sort { (dc1, dc2) -> Bool in
            return dc1.code < dc2.code
        }
        
        var combinedChanges = [DeckChange]()
        var prevCode: String? = nil
        var count = 0
        for dc in sorted {
            if prevCode != nil && dc.code != prevCode {
                if (count != 0) {
                    let newDc = DeckChange(code: prevCode!, count: count)
                    combinedChanges.append(newDc)
                }
                
                count = 0
            }
            
            prevCode = dc.code
            count += dc.count
        }
        if prevCode != nil && count != 0 {
            let newDc = DeckChange(code: prevCode!, count: count)
            combinedChanges.append(newDc)
        }
        
        self.changes = combinedChanges
        self.sort()
        self.timestamp = NSDate()
        
        // self.dump()
    }
    
    func sort() {
        self.changes.sortInPlace { (dc1, dc2) -> Bool in
            if dc1.count > 0 && dc2.count < 0 { return true }
            if dc1.count < 0 && dc2.count > 0 { return false }
            let n1 = dc1.card?.name ?? ""
            let n2 = dc2.card?.name ?? ""
            return n1 < n2
        }
    }
    
    func dump() {
        NSLog("---- changes -----")
        for dc in self.changes {
            NSLog("%@ %ld %@", dc.count > 0 ? "add" : "rem",
                dc.count,
                dc.card!.name)
        }
        NSLog("---end---")
    }
    
    // MARK: NSCoding
    
    convenience required init?(coder aDecoder: NSCoder) {
        self.init()
        self.timestamp = aDecoder.decodeObjectForKey("timestamp") as? NSDate
        self.changes = aDecoder.decodeObjectForKey("changes") as! [DeckChange]
        self.initial = aDecoder.decodeBoolForKey("initial")
        self.cards = aDecoder.decodeObjectForKey("cards") as? [String: Int]
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.timestamp, forKey:"timestamp")
        aCoder.encodeObject(self.changes, forKey:"changes")
        aCoder.encodeBool(self.initial, forKey:"initial")
        aCoder.encodeObject(self.cards, forKey:"cards")
    }
    
    // MARK: NSCopying
    
    func copyWithZone(zone: NSZone) -> AnyObject {
        let dc = DeckChangeSet()
        dc.timestamp = self.timestamp
        dc.initial = self.initial
        dc.cards = self.cards
        dc.changes = self.changes.map({ $0.copy() as! DeckChange })
        return dc
    }
}