//
//  Deck.swift
//  NetDeck
//
//  Created by Gereon Steffens on 28.11.15.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import Foundation
import Marshal
import SwiftyUserDefaults

@objc(Deck) class Deck: NSObject, NSCoding, Unmarshaling {

    var filename: String?
    var revisions = [DeckChangeSet]()
    var lastModified: Date?
    var dateCreated: Date?

    @objc private(set) var cards = [CardCounter]()
    private(set) var identityCc: CardCounter?
    private(set) var modified = false
    private(set) var isDraft = false
    
    private var lastChanges = DeckChangeSet()
    fileprivate(set) var convertedToCore2 = false
    
    override private init() {}
    
    init(role: Role) {
        self.state = Defaults[.createDeckActive] ? .active : .testing
        let seq = DeckManager.fileSequence() + 1
        self.name = "Deck #\(seq)"
        self.mwl = Defaults[.defaultMWL]
        self.role = role
    }
    
    var allCards: [CardCounter] {
        var all = self.cards
        if let id = self.identityCc {
            all.insert(id, at: 0)
        }
        return all
    }
    
    @objc var identity: Card? {
        return identityCc?.card
    }
    
    @objc var name: String = "" {
        willSet { modified = true }
    }
    
    @objc var state = DeckState.none {
        willSet { modified = true }
    }
    
    var netrunnerDbId: String? {
        willSet { modified = true }
    }
    
    var notes: String? {
        willSet { modified = true }
    }
    
    private(set) var role = Role.none {
        willSet { modified = true }
    }
    
    var mwl = MWL.none {
        willSet { modified = true }
    }

    var onesies: Bool = false {
        willSet { modified = true }
    }
    
    var cacheRefresh: Bool = false {
        willSet { modified = true }
    }
    
    var size: Int {
        return self.cards.reduce(0) { $0 + $1.count }
    }
    
    var agendaPoints: Int {
        return self.cards
            .filter { $0.card.type == .agenda}
            .reduce(0) { $0 + $1.card.agendaPoints * $1.count }
    }
    
    var influence: Int {
        return self.cards.reduce(0) { $0 + self.influenceFor($1) }
    }
    
    var influenceLimit: Int {
        if let identity = self.identity {
            return max(1, identity.influenceLimit - self.mwlPenalty)
        } else {
            return 0
        }
    }
        
    /// what's the influence penalty incurred through MWL cards?
    var mwlPenalty: Int {
        if self.mwl.universalInfluence {
            return 0
        }
        return cards.reduce(0) { $0 + $1.card.mwlPenalty(self.mwl) * $1.count }
    }
    
    func influenceFor(_ cc: CardCounter) -> Int {
        let influence = cardInfluenceFor(cc)
        let universal = self.universalInfluenceFor(cc)
        return influence + universal
    }
    
    func universalInfluenceFor(_ cc: CardCounter) -> Int {
        if self.mwl.universalInfluence {
            var count = cc.count
            if cc.card.type == .program && self.identity?.code == Card.theProfessor {
                count -= 1
            }
            return cc.card.mwlPenalty(self.mwl) * count
        } else {
            return 0
        }
    }
    
    private func cardInfluenceFor(_ cc: CardCounter) -> Int {
        if self.identity?.faction == cc.card.faction || cc.card.influence == -1 {
            return 0
        }
        
        var count = cc.count
        if cc.card.type == .program && self.identity?.code == Card.theProfessor {
            count -= 1
        }
        
        // alliance rules for corp
        if self.role == .corp {
            // mumba temple: 0 inf if 15 or fewer ICE
            if cc.card.code == Card.mumbaTemple && self.iceCount() <= 15 {
                return 0
            }
            // pad factory: 0 inf if 3 PAD Campaigns in deck
            if cc.card.code == Card.padFactory && self.padCampaignCount() == 3 {
                return 0
            }
            // mumbad virtual tour: 0 inf if 7 or more assets
            if cc.card.code == Card.mumbadVirtualTour && self.assetCount() >= 7 {
                return 0
            }
            // museum of history: 0 inf if >= 50 cards in deck
            if cc.card.code == Card.museumOfHistory && self.size >= 50 {
                return 0
            }
            // alliance-based cards: 0 inf if >=6 non-alliance cards of same faction in deck
            if Card.alliance6.contains(cc.card.code) && self.nonAllianceOfFaction(cc.card.faction) >= 6 {
                return 0
            }
        }
        
        return count * cc.card.influence
    }
    
    private func nonAllianceOfFaction(_ faction: Faction) -> Int {
        return self.cards
            .filter { $0.card.faction == faction && !$0.card.isAlliance }
            .reduce(0) { $0 + $1.count }
    }
    
    private func padCampaignCount() -> Int {
        if let padIndex = self.indexOfCardCode(Card.padCampaign) {
            let pad = cards[padIndex]
            return pad.count
        } else if let padIndex = self.indexOfCardCode(Card.padCampaignCore2) {
            let pad = cards[padIndex]
            return pad.count
        }
        return 0
    }
    
    private func iceCount() -> Int {
        return self.typeCount(.ice)
    }
    
    private func assetCount() -> Int {
        return self.typeCount(.asset)
    }
    
    private func typeCount(_ type: CardType) -> Int {
        return cards.filter({ $0.card.type == type}).reduce(0) { $0 + $1.count }
    }
    
    /// add (`copies>0`) or remove (`copies<0`) a copy of a card from the deck
    /// if `copies==0`, removes ALL copies of the card
    func addCard(_ card: Card, copies: Int) {
        self.addCard(card, copies: copies, history: true)
    }
    
    /// add (copies>0) or remove (copies<0) a copy of a card from the deck
    /// if copies==0, removes ALL copies of the card
    func addCard(_ card: Card, copies: Int, history: Bool) {
        
        var changed = false
        var copies = copies
        if card.type == .identity {
            self.modified = true
            self.setIdentity(card, copies: copies, history: history)
            return
        }
        
        if let cardIndex = self.indexOfCardCode(card.code) {
            // modify an existing card
            let cc = self.cards[cardIndex]
            
            if copies < 1 {
                // remove N (or all) copies of card
                if copies == 0 || abs(copies) >= cc.count {
                    cards.remove(at: cardIndex)
                    copies = -cc.count
                } else {
                    cc.count -= abs(copies)
                }
                changed = true
            } else {
                // add N copies
                let max = self.isDraft ? 100 : cc.card.maxPerDeck
                let maxAdd = max - cc.count
                copies = min(copies, maxAdd)
                cc.count += copies
                changed = copies != 0
            }
        } else {
            // add a new card
            assert(copies > 0, "removing a card that isn't in deck")
            copies = min(copies, card.maxPerDeck)
            let cc = CardCounter(card: card, count: copies)
            cards.append(cc)
            changed = true
        }
        
        // print("copies=\(copies) of \(card.name)")
        if history && copies != 0 {
            self.lastChanges.addCardCode(card.code, copies: copies)
        }
        
        self.modified = self.modified || changed
    }
    
    private func setIdentity(_ identity: Card?, copies: Int, history: Bool) {
        if self.identityCc != nil && history {
            // record removal of existing identity
            self.lastChanges.addCardCode(self.identityCc!.card.code, copies: -1)
        }
        // print("\(self.name) set id to \(String(describing: identity?.name))")
        if let id = identity, copies > 0 {
            if history {
                self.lastChanges.addCardCode(id.code, copies: 1)
            }
            
            self.identityCc = CardCounter(card: id, count: 1)
            if self.role != .none {
                assert(self.role == id.role, "role mismatch")
            }
            self.role = id.role
        } else {
            self.identityCc = nil
        }
        self.isDraft = identity?.faction == .neutral
    }
    
    private func indexOfCardCode(_ code: String) -> Int? {
        return self.cards.index { $0.card.code == code }
    }
    
    func findCard(_ card: Card) -> CardCounter? {
        if let index = self.indexOfCardCode(card.code) {
            return self.cards[index]
        }
        return nil
    }
    
    private func sort(by sortOrder: DeckSort) {
        self.cards.sort { cc1, cc2 in
            let c1 = cc1.card
            let c2 = cc2.card
            
            if sortOrder == .bySetType || sortOrder == .bySetNum {
                if c1.packNumber != c2.packNumber {
                    return c1.packNumber < c2.packNumber
                }
            }
            if sortOrder == .byFactionType {
                if c1.faction != c2.faction {
                    return c1.faction.rawValue < c2.faction.rawValue
                }
            }
            if sortOrder == .bySetNum {
                return c1.number < c2.number
            }
            if c1.type != c2.type {
                return c1.type.rawValue < c2.type.rawValue
            }
            if c1.type == .ice && c2.type == .ice {
                if c1.iceType != c2.iceType {
                    return c1.iceType < c2.iceType
                }
            }
            if c1.type == .program && c2.type == .program {
                if c1.programType != c2.programType {
                    return c1.programType < c2.programType
                }
            }
            
            return c1.foldedName < c2.foldedName
        }
    }
    
    func duplicate() -> Deck {
        let newDeck = Deck()
        
        let oldName = self.name
        var newName = oldName + " " + "(Copy)".localized()

        let regex = try! NSRegularExpression(pattern: "\\d+$", options:[])
        let matches = regex.matches(in: oldName, options: [], range: NSMakeRange(0, oldName.count))
        if matches.count > 0 {
            let match = matches[0]
            let range = match.range.stringRangeForText(oldName)
            let numberStr = oldName[range]
            let number = 1 + Int(numberStr)!

            newName = String(oldName[..<oldName.index(oldName.startIndex, offsetBy: match.range.location)])
            newName += "\(number)"
        }
        
        newDeck.name = newName
        if (self.identityCc != nil) {
            newDeck.identityCc = CardCounter(card: self.identity!, count: 1)
        }
        newDeck.isDraft = self.isDraft
        newDeck.cards = self.cards.map({ $0.copy() as! CardCounter })
        newDeck.role = self.role
        newDeck.filename = nil
        newDeck.state = self.state
        newDeck.notes = self.notes
        newDeck.mwl = self.mwl
        newDeck.lastChanges = self.lastChanges.copy() as! DeckChangeSet
        newDeck.revisions = self.revisions.map({ $0.copy() as! DeckChangeSet })
        newDeck.modified = true
        newDeck.convertedToCore2 = self.convertedToCore2
        
        return newDeck
    }
    
    func mergeRevisions() {
        self.lastChanges.coalesce()
        if self.lastChanges.changes.count > 0 {
            self.lastChanges.cards = [:]
            
            for cc in self.allCards {
                self.lastChanges.cards[cc.card.code] = cc.count
            }
            
            if self.revisions.count == 0 {
                self.lastChanges.initial = true
            }
            
            self.revisions.insert(self.lastChanges, at: 0)
            
            self.lastChanges = DeckChangeSet()
        }
    }
    
    func resetToCards(_ cards: [String: Int]) {
        var newCards = [CardCounter]()
        var newIdentity: Card?
        
        for (code, qty) in cards {
            if let card = CardManager.cardBy(code: code) {
                if card.type != .identity {
                    let cc = CardCounter(card: card, count: qty)
                    newCards.append(cc)
                } else {
                    assert(newIdentity == nil, "new identity already set")
                    newIdentity = card
                }
            }
        }
        
        // figure out changes between this and the last saved state
        if self.revisions.count > 0 {
            let dcs = self.revisions[0]
            
            for (code, oldQty) in dcs.cards {
                let newQty = cards[code]
                
                if newQty == nil {
                    self.lastChanges.addCardCode(code, copies: -oldQty)
                } else {
                    let diff = oldQty - newQty!
                    if diff != 0 {
                        self.lastChanges.addCardCode(code, copies: diff)
                    }
                }
            }
            
            for code in cards.keys {
                if !dcs.cards.keys.contains(code) {
                    let newQty = cards[code]
                    self.lastChanges.addCardCode(code, copies: newQty!)
                }
            }
        }

        self.setIdentity(newIdentity, copies: 1, history: false)
        self.cards = newCards
        self.modified = true
    }
    
    func dataForTableView(_ sortOrder: DeckSort) -> TableData<CardCounter> {
        var sections = [String]()
        var cards = [[CardCounter]]()
        
        self.sort(by: sortOrder)
        
        sections.append(CardType.name(for: .identity))
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
        
        var current = [CardCounter]()
        for cc in self.cards {
            if current.isEmpty || self.section(cc, sortOrder) == self.section(current[0], sortOrder) {
                current.append(cc)
            } else {
                sections.append(self.section(current[0], sortOrder))
                cards.append(current)
                current = [cc]
            }
        }
        if !current.isEmpty {
            sections.append(self.section(current[0], sortOrder))
            cards.append(current)
        }
        
        return TableData(sections: sections, values: cards)
    }
    
    private func section(_ cc: CardCounter, _ sortOrder: DeckSort) -> String {
        let card = cc.card
        switch sortOrder {
        case .byType:
            switch card.type {
            case .ice:
                return card.iceType
            case .program:
                return card.programType
            default:
                return card.typeStr
            }
        case .bySetType, .bySetNum:
            return card.packName
        case .byFactionType:
            return card.factionStr
        }
    }
    
    func saveToDisk() {
        DeckManager.saveDeck(self, keepLastModified: false)
        self.modified = false
    }
    
    func updateOnDisk() {
        DeckManager.saveDeck(self, keepLastModified: true)
        self.modified = false
    }
    
    // MARK: create deck from JSON
    
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ssZ'"
        formatter.timeZone = TimeZone(identifier: "GMT")
        return formatter
    }()

    convenience required init(object: MarshaledObject) throws {
        self.init()
        
        self.state = Defaults[.createDeckActive] ? .active : .testing
        self.name = try object.value(for: "name")
        self.notes = try object.value(for: "description")
        let id: Int = try object.value(for: "id")
        self.netrunnerDbId = "\(id)"
        
        // parse last update '2014-06-19T13:52:24+00:00'
        self.lastModified = Deck.dateFormatter.date(from: try object.value(for: "date_update"))
        self.dateCreated = Deck.dateFormatter.date(from: try object.value(for: "date_creation"))
        
        if let mwlCode: String = try? object.value(for: "mwl_code") {
            self.mwl = MWL.by(code: mwlCode)
        } else {
            self.mwl = Defaults[.defaultMWL]
        }
        
        if let cards = object.optionalAny(for: "cards") as? [String: Int] {
            for (code, qty) in cards {
                if let card = CardManager.cardBy(code: code) {
                    self.addCard(card, copies:qty, history: false)
                }
            }
        }
        
        typealias HistoryData = [String: [String: Int]]
        let history: HistoryData = object.optionalAny(for: "history") as? HistoryData ?? HistoryData()
        
        var revisions = [DeckChangeSet]()
        for (date, changes) in history {
            if let timestamp = Deck.dateFormatter.date(from: date) {
                let dcs = DeckChangeSet()
                dcs.timestamp = timestamp
                
                for (code, amount) in changes {
                    if let card = CardManager.cardBy(code: code) {
                        dcs.addCardCode(card.code, copies: amount)
                    }
                }
                
                dcs.sort()
                revisions.append(dcs)
            }
        }
        
        revisions.sort { $0.timestamp?.timeIntervalSince1970 ?? 0 < $1.timestamp?.timeIntervalSinceNow ?? 0 }
        
        let initial = DeckChangeSet()
        initial.initial = true
        initial.timestamp = self.dateCreated
        revisions.append(initial)
        self.revisions = revisions
        
        let newest = self.revisions.first
        var cards = [String: Int]()
        for cc in self.allCards {
            cards[cc.card.code] = cc.count
        }
        newest?.cards = cards
        
        // walk through the deck's history and pre-compute a card list for every revision
        for i in 0..<self.revisions.count-1 {
            let prev = self.revisions[i]
            for dc in prev.changes {
                let qty = (cards[dc.code] ?? 0) - dc.count
                if qty == 0 {
                    cards.removeValue(forKey: dc.code)
                } else {
                    cards[dc.code] = qty
                }
            }
            
            let dcs = self.revisions[i+1]
            dcs.cards = cards
        }
    }

    // MARK: - NSCoding
    convenience required init?(coder decoder: NSCoder) {
        self.init()
        
        self.cards = decoder.decodeObject(forKey: "cards") as! [CardCounter]
        
        // kill cards that we couldn't deserialize
        self.cards = self.cards.filter { !$0.isNull && $0.count > 0 }
        
        self.netrunnerDbId = decoder.decodeObject(forKey: "netrunnerDbId") as? String
        
        self.name = (decoder.decodeObject(forKey: "name") as? String) ?? ""
        self.role = Role(rawValue: decoder.decodeInteger(forKey: "role"))!
        self.state = DeckState(rawValue: decoder.decodeInteger(forKey: "state"))!
        self.isDraft = decoder.decodeBool(forKey: "draft")
        if let identityCode = decoder.decodeObject(forKey: "identity") as? String {
            if let identity = CardManager.cardBy(code: identityCode) {
                self.identityCc = CardCounter(card:identity, count:1)
            }
        }
        self.lastModified = nil
        self.notes = decoder.decodeObject(forKey: "notes") as? String
        
        let lastChanges = decoder.decodeObject(forKey: "lastChanges") as? DeckChangeSet
        self.lastChanges = lastChanges ?? DeckChangeSet()

        let revisions = decoder.decodeObject(forKey: "revisions") as? [DeckChangeSet]
        self.revisions = revisions ?? [DeckChangeSet]()

        let mwl = decoder.decodeInteger(forKey: "mwl")
        self.mwl = MWL(rawValue: mwl) ?? .none

        self.onesies = decoder.decodeBool(forKey: "onesies")

        // can't use bool here for backwards compatibility when CacheRefresh was an Int-based enum
        if decoder.containsValue(forKey: "cacheRefresh") {
            let cacheRefresh = decoder.decodeInteger(forKey: "cacheRefresh")
            self.cacheRefresh = cacheRefresh != 0
        } else {
            self.cacheRefresh = false
        }
        
        self.convertedToCore2 = decoder.decodeBool(forKey: "convertedToCore2")
        
        self.modified = false
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.netrunnerDbId, forKey:"netrunnerDbId")
        coder.encode(self.cards, forKey:"cards")
        coder.encode(self.name, forKey:"name")
        coder.encode(self.role.rawValue, forKey:"role")
        coder.encode(self.state.rawValue, forKey:"state")
        coder.encode(self.isDraft, forKey:"draft")
        if let idCode = self.identityCc?.card.code {
            coder.encode(idCode, forKey:"identity")
        }
        coder.encode(self.notes, forKey:"notes")
        coder.encode(self.lastChanges, forKey:"lastChanges")
        coder.encode(self.revisions, forKey:"revisions")
        coder.encode(self.mwl.rawValue, forKey: "mwl")
        coder.encode(self.onesies, forKey: "onesies")
        
        // can't use bool here for backwards compatibility when CacheRefresh was an Int-based enum
        coder.encode(self.cacheRefresh ? 1 : 0, forKey: "cacheRefresh")
        
        coder.encode(self.convertedToCore2, forKey: "convertedToCore2")
    }
}

// MARK: - validity checking

extension Deck {
    
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
        
        if let id = self.identity, self.size < id.minimumDecksize {
            reasons.append("Not enough cards".localized())
        }
        
        let role = self.identity?.role
        if role == .corp {
            let apRequired = ((self.size / 5) + 1) * 2
            let ap = self.agendaPoints
            if ap != apRequired && ap != apRequired+1 {
                reasons.append(String(format: "AP must be %d or %d".localized(), apRequired, apRequired+1))
            }
        }
        
        let noJintekiAllowed = self.identity?.code == Card.customBiotics
        let isApex = self.identity?.code == Card.apex
        var limitError = false, jintekiError = false, agendaError = false, apexError = false
        
        // check max 1 per deck restrictions and other spcial rules
        for cc in self.cards {
            let card = cc.card
            
            let limitExceeded = self.isDraft ? cc.count > 1 && card.maxPerDeck == 1 : cc.count > card.maxPerDeck
            if limitExceeded && !limitError {
                limitError = true
                reasons.append("Card limit exceeded".localized())
            }
            
            if role == .corp {
                if noJintekiAllowed && card.faction == .jinteki && !jintekiError {
                    jintekiError = true
                    reasons.append("Faction not allowed".localized())
                }
                
                if !self.isDraft && card.type == .agenda && card.faction != .neutral && card.faction != self.identity?.faction && !agendaError {
                    agendaError = true
                    reasons.append("Has out-of-faction agendas".localized())
                }
            }
            else if role == .runner {
                if isApex && card.type == .resource && !card.isVirtual && !apexError {
                    apexError = true
                    reasons.append("Has non-virtual resources".localized())
                }
            }
        }

        let banned = self.cards.filter { $0.card.banned(self.mwl) }
        let restricted = self.cards.filter { $0.card.restricted(self.mwl) }

        if banned.count > 0 {
            reasons.append("Uses removed cards".localized())
        }
        if restricted.count > 1 {
            reasons.append("Too many restricted cards".localized())
        }
        
        if Defaults[.rotationActive] {
            let packsUsed = Set(self.cards.map { $0.card.packCode} )
            let rotatedPacks = packsUsed.flatMap { PackManager.packsByCode[$0] }.filter { $0.rotated }
            if rotatedPacks.count > 0 {
                reasons.append("Uses rotated-out cards".localized())
            }
        }
        
        if self.onesies {
            let onesiesReasons = self.checkOnesiesRules()
            if onesiesReasons.count > 0 {
                reasons.append("Invalid for 1.1.1.1".localized())
                reasons.append(contentsOf: onesiesReasons)
            }
        }
        
        if self.cacheRefresh {
            let crReasons = self.checkCacheRefreshRules()
            if crReasons.count > 0 {
                reasons.append("Invalid for Cache Refresh".localized())
                reasons.append(contentsOf: crReasons)
            }
        }
        
        return reasons
    }
    
    // check if this is a valid "Onesies" deck - 1 Core Set, 1 Deluxe, 1 Data Pack, 1 playset of a Card
    // (which may be 3x of a Core card like Desperado, or a 6x of e.g. Spy Camera
    private func checkOnesiesRules() -> [String] {
        
        var coreCardsOverQuantity = 0
        var draftUsed = false
        
        var cardsFromDeluxe = [String: Int]()
        var cardsFromPack = [String: Int]()
        
        for cc in self.cards {
            let card = cc.card
            switch card.packCode {
            case PackManager.draft:
                draftUsed = true
            case PackManager.core, PackManager.core2:
                if cc.count > card.quantity {
                    coreCardsOverQuantity += 1
                }
            case PackManager.creationAndControl, PackManager.honorAndProfit, PackManager.orderAndChaos, PackManager.dataAndDestiny, PackManager.terminalDirective:
                let c = cardsFromDeluxe[card.packCode] ?? 0
                cardsFromDeluxe[card.packCode] = c + 1
            default:
                let c = cardsFromPack[card.packCode] ?? 0
                cardsFromPack[card.packCode] = c + 1
            }
        }
        
        var reasons = [String]()
        if draftUsed {
            reasons.append("Uses draft cards".localized())
        }
        
        let minPackCards = cardsFromPack.values.min()
        let minDeluxeCards = cardsFromDeluxe.values.min()
        
        let packsUsed = cardsFromPack.count
        let deluxesUsed = cardsFromDeluxe.count
        
        // 1 pack, 1 deluxe, 1 extra from core
        if packsUsed <= 1 && deluxesUsed <= 1 && coreCardsOverQuantity <= 1 {
            return reasons
        }
        // 2 packs, 1 deluxe, extra card from 2nd pack
        if packsUsed == 2 && coreCardsOverQuantity == 0 && minPackCards == 1 && deluxesUsed <= 1 {
            return reasons
        }
        // 1 pack, 2 deluxes: extra card from 2md deluxe
        if deluxesUsed == 2 && coreCardsOverQuantity == 0 && minDeluxeCards == 1 && packsUsed <= 1 {
            return reasons
        }
        
        // more than 1 extra card from core, or extra card is from pack or deluxe
        if coreCardsOverQuantity > 1 || (coreCardsOverQuantity == 1 && (packsUsed > 1 || deluxesUsed > 1)) {
            reasons.append("Uses >1 Core".localized())
        }
        
        // more than 1 deluxe used
        if deluxesUsed > 1 {
            reasons.append("Uses >1 Deluxe".localized())
        }
        
        // more than 2 datapacks used - 2 is only allowed if one of them has the extra card
        if (packsUsed > 1 && minPackCards != 1) || packsUsed > 2 {
            reasons.append("Uses >1 Datapack".localized())
        }
        
        return reasons
    }
    
    // check if this is a valid "Cache Refresh" deck - 1 Core Set, 1 Deluxe, TD, last 2 cycles, current MWL
    private func checkCacheRefreshRules() -> [String] {
        if !self.cacheRefresh {
            return []
        }
        
        let validCycles = PackManager.cacheRefreshCycles
        
        var coreCardsOverQuantity = 0
        var draftUsed = false
        
        var cardsFromDeluxe = [String: Int]()
        var cardsFromTD = 0
        var cardsFromAllowedCycles = 0
        var cardsFromForbiddenCycles = 0
        
        for cc in self.cards {
            let card = cc.card
            switch card.packCode {
            case PackManager.draft:
                draftUsed = true
            case PackManager.core, PackManager.core2:
                if cc.count > card.quantity {
                    coreCardsOverQuantity += 1
                }
            case PackManager.creationAndControl, PackManager.honorAndProfit, PackManager.orderAndChaos, PackManager.dataAndDestiny:
                let c = cardsFromDeluxe[card.packCode] ?? 0
                cardsFromDeluxe[card.packCode] = c + 1
            case PackManager.terminalDirective:
                cardsFromTD += 1
            default:
                let cycle = PackManager.cycleForPack(card.packCode) ?? ""
                if validCycles.contains(cycle) {
                    cardsFromAllowedCycles += 1
                } else {
                    cardsFromForbiddenCycles += 1
                }
            }
        }
        
        var reasons = [String]()
        if draftUsed {
            reasons.append("Uses draft cards".localized())
        }
        
        let deluxesUsed = cardsFromDeluxe.count
        
        // only legal packs, 1 deluxe, 1 core, TD
        if cardsFromForbiddenCycles == 0 && deluxesUsed <= 1 && coreCardsOverQuantity == 0 {
            return reasons
        }

        // more than 1 core used
        if coreCardsOverQuantity > 0 {
            reasons.append("Uses >1 Core".localized())
        }
        
        // more than 1 deluxe used
        if deluxesUsed > 1 {
            reasons.append("Uses >1 Deluxe".localized())
        }
        
        // invalid datapacks used
        if cardsFromForbiddenCycles > 0 {
            reasons.append("Uses invalid Datapack".localized())
        }
        
        return reasons
    }
}

// MARK: - rotation support
extension Deck {
    func containsOldCore() -> Bool {
        for cc in self.allCards {
            if cc.card.packCode == PackManager.core {
                return true
            }
        }
        return false
    }
    
    func convertToRevisedCore() {
        let core2Cards =
            CardManager.allFor(role: self.role).filter { $0.packCode == PackManager.core2 } +
            CardManager.identitiesFor(role: self.role).filter { $0.packCode == PackManager.core2 }
        
        for cc in self.allCards {
            if !PackManager.Rotation2017.packs.contains(cc.card.packCode) {
                continue
            }
            
            if let index = core2Cards.index(where: { $0.englishName == cc.card.englishName }) {
                let replacement = core2Cards[index]
                // print("replacing \(cc.card.name )\(cc.card.code) -> \(replacement.name) \(replacement.code)")
                self.addCard(cc.card, copies: 0)
                self.addCard(replacement, copies: cc.count)
            }
            
            self.convertedToCore2 = true
        }
    }
}
