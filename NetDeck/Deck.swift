//
//  Deck.swift
//  NetDeck
//
//  Created by Gereon Steffens on 28.11.15.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import Foundation
import Marshal

@objc(Deck) class Deck: NSObject, NSCoding, Unmarshaling {

    var filename: String?
    var revisions = [DeckChangeSet]()
    var lastModified: Date?
    var dateCreated: Date?

    private(set) var cards = [CardCounter]()
    private(set) var identityCc: CardCounter?
    private(set) var modified = false
    private(set) var isDraft = false
    
    private var lastChanges = DeckChangeSet()
    
    override private init() {}
    
    init(role: NRRole) {
        let settings = UserDefaults.standard
        self.state = settings.bool(forKey: SettingsKeys.CREATE_DECK_ACTIVE) ? .active : .testing
        let mwlVersion = settings.integer(forKey: SettingsKeys.MWL_VERSION)
        let seq = DeckManager.fileSequence() + 1
        self.name = "Deck #\(seq)"
        self.mwl = NRMWL(rawValue: mwlVersion) ?? .none
        self.role = role
    }
    
    var allCards: [CardCounter] {
        var all = self.cards
        if let id = self.identityCc {
            all.insert(id, at: 0)
        }
        return all
    }
    
    var identity: Card? {
        return identityCc?.card
    }
    
    var name: String = "" {
        willSet { modified = true }
    }
    
    var state = NRDeckState.none {
        willSet { modified = true }
    }
    
    var netrunnerDbId: String? {
        willSet { modified = true }
    }
    
    var notes: String? {
        willSet { modified = true }
    }
    
    private(set) var role = NRRole.none {
        willSet { modified = true }
    }
    
    var mwl = NRMWL.none {
        willSet { modified = true }
    }
    
    var onesies: Bool = false {
        willSet { modified = true }
    }
    
    var size: Int {
        return cards.reduce(0) { $0 + $1.count }
    }
    
    var agendaPoints: Int {
        return cards.filter({ $0.card.type == .agenda}).reduce(0) { $0 + $1.card.agendaPoints * $1.count }
    }
    
    var influence: Int {
        return cards.filter( { $0.card.faction != self.identity?.faction && $0.card.influence != -1 }).reduce(0) { $0 + self.influenceFor($1) }
    }
    
    var influenceLimit: Int {
        if let identity = self.identity {
            if self.mwl != .none {
                return max(1, identity.influenceLimit - self.mwlPenalty)
            } else {
                return identity.influenceLimit
            }
        } else {
            return 0
        }
    }
    
    /// how many cards in this deck are on the MWL?
    var cardsFromMWL: Int {
        return cards.filter({ $0.card.isMostWanted(self.mwl) }).reduce(0) { $0 + $1.count }
    }
    
    /// what's the influence penalty incurred through MWL cards?
    /// (separate from `cardsFromMWL` in case we ever get rules other than "1 inf per card")
    var mwlPenalty: Int {
        return self.cardsFromMWL
    }
    
    func influenceFor(_ cardcounter: CardCounter?) -> Int {
        guard let cc = cardcounter else { return 0 }

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
    
    func nonAllianceOfFaction(_ faction: NRFaction) -> Int {
        var count = 0
        for cc in cards {
            if cc.card.faction == faction && !cc.card.isAlliance {
                count += cc.count
            }
        }
        return count
    }
    
    func padCampaignCount() -> Int {
        if let padIndex = self.indexOfCardCode(Card.padCampaign) {
            let pad = cards[padIndex]
            return pad.count
        }
        return 0
    }
    
    func iceCount() -> Int {
        return self.typeCount(.ice)
    }
    
    func assetCount() -> Int {
        return self.typeCount(.asset)
    }
    
    func typeCount(_ type: NRCardType) -> Int {
        return cards.filter({ $0.card.type == type}).reduce(0) { $0 + $1.count }
    }
    
    func addCard(_ card: Card, copies: Int) {
        self.addCard(card, copies: copies, history: true)
    }
    
    // add (copies>0) or remove (copies<0) a copy of a card from the deck
    // if copies==0, removes ALL copies of the card
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
                let max = cc.card.maxPerDeck
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
    
    func setIdentity(_ identity: Card?, copies: Int, history: Bool) {
        if self.identityCc != nil && history {
            // record removal of existing identity
            self.lastChanges.addCardCode(self.identityCc!.card.code, copies: -1)
        }
        if let id = identity , copies > 0 {
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
        self.isDraft = identity?.packCode == PackManager.draftSetCode
    }
    
    func indexOfCardCode(_ code: String) -> Int? {
        return cards.index { $0.card.code == code }
    }
    
    func findCard(_ card: Card?) -> CardCounter? {
        if let c = card, let index = self.indexOfCardCode(c.code) {
            return cards[index]
        }
        return nil
    }
    
    private func sort(by sortOrder: NRDeckSort) {
        cards.sort { (cc1, cc2) -> Bool in
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
            return c1.name.lowercased() < c2.name.lowercased()
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
            
            if cc.count > card.maxPerDeck && !limitError {
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
        
        if self.onesies {
            let onesiesReasons = self.checkOnesiesRules()
            if onesiesReasons.count > 0 {
                reasons.append("Invalid for 1.1.1.1".localized())
                reasons.append(contentsOf: onesiesReasons)
            }
        }
        
        return reasons
    }
    
    // check if this is a valid "Onesies" deck - 1 Core Set, 1 Deluxe, 1 Data Pack, 1 playset of a Card
    // (which may be 3x of a Core card like Desperado, or a 6x of e.g. Spy Camera
    func checkOnesiesRules() -> [String] {
        
        var coreCardsOverQuantity = 0
        var draftUsed = false
        
        var cardsFromDeluxe = [String: Int]()
        var cardsFromPack = [String: Int]()
        
        for cc in self.cards {
            let card = cc.card
            switch card.packCode {
            case PackManager.draftSetCode:
                draftUsed = true
            case PackManager.coreSetCode:
                if cc.count > card.quantity {
                    coreCardsOverQuantity += 1
                }
            case "cac", "hap", "oac", "dad":
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
    
    func duplicate() -> Deck {
        let newDeck = Deck()
        
        let oldName = self.name
        var newName = oldName + " " + "(Copy)".localized()
        
        let regexPattern = "\\d+$"
        let regex = try! NSRegularExpression(pattern:regexPattern, options:[])
        
        let matches = regex.matches(in: oldName, options: [], range: NSMakeRange(0, oldName.length))
        if matches.count > 0 {
            let match = matches[0]
            let range = match.range.stringRangeForText(oldName)
            let numberStr = oldName.substring(with: range)
            let number = 1 + Int(numberStr)!
            
            newName = oldName.substring(to: oldName.characters.index(oldName.startIndex, offsetBy: match.range.location))
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
        newDeck.lastChanges = self.lastChanges.copy() as! DeckChangeSet
        newDeck.revisions = self.revisions.map({ $0.copy() as! DeckChangeSet })
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
            
            if let lastSavedCards = dcs.cards {
                let lastSavedCodes = lastSavedCards.keys
                for code in lastSavedCodes {
                    let oldQty = lastSavedCards[code]!
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
                    if !lastSavedCodes.contains(code) {
                        let newQty = cards[code]
                        self.lastChanges.addCardCode(code, copies: newQty!)
                    }
                }
            }
        }

        self.setIdentity(newIdentity, copies: 1, history: false)
        self.cards = newCards
        self.modified = true
    }
    
    func dataForTableView(_ sortOrder: NRDeckSort) -> TableData {
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
        
        var prevSection = ""
        var arr: [CardCounter]?
        
        for cc in self.cards {
            var section: String
            
            switch sortOrder {
            case .byType:
                section = cc.card.typeStr
                if cc.card.type == .ice {
                    section = cc.card.iceType
                }
                if cc.card.type == .program {
                    section = cc.card.programType
                }
            case .bySetType, .bySetNum:
                section = cc.card.packName
            case .byFactionType:
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
        
        if let arr = arr, arr.count > 0 {
            cards.append(arr)
        }
        
        assert(sections.count == cards.count, "count mismatch")
        
        return TableData(sections: sections as NSArray, andValues: cards as NSArray)
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
        
        self.name = try object.value(for: "name")
        self.notes = try object.value(for: "description")
        let id: Int = try object.value(for: "id")
        self.netrunnerDbId = "\(id)"
        
        // parse last update '2014-06-19T13:52:24+00:00'
        self.lastModified = Deck.dateFormatter.date(from: try object.value(for: "date_update"))
        self.dateCreated = Deck.dateFormatter.date(from: try object.value(for: "date_creation"))
        
        let mwlCode: String = try object.value(for: "mwl_code") ?? ""
        self.mwl = NRMWL.by(code: mwlCode)
        
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
    
    // MARK: NSCoding
    convenience required init?(coder decoder: NSCoder) {
        self.init()
        
        self.cards = decoder.decodeObject(forKey: "cards") as! [CardCounter]
        
        // kill cards that we couldn't deserialize
        self.cards = self.cards.filter{ !$0.isNull && $0.count > 0 }
        
        self.netrunnerDbId = decoder.decodeObject(forKey: "netrunnerDbId") as? String
        
        self.name = (decoder.decodeObject(forKey: "name") as? String) ?? ""
        self.role = NRRole(rawValue: decoder.decodeInteger(forKey: "role"))!
        self.state = NRDeckState(rawValue: decoder.decodeInteger(forKey: "state"))!
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
        
        let mwl = decoder.containsValue(forKey: "mwl") ?
            decoder.decodeInteger(forKey: "mwl") :
            UserDefaults.standard.integer(forKey: SettingsKeys.MWL_VERSION)
        
        self.mwl = NRMWL(rawValue: mwl) ?? .none
        
        self.onesies = decoder.decodeBool(forKey: "onesies")
        
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
    }
}
