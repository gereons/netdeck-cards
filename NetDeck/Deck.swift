//
//  Deck.swift
//  NetDeck
//
//  Created by Gereon Steffens on 28.11.15.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import Foundation

@objc(Deck) class Deck: NSObject, NSCoding {

    var filename: String?
    var tags: [String]?
    var revisions: [DeckChangeSet]?
    var lastModified: NSDate?
    var dateCreated: NSDate?

    private(set) var cards = [CardCounter]()
    private(set) var identityCc: CardCounter?
    private(set) var modified = false
    private(set) var isDraft = false
    
    private var sortType: NRDeckSort = .Type
    private var lastChanges = DeckChangeSet()

    override init() {
        self.state = NSUserDefaults.standardUserDefaults().boolForKey(SettingsKeys.CREATE_DECK_ACTIVE) ? NRDeckState.Active : NRDeckState.Testing
    }
    
    var allCards: [CardCounter] {
        var all = [CardCounter]()
        if let id = self.identityCc {
            all.append(id)
        }
        all.appendContentsOf(cards)
        return all
    }
    
    var identity: Card? {
        return identityCc?.card
    }
    
    var name: String? {
        willSet { modified = true }
    }
    
    var state = NRDeckState.None {
        willSet { modified = true }
    }
    
    var netrunnerDbId: String? {
        willSet { modified = true }
    }
    
    var notes: String? {
        willSet { modified = true }
    }
    
    var role = NRRole.None {
        willSet { modified = true }
    }
    
    var size: Int {
        var sz = 0
        for cc in cards {
            sz += cc.count
        }
        return sz
    }
    
    var agendaPoints: Int {
        var ap = 0
        for cc in cards {
            if cc.card.type == .Agenda {
                ap += cc.card.agendaPoints * cc.count
            }
        }
        return ap
    }
    
    var influence: Int {
        var inf = 0
        for cc in cards {
            if cc.card.faction != self.identity?.faction && cc.card.influence != -1 {
                inf += self.influenceFor(cc)
            }
        }
        return inf
    }
    
    func saveToDisk() {
        DeckManager.saveDeck(self)
        self.modified = false
    }
    
    var influenceLimit: Int {
        if self.identity == nil {
            return 0
        }
        
        if NSUserDefaults.standardUserDefaults().boolForKey(SettingsKeys.USE_NAPD_MWL) {
            let limit = self.identity!.influenceLimit
            return max(1, limit - self.mwlPenalty)
        } else {
            return self.identity!.influenceLimit
        }
    }
    
    /// how many cards in this deck are on the MWL?
    var cardsFromMWL: Int {
        var mwl = 0
        for cc in cards {
            if cc.card.isMostWanted {
                mwl += cc.count
            }
        }
        return mwl
    }
    
    /// what's the influence penalty incurred through MWL cards?
    /// (separate from `cardsFromMWL` in case we ever get rules other than "1 inf per card")
    var mwlPenalty: Int {
        return self.cardsFromMWL
    }
    
    func influenceFor(cardcounter: CardCounter?) -> Int {
        guard let cc = cardcounter else { return 0 }

        if self.identity?.faction == cc.card.faction || cc.card.influence == -1 {
            return 0
        }
        
        var count = cc.count
        if cc.card.type == .Program && self.identity?.code == Card.THE_PROFESSOR {
            --count
        }
        
        // alliance rules for corp
        if self.role == .Corp {
            // mumba temple: 0 inf if 15 or fewer ICE
            if cc.card.code == Card.MUMBA_TEMPLE && self.iceCount() <= 15 {
                return 0
            }
            // pad factory: 0 inf if 3 PAD Campaigns in deck
            if cc.card.code == Card.PAD_FACTORY && self.padCampaignCount() == 3 {
                return 0
            }
            // mumbad virtual tour: 0 inf if 7 or more assets
            if cc.card.code == Card.MUMBAD_VIRTUAL_TOUR && self.assetCount() >= 7 {
                return 0
            }
            // museum of history: 0 inf if >= 50 cards in deck
            if cc.card.code == Card.MUSEUM_OF_HISTORY && self.size >= 50 {
                return 0
            }
            // alliance-based cards: 0 inf if >=6 non-alliance cards of same faction in deck
            if Card.ALLIANCE_6.contains(cc.card.code) && self.nonAllianceOfFaction(cc.card.faction) >= 6 {
                return 0
            }
        }
        
        return count * cc.card.influence
    }
    
    func nonAllianceOfFaction(faction: NRFaction) -> Int {
        var count = 0
        for cc in cards {
            if cc.card.faction == faction && !cc.card.isAlliance {
                count += cc.count
            }
        }
        return count
    }
    
    func padCampaignCount() -> Int {
        if let padIndex = self.indexOfCardCode(Card.PAD_CAMPAIGN) {
            let pad = cards[padIndex]
            return pad.count
        }
        return 0
    }
    
    func iceCount() -> Int {
        return self.typeCount(.Ice)
    }
    
    func assetCount() -> Int {
        return self.typeCount(.Asset)
    }
    
    func typeCount(type: NRCardType) -> Int {
        var count = 0
        for cc in cards {
            if cc.card.type == type {
                count += cc.count
            }
        }
        return count
    }
    
    func addCard(card: Card, copies: Int) {
        self.addCard(card, copies: copies, history: true)
    }
    
    // add (copies>0) or remove (copies<0) a copy of a card from the deck
    // if copies==0, removes ALL copies of the card
    func addCard(card: Card, var copies: Int, history: Bool) {
        self.modified = true

        if card.type == .Identity {
            self.setIdentity(card, copies: copies, history: history)
            return
        }
        
        var cc: CardCounter?
        let cardIndex = self.indexOfCardCode(card.code)
        if cardIndex != nil {
            cc = cards[cardIndex!]
        }
        
        if copies < 1 {
            if cc != nil {
                if copies == 0 || abs(copies) >= cc!.count {
                    cards.removeAtIndex(cardIndex!)
                    copies = -cc!.count
                } else {
                    cc!.count -= abs(copies)
                }
            }
        } else {
            if cc == nil {
                cc = CardCounter(card: card, andCount: copies)
                cards.append(cc!)
            } else {
                let max = cc!.card.maxPerDeck
                if cc!.count < max {
                    cc!.count = min(max, cc!.count + copies)
                }
            }
        }
        
        if history && cc != nil {
            self.lastChanges.addCardCode(cc!.card.code, copies: copies)
        }
        
        self.sort()
    }
    
    func setIdentity(identity: Card?, copies: Int, history: Bool) {
        if self.identityCc != nil && history {
            // record removal of existing identity
            self.lastChanges.addCardCode(self.identityCc!.card.code, copies: -1)
        }
        if let id = identity where copies > 0 {
            if history {
                self.lastChanges.addCardCode(id.code, copies: 1)
            }
            
            self.identityCc = CardCounter(card: id, andCount: 1)
            if self.role != .None {
                assert(self.role == id.role, "role mismatch")
            }
            self.role = id.role
        } else {
            self.identityCc = nil
        }
        self.isDraft = identity?.setCode == CardSets.DRAFT_SET_CODE
    }
    
    func indexOfCardCode(code: String) -> Int? {
        return cards.indexOf { $0.card.code == code }
    }
    
    func findCard(card: Card) -> CardCounter? {
        if let index = self.indexOfCardCode(card.code) {
            return cards[index]
        }
        return nil
    }
    
    func sort() {
        cards.sortInPlace { (cc1, cc2) -> Bool in
            let c1 = cc1.card
            let c2 = cc2.card
            
            if self.sortType == .SetType || self.sortType == .SetNum {
                if c1.setNumber != c2.setNumber { return c1.setNumber < c2.setNumber }
            }
            if self.sortType == .FactionType {
                if c1.faction != c2.faction { return c1.faction.rawValue < c2.faction.rawValue }
            }
            if self.sortType == .SetNum {
                return c1.number < c2.number
            }
            if c1.type != c2.type {
                return c1.type.rawValue < c2.type.rawValue
            }
            if c1.type == .Ice && c2.type == .Ice {
                return c1.iceType < c2.iceType
            }
            if c1.type == .Program && c2.type == .Program {
                return c1.programType < c2.programType
            }
            return c1.name.lowercaseString < c2.name.lowercaseString
        }
    }
    
    func checkValidity() -> [String] {
        var reasons = [String]()
        
        if self.identityCc == nil {
            reasons.append("No Identity".localized())
        } else {
            assert(self.identityCc?.count == 1, "identity count")
        }
        
        if !self.isDraft && self.influence > self.influenceLimit {
            reasons.append("Too much influence used".localized())
        }
        
        if self.size < self.identity?.minimumDecksize {
            reasons.append("Not enough cards".localized())
        }
        
        let role = self.identity?.role
        if role == .Corp {
            let apRequired = ((self.size / 5) + 1) * 2
            let ap = self.agendaPoints
            if ap != apRequired && ap != apRequired+1 {
                reasons.append(String(format: "AP must be %d or %d".localized(), apRequired, apRequired+1))
            }
        }
        
        let noJintekiAllowed = self.identity?.code == Card.CUSTOM_BIOTICS
        let isApex = self.identity?.code == Card.APEX
        var limitError = false, jintekiError = false, agendaError = false, apexError = false
        
        // check max 1 per deck restrictions
        for cc in self.cards {
            let card = cc.card
            
            if cc.count > card.maxPerDeck && !limitError {
                limitError = true
                reasons.append("Card limit exceeded".localized())
            }
            
            if role == .Corp {
                if noJintekiAllowed && card.faction == .Jinteki && !jintekiError {
                    jintekiError = true
                    reasons.append("Faction not allowed".localized())
                }
                
                if !self.isDraft && card.type == .Agenda && card.faction != .Neutral && card.faction != self.identity?.faction && !agendaError {
                    agendaError = true
                    reasons.append("Has out-of-faction agendas".localized())
                }
            }
            else if role == .Runner {
                if isApex && card.type == .Resource && !card.isVirtual && !apexError {
                    apexError = true
                    reasons.append("Has non-virtual resources".localized())
                }
            }
        }
        
        return reasons
    }
    
    func duplicate() -> Deck {
        let newDeck = Deck()
        
        let oldName = self.name ?? ""
        var newName = oldName + " " + "(Copy)".localized()
        
        let regexPattern = "\\d+$"
        let regex = try! NSRegularExpression(pattern:regexPattern, options:[])
        
        let matches = regex.matchesInString(oldName, options: [], range: NSMakeRange(0, oldName.length))
        if matches.count > 0 {
            let match = matches[0]
            let range = match.range.stringRangeForText(oldName)
            let numberStr = oldName.substringWithRange(range)
            let number = 1 + Int(numberStr)!
            
            newName = oldName.substringToIndex(oldName.startIndex.advancedBy(match.range.location))
            newName += "\(number)"
        }
        
        newDeck.name = newName
        if (self.identityCc != nil) {
            newDeck.identityCc = CardCounter(card: self.identity!, andCount: 1)
        }
        newDeck.isDraft = self.isDraft
        newDeck.cards = self.cards
        newDeck.role = self.role
        newDeck.filename = nil
        newDeck.state = self.state
        newDeck.notes = self.notes
        newDeck.lastChanges = self.lastChanges
        newDeck.revisions = self.revisions
        newDeck.modified = true
        
        return newDeck
    }
    
    func mergeRevisions() {
        self.lastChanges.coalesce()
        if self.lastChanges.changes.count > 0 {
            self.lastChanges.cards = [String: Int]()
            
            for cc in self.allCards {
                self.lastChanges.cards![cc.card.code] = cc.count
            }
            
            if self.revisions?.count == 0 {
                self.lastChanges.initial = true
            }
            
            self.revisions?.insert(self.lastChanges, atIndex: 0)
            
            self.lastChanges = DeckChangeSet()
        }
    }
    
    func resetToCards(cards: [String: Int]) {
        var newCards = [CardCounter]()
        var newIdentity: Card?
        
        for (code, qty) in cards {
            let card = CardManager.cardByCode(code)
            
            if card?.type != .Identity {
                let cc = CardCounter(card: card!, andCount: qty)
                newCards.append(cc)
            } else {
                assert(newIdentity == nil, "new identity already set")
                newIdentity = card!
            }
        }
        
        // figure out changes between this and the last saved state
        
        if self.revisions?.count > 0 {
            let dcs = self.revisions![0]
            let lastSavedCards = dcs.cards
            let lastSavedCodes = dcs.cards?.keys
            
            for code in lastSavedCodes! {
                let oldQty = lastSavedCards![code]
                let newQty = cards[code]
                
                if newQty == nil {
                    self.lastChanges .addCardCode(code, copies: -oldQty!)
                } else {
                    let diff = oldQty! - newQty!
                    if diff != 0 {
                        self.lastChanges.addCardCode(code, copies: diff)
                    }
                }
            }
            
            for code in cards.keys {
                if !lastSavedCodes!.contains(code) {
                    let newQty = cards[code]
                    self.lastChanges.addCardCode(code, copies: newQty!)
                }
            }
        }
        
        self.setIdentity(newIdentity, copies: 1, history: false)
        self.cards = newCards
        self.modified = true
    }
    
    func dataForTableView(sortType: NRDeckSort) -> TableData {
        self.sortType = sortType
        
        var sections = [String]()
        var cards = [[CardCounter]]()
        
        self.sort()
        
        sections.append(CardType.name(.Identity))
        if self.identityCc != nil {
            cards.append([self.identityCc!])
        } else {
            cards.append([CardCounter.null()])
        }
        
        var removals = [Card]()
        for cc in self.cards {
            assert(cc.count > 0, "found card with 0 copies")
            if (cc.count == 0) {
                removals.append(cc.card)
            }
        }
        for card in removals {
            self.addCard(card, copies: 0)
        }
        
        var prevSection = ""
        var arr: [CardCounter]?
        
        for cc in self.cards {
            var section: String
            
            switch self.sortType {
            case .Type:
                section = cc.card.typeStr
                if cc.card.type == .Ice {
                    section = cc.card.iceType!
                }
                if cc.card.type == .Program {
                    section = cc.card.programType!
                }
            case .SetType, .SetNum:
                section = cc.card.setName
            case .FactionType:
                section = cc.card.factionStr
            }
            
            if section != prevSection {
                sections.append(section)
                if arr != nil {
                    cards.append(arr!)
                }
                arr = [CardCounter]()
            }
            arr?.append(cc)
            prevSection = section
        }
        
        if arr?.count > 0 {
            cards.append(arr!)
        }
        
        assert(sections.count == cards.count, "count mismatch")
        
        return TableData(sections: sections, andValues: cards)
    }
    
    // MARK: NSCoding
    convenience required init?(coder decoder: NSCoder) {
        self.init()
        
        self.cards = decoder.decodeObjectForKey("cards") as! [CardCounter]
        
        // kill cards that we couldn't deserialize
        self.cards = self.cards.filter{ !$0.isNull || $0.count > 0 }
        
        self.netrunnerDbId = decoder.decodeObjectForKey("netrunnerDbId") as? String
        
        self.name = decoder.decodeObjectForKey("name") as? String
        self.role = NRRole(rawValue: decoder.decodeIntegerForKey("role"))!
        self.state = NRDeckState(rawValue: decoder.decodeIntegerForKey("state"))!
        self.isDraft = decoder.decodeBoolForKey("draft")
        if let identityCode = decoder.decodeObjectForKey("identity") as? String {
            if let identity = CardManager.cardByCode(identityCode) {
                self.identityCc = CardCounter(card:identity, andCount:1)
            }
        }
        self.lastModified = nil
        self.notes = decoder.decodeObjectForKey("notes") as? String
        self.tags = decoder.decodeObjectForKey("tags") as? [String]
        self.sortType = .Type
        
        if let lastChanges = decoder.decodeObjectForKey("lastChanges") as? DeckChangeSet {
            self.lastChanges = lastChanges
        } else {
            self.lastChanges = DeckChangeSet()
        }
        self.revisions = decoder.decodeObjectForKey("revisions") as? [DeckChangeSet]
        if self.revisions == nil {
            self.revisions = [DeckChangeSet]()
        }
        self.modified = false
    }
    
    func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(self.netrunnerDbId, forKey:"netrunnerDbId")
        coder.encodeObject(self.cards, forKey:"cards")
        coder.encodeObject(self.name, forKey:"name")
        coder.encodeInteger(self.role.rawValue, forKey:"role")
        coder.encodeInteger(self.state.rawValue, forKey:"state")
        coder.encodeBool(self.isDraft, forKey:"draft")
        if let idCode = self.identityCc?.card.code {
            coder.encodeObject(idCode, forKey:"identity")
        }
        coder.encodeObject(self.notes, forKey:"notes")
        coder.encodeObject(self.tags, forKey:"tags")
        coder.encodeObject(self.lastChanges, forKey:"lastChanges")
        coder.encodeObject(self.revisions, forKey:"revisions")
    }
}