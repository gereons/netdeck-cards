//
//  Deck.swift
//  NetDeck
//
//  Created by Gereon Steffens on 28.11.15.
//  Copyright © 2018 Gereon Steffens. All rights reserved.
//

import Foundation
import SwiftyUserDefaults

@objc(Deck) class Deck: NSObject, NSCoding {

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
    fileprivate(set) var convertedToSC19 = false
    
    override private init() { }
    
    init(role: Role) {
        self.state = Defaults[.createDeckActive] ? .active : .testing
        let seq = DeckManager.fileSequence() + 1
        self.name = "Deck #\(seq)"
        self.legality = .standard(mwl: Defaults[.defaultMWL])
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

    var legality = DeckLegality.casual {
        willSet { modified = true }
    }
    
    var mwl: MWL {
        return self.legality.mwl
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
        if self.identityCc != nil {
            newDeck.identityCc = CardCounter(card: self.identity!, count: 1)
        }
        newDeck.isDraft = self.isDraft
        newDeck.cards = self.cards.map({ $0.copy() as! CardCounter })
        newDeck.role = self.role
        newDeck.filename = nil
        newDeck.state = self.state
        newDeck.notes = self.notes
        newDeck.legality = self.legality
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
            if let card = CardManager.cardBy(code) {
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
            if cc.count == 0 {
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
    static func arrayFromJson(_ data: Data) -> [Deck] {
        let rawDecks = NetrunnerDbDeck.parse(data)
        var decks = [Deck]()
        
        rawDecks.forEach { rawDeck in
            let deck = Deck()
            deck.state = Defaults[.createDeckActive] ? .active : .testing
            deck.name = rawDeck.name
            deck.notes = rawDeck.description
            deck.netrunnerDbId = "\(rawDeck.id)"
            deck.lastModified = rawDeck.date_update
            deck.dateCreated = rawDeck.date_creation
            
            for (code, qty) in rawDeck.cards {
                if let card = CardManager.cardBy(code) {
                    deck.addCard(card, copies: qty, history: false)
                }
            }
            
            let mwl: MWL
            if let code = rawDeck.mwl_code {
                mwl = MWL.by(code: code)
            } else {
                mwl = Defaults[.defaultMWL]
            }

            deck.legality = DeckLegality.standard(mwl: mwl)
            if mwl >= .v2_0 || (mwl == .none && Defaults[.defaultMWL] >= .v2_0) {
                deck.convertToRevisedCore()
            }
            if mwl >= .v3_0 || (mwl == .none && Defaults[.defaultMWL] >= .v3_0) {
                deck.convertToSC19()
            }
            
            let formatter = DateFormatter()
            formatter.dateFormat = NetrunnerDbDeck.dateFormat
            
            var revisions = [DeckChangeSet]()
            for (date, changes) in rawDeck.history {
                if let timestamp = formatter.date(from: date) {
                    let dcs = DeckChangeSet()
                    dcs.timestamp = timestamp
                    
                    for (code, amount) in changes {
                        if let card = CardManager.cardBy(code) {
                            dcs.addCardCode(card.code, copies: amount)
                        }
                    }
                    
                    dcs.sort()
                    revisions.append(dcs)
                }
            }
            
            revisions.sort {
                $0.timestamp?.timeIntervalSince1970 ?? 0 < $1.timestamp?.timeIntervalSinceNow ?? 0
            }
            
            let initial = DeckChangeSet()
            initial.initial = true
            initial.timestamp = deck.dateCreated
            revisions.append(initial)
            deck.revisions = revisions
            
            let newest = deck.revisions.first
            var cards = [String: Int]()
            for cc in deck.allCards {
                cards[cc.card.code] = cc.count
            }
            newest?.cards = cards
            
            // walk through the deck's history and pre-compute a card list for every revision
            for i in 0 ..< deck.revisions.count-1 {
                let prev = deck.revisions[i]
                for dc in prev.changes {
                    let qty = (cards[dc.code] ?? 0) - dc.count
                    if qty == 0 {
                        cards.removeValue(forKey: dc.code)
                    } else {
                        cards[dc.code] = qty
                    }
                }
                
                let dcs = deck.revisions[i+1]
                dcs.cards = cards
            }
            decks.append(deck)
        }
        
        return decks
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
            if let identity = CardManager.cardBy(identityCode) {
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
        let onesies = decoder.decodeBool(forKey: "onesies")
        let modded = decoder.decodeBool(forKey: "modded")

        // can't use bool here for backwards compatibility when CacheRefresh was an Int-based enum
        var cacheRefresh: Bool
        if decoder.containsValue(forKey: "cacheRefresh") {
            cacheRefresh = decoder.decodeInteger(forKey: "cacheRefresh") != 0
        } else {
            cacheRefresh = false
        }

        var legality: DeckLegality
        if onesies {
            legality = .onesies
        } else if cacheRefresh {
            legality = .cacheRefresh
        } else if modded {
            legality = .modded
        } else {
            legality = .standard(mwl: MWL(rawValue: mwl) ?? .none)
        }
        self.legality = legality
        self.convertedToCore2 = decoder.decodeBool(forKey: "convertedToCore2")
        self.convertedToSC19 = decoder.decodeBool(forKey: "convertedToSC19")
        
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
        coder.encode(self.legality == .onesies, forKey: "onesies")
        coder.encode(self.legality == .modded, forKey: "modded")
        
        // can't use bool here for backwards compatibility when CacheRefresh was an Int-based enum
        coder.encode(self.legality == .cacheRefresh ? 1 : 0, forKey: "cacheRefresh")
        
        coder.encode(self.convertedToCore2, forKey: "convertedToCore2")
        coder.encode(self.convertedToSC19, forKey: "convertedToSC19")
    }

    // -

    func packsUsed() -> [String] {
        var packsUsed = [String: Int]() // pack code -> number of times used
        var cardsUsed = [String: Int]() // pack code -> number of cards used

        for cc in self.allCards {
            let code = cc.card.packCode

            var used = packsUsed[code] ?? 1
            if cc.count > Int(cc.card.quantity) {
                let needed = Int(0.5 + Float(cc.count) / Float(cc.card.quantity))
                if needed > used {
                    used = needed
                }
            }
            packsUsed[code] = used

            var cardUsed = cardsUsed[code] ?? 0
            cardUsed += cc.count
            cardsUsed[code] = cardUsed
        }

        var result = [String]()
        for pack in PackManager.allPacks {
            if let used = cardsUsed[pack.code], let needed = packsUsed[pack.code] {
                let cards = used == 1 ? "Card".localized() : "Cards".localized()
                if needed > 1 {
                    result.append(String(format:"%d×%@ - %d %@", needed, pack.name, used, cards))
                } else {
                    result.append(String(format:"%@ - %d %@", pack.name, used, cards))
                }
            }
        }
        return result
    }

    func mostRecentPackUsed() -> String {
        var maxIndex = -1

        for cc in cards {
            if let index = PackManager.allPacks.index(where: { $0.code == cc.card.packCode}) {
                maxIndex = max(index, maxIndex)
            }
        }

        return maxIndex == -1 ? "n/a" : PackManager.allPacks[maxIndex].name
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
        var limitError = false, jintekiError = false, agendaError = false
        
        // check max 1 per deck restrictions and other special rules
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
        }

        let banned = self.allCards.filter { $0.card.banned(self.mwl) }
        let restricted = self.allCards.filter { $0.card.restricted(self.mwl) }

        if banned.count > 0 {
            reasons.append("Uses removed cards".localized())
        }
        if restricted.count > 1 {
            reasons.append("Too many restricted cards".localized())
        }
        
        if Defaults[.rotationActive] {
            let packsUsed = Set(self.cards.map { $0.card.packCode} )
            let rotatedPacks = packsUsed.compactMap { PackManager.packsByCode[$0] }.filter { $0.rotated }
            if rotatedPacks.count > 0 {
                reasons.append("Uses rotated-out cards".localized())
            }
        }
        
        if self.legality == .onesies {
            let onesiesReasons = self.checkOnesiesRules()
            if onesiesReasons.count > 0 {
                reasons.append("Invalid for 1.1.1.1".localized())
                reasons.append(contentsOf: onesiesReasons)
            }
        }
        
        if self.legality == .cacheRefresh {
            let crReasons = self.checkCacheRefreshRules()
            if crReasons.count > 0 {
                reasons.append("Invalid for Cache Refresh".localized())
                reasons.append(contentsOf: crReasons)
            }
        }

        if self.legality == .modded {
            let modReasons = self.checkModdedRules()
            if modReasons.count > 0 {
                reasons.append("Invalid for Modded".localized())
                reasons.append(contentsOf: modReasons)
            }
        }
        
        return reasons
    }

    // check if this is a valid "Modded" deck - only RCS and current cycle are allowed
    private func checkModdedRules() -> [String] {
        let validCycle = PackManager.cacheRefreshCycles.last

        var deckOk = true
        for cc in self.cards {
            let card = cc.card
            let ok = card.packCode == PackManager.sc19 || PackManager.cycleForPack(card.packCode) == validCycle
            if !ok {
                deckOk = false
            }
        }

        var reasons = [String]()
        if !deckOk {
            reasons.append("Uses cards from previous cycle(s)".localized())
        }
        return reasons
    }
    
    // check if this is a valid "Onesies" deck - 1 Core Set, 1 Big Box, 1 Data Pack, 1 playset of a Card
    // (which may be 3x of a Core card like Desperado, or a 6x of e.g. Spy Camera
    private func checkOnesiesRules() -> [String] {
        var coreCardsOverQuantity = 0
        var draftUsed = false
        
        var cardsFromBigBox = [String: Int]()
        var cardsFromPack = [String: Int]()
        
        for cc in self.cards {
            let card = cc.card
            switch card.packCode {
            case PackManager.draft:
                draftUsed = true
            case PackManager.core, PackManager.core2, PackManager.sc19:
                if cc.count > card.quantity {
                    coreCardsOverQuantity += 1
                }
            case _ where PackManager.bigBoxes.contains(card.packCode):
                let c = cardsFromBigBox[card.packCode] ?? 0
                cardsFromBigBox[card.packCode] = c + 1
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
        let minBigboxCards = cardsFromBigBox.values.min()
        
        let packsUsed = cardsFromPack.count
        let boxesUsed = cardsFromBigBox.count
        
        // 1 pack, 1 big box, 1 extra from core
        if packsUsed <= 1 && boxesUsed <= 1 && coreCardsOverQuantity <= 1 {
            return reasons
        }
        // 2 packs, 1 big box, extra card from 2nd pack
        if packsUsed == 2 && coreCardsOverQuantity == 0 && minPackCards == 1 && boxesUsed <= 1 {
            return reasons
        }
        // 1 pack, 2 big box: extra card from 2md deluxe
        if boxesUsed == 2 && coreCardsOverQuantity == 0 && minBigboxCards == 1 && packsUsed <= 1 {
            return reasons
        }
        
        // more than 1 extra card from core, or extra card is from pack or big box
        if coreCardsOverQuantity > 1 || (coreCardsOverQuantity == 1 && (packsUsed > 1 || boxesUsed > 1)) {
            reasons.append("Uses >1 Core".localized())
        }
        
        // more than 1 big box used
        if boxesUsed > 1 {
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
        let validCycles = PackManager.cacheRefreshCycles

        var coreCardsOverQuantity = 0
        var draftUsed = false
        var oldCoreUsed = false
        
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
                oldCoreUsed = true
            case PackManager.sc19:
                if cc.count > card.quantity {
                    coreCardsOverQuantity += 1
                }
            case _ where PackManager.deluxeBoxes.contains(card.packCode):
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
        if oldCoreUsed {
            reasons.append("Uses old Core set cards".localized())
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

    func containsCore2() -> Bool {
        for cc in self.allCards {
            if cc.card.packCode == PackManager.core2 {
                return true
            }
        }
        return false
    }
    
    func convertToRevisedCore() {
        for cc in self.allCards {
            if let newCode = Card.originalToRevised[cc.card.code], let newCard = CardManager.cardBy(newCode) {
                // print("replacing \(cc.card.name) \(cc.card.code) -> \(newCard.name) \(newCard.code)")
                self.addCard(cc.card, copies: 0)
                self.addCard(newCard, copies: cc.count)
            }

            self.convertedToCore2 = true
        }
    }

    func convertToSC19() {
        self.convertToRevisedCore()
        for cc in self.allCards {
            if let newCode = Card.revisedToSC19[cc.card.code], let newCard = CardManager.cardBy(newCode) {
                // print("replacing \(cc.card.name) \(cc.card.code) -> \(newCard.name) \(newCard.code)")
                self.addCard(cc.card, copies: 0)
                self.addCard(newCard, copies: cc.count)
            }

            self.convertedToSC19 = true
        }
    }
}
