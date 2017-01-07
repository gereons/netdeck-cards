//
//  CardList.swift
//  NetDeck
//
//  Created by Gereon Steffens on 23.11.15.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import Foundation

class CardList: NSObject {
    private var role: NRRole = .none
    private var initialCards: [Card]
    
    private var cost: Int = -1
    private var type: String?
    private var types: Set<String>?
    private var subtype: String?
    private var subtypes: Set<String>?
    private var strength: Int = -1
    private var mu: Int = -1
    private var trash: Int = -1
    private var faction: String?
    private var factions: Set<String>?
    private var influence: Int = -1
    private var set: String?
    private var sets: Set<String>?
    private var agendaPoints: Int = -1
    private var text: String?
    private var searchScope: NRSearchScope = .all
    private var unique: Bool = false
    private var limited: Bool = false
    private var mwl: Bool = false
    private var faction4inf: NRFaction = .none   // faction for influence filter
    
    private var sortType: NRBrowserSort = .byType
    private var packUsage: NRPackUsage

    init(forRole role: NRRole, packUsage: NRPackUsage) {
        self.role = role
        self.sortType = .byType
        self.faction4inf = .none
        self.initialCards = [Card]()
        self.packUsage = packUsage
        super.init()
        
        self.resetInitialCards()
        self.clearFilters()
    }
    
    class func browserInitForRole(_ role: NRRole, packUsage: NRPackUsage) -> CardList {
        let cl = CardList(forRole: role, packUsage: packUsage)
        
        var roles = [NRRole]()
        switch (role) {
        case .none: roles = [ .runner, .corp ]
        case .corp: roles = [ .corp ]
        case .runner: roles = [ .runner ]
        }
        
        cl.initialCards = [Card]()
        for role in roles {
            cl.initialCards.append(contentsOf: CardManager.allFor(role: role))
            cl.initialCards.append(contentsOf: CardManager.identitiesFor(role: role))
        }
        switch packUsage {
        case .selected: cl.filterDeselectedSets()
        case .allAfterRotation: cl.filterRotatedSets()
        case .all: cl.filterDraft()
        }

        cl.clearFilters()
        
        return cl
    }
    
    func resetInitialCards() {
        self.initialCards = CardManager.allFor(role: self.role)
        switch self.packUsage {
        case .selected: self.filterDeselectedSets()
        case .allAfterRotation: self.filterRotatedSets()
        case .all: break
        }
    }
    
    func clearFilters() {
        self.cost = -1
        self.type = ""
        self.types = nil
        self.subtype = ""
        self.subtypes = nil
        self.strength = -1
        self.mu = -1
        self.trash = -1
        self.faction = ""
        self.factions = nil
        self.influence = -1
        self.set = ""
        self.sets = nil
        self.agendaPoints = -1
        self.text = ""
        self.searchScope = .all
        self.unique = false
        self.limited = false
        self.mwl = false
        self.faction4inf = .none
    }
    
    func filterDeselectedSets() {
        let disabledPackCodes = PackManager.disabledPackCodes()
        let packPredicate = NSPredicate(format: "!(packCode in %@)", disabledPackCodes)
        var predicate = packPredicate
        
        if let cards = PrebuiltManager.availableCodes() {
            let decksPredicate = NSPredicate(format: "code in %@", cards)
            predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [packPredicate, decksPredicate])
        }
        
        applyPredicate(predicate)
    }
    
    func filterRotatedSets() {
        let rotatedPackCodes = PackManager.rotatedPackCodes()
        let predicate = NSPredicate(format: "!(packCode in %@)", rotatedPackCodes)
        applyPredicate(predicate)
    }
    
    func filterDraft() {
        let draft = PackManager.draftPackCode()
        if draft.count > 0 {
            let predicate = NSPredicate(format: "!(packCode in %@)", draft)
            applyPredicate(predicate)
        }
    }
    
    func preFilterForCorp(_ identity: Card) {
        self.resetInitialCards()
        
        if (identity.faction != .neutral)
        {
            let factions: NSArray = [ NRFaction.neutral.rawValue, identity.faction.rawValue ]
            let predicate = NSPredicate(format:"type != %d OR (type = %d AND faction in %@)", NRCardType.agenda.rawValue, NRCardType.agenda.rawValue, factions)
            
            applyPredicate(predicate)
        }
        
        if identity.code == Card.customBiotics {
            let predicate = NSPredicate(format:"faction != %d", NRFaction.jinteki.rawValue)
            applyPredicate(predicate)
        }
        
        let _ = self.applyFilters()
    }
    
    func preFilterForRunner(_ identity: Card) {
        self.resetInitialCards()
        
        if identity.faction == .apex {
            let predicate = NSPredicate(format:"type != %d OR (type = %d AND isVirtual = 1)", NRCardType.resource.rawValue, NRCardType.resource.rawValue)
            applyPredicate(predicate)
        }
        
        let _ = self.applyFilters()
    }
    
    func filterByType(_ type: String)
    {
        self.type = type
        self.types = nil
    }
    
    func filterByTypes(_ types: Set<String>) {
        self.type = ""
        self.types = types
    }
    
    func filterByFaction(_ faction: String) {
        self.faction = faction
        self.factions = nil
    }
    
    func filterByFactions(_ factions: Set<String>) {
        self.faction = ""
        self.factions = factions
    }
    
    func filterByText(_ text: String) {
        self.text = text
        self.searchScope = .text
    }
    
    func filterByTextOrName(_ text: String) {
        self.text = text
        self.searchScope = .all
    }
    
    func filterByName(_ name: String) {
        self.text = name
        self.searchScope = .name
    }
    
    func filterBySet(_ set: String) {
        self.set = set
        self.sets = nil
    }
    
    func filterBySets(_ sets: Set<String>) {
        self.set = ""
        self.sets = sets
    }
    
    func filterByInfluence(_ influence: Int) {
        self.influence = influence
        self.faction4inf = .none
    }
    
    func filterByInfluence(_ influence: Int, forFaction faction : NRFaction) {
        self.influence = influence
        self.faction4inf = faction
    }
    
    func filterByMU(_ mu: Int) {
        self.mu = mu
    }
    
    func filterByTrash(_ trash: Int) {
        self.trash = trash
    }
    
    func filterByCost(_ cost: Int) {
        self.cost = cost
    }
    
    func filterBySubtype(_ subtype: String) {
        self.subtype = subtype
        self.subtypes = nil
    }
    
    func filterBySubtypes(_ subtypes: Set<String>) {
        self.subtype = ""
        self.subtypes = subtypes
    }
    
    func filterByStrength(_ strength: Int) {
        self.strength = strength
    }
    
    func filterByAgendaPoints(_ ap: Int) {
        self.agendaPoints = ap
    }
    
    func filterByUniqueness(_ unique: Bool) {
        self.unique = unique
    }
    
    func filterByLimited(_ limited: Bool) {
        self.limited = limited
    }
    
    func filterByMWL(_ mwl: Bool) {
        self.mwl = mwl
    }
    
    func sortBy(_ sortType: NRBrowserSort) {
        self.sortType = sortType
    }
    
    func applyPredicate(_ predicate: NSPredicate) {
        self.initialCards = self.initialCards.filter { predicate.evaluate(with: $0) }
    }
    
    func applyFilters() -> [Card] {
        var filteredCards = self.initialCards
        var predicates = [NSPredicate]()
        
        
        if let f = self.faction, f.length > 0 && f != Constant.kANY {
            let predicate = NSPredicate(format:"factionStr LIKE[cd] %@", self.faction!)
            predicates.append(predicate)
        }
        if let f = self.factions, f.count > 0 {
            let predicate = NSPredicate(format:"factionStr IN %@", self.factions!)
            predicates.append(predicate)
        }
        if let t = self.type, t.length > 0 && t != Constant.kANY {
            let predicate = NSPredicate(format:"typeStr LIKE[cd] %@", self.type!)
            predicates.append(predicate)
        }
        if let t = self.types, t.count > 0 {
            let predicate = NSPredicate(format:"typeStr IN %@", self.types!)
            predicates.append(predicate)
        }
        if self.mu != -1 {
            let predicate = NSPredicate(format:"mu == %d", self.mu)
            predicates.append(predicate)
        }
        if self.trash != -1 {
            let predicate = NSPredicate(format:"trash == %d", self.trash)
            predicates.append(predicate)
        }
        if self.strength != -1 {
            let predicate = NSPredicate(format:"strength == %d", self.strength)
            predicates.append(predicate)
        }
        if self.influence != -1 {
            if (self.faction4inf == .none) {
                let predicate = NSPredicate(format:"influence == %d", self.influence)
                predicates.append(predicate)
            } else {
                let predicate = NSPredicate(format:"influence == %d && faction != %d", self.influence, self.faction4inf.rawValue)
                predicates.append(predicate)
            }
        }
        if let s = self.set, s.length > 0 && s != Constant.kANY {
            let predicate = NSPredicate(format:"packName LIKE[cd] %@", self.set!)
            predicates.append(predicate)
        }
        if let s = self.sets, s.count > 0 {
            let predicate = NSPredicate(format:"packName IN %@", self.sets!)
            predicates.append(predicate)
        }
        if self.cost != -1 {
            let predicate = NSPredicate(format:"cost == %d || advancementCost == %d", self.cost, self.cost)
            predicates.append(predicate)
        }
        if let s = self.subtype, s.length > 0 && s != Constant.kANY {
            let predicate = NSPredicate(format:"%@ IN subtypes", self.subtype!)
            predicates.append(predicate)
        }
        if let s = self.subtypes, s.count > 0 {
            var subPredicates = [NSPredicate]()
            for subtype in self.subtypes! {
                subPredicates.append(NSPredicate(format:"%@ IN subtypes", subtype))
            }
            let subtypePredicate = NSCompoundPredicate(orPredicateWithSubpredicates:subPredicates)
            predicates.append(subtypePredicate)
        }
        if self.agendaPoints != -1 {
            let predicate = NSPredicate(format:"agendaPoints == %d", self.agendaPoints)
            predicates.append(predicate)
        }
        if let text = self.text , text.length > 0 {
            var predicate: NSPredicate
            switch (self.searchScope) {
            case .all:
                predicate = NSPredicate(format:"(name CONTAINS[cd] %@) OR (englishName CONTAINS[cd] %@) OR (text CONTAINS[cd] %@) or (alias CONTAINS[cd] %@)",
                                        text, text, text, text)
            case .name:
                predicate = NSPredicate(format:"(name CONTAINS[cd] %@) OR (englishName CONTAINS[cd] %@) OR (alias CONTAINS[cd] %@)",
                                        text, text, text)
                let ch = text.characters[text.startIndex]
                if (ch >= "0" && ch <= "9")
                {
                    let codePredicate = NSPredicate(format:"code BEGINSWITH %@", text)
                    predicate = NSCompoundPredicate(orPredicateWithSubpredicates:[ predicate, codePredicate ])
                }
            case .text:
                predicate = NSPredicate(format:"text CONTAINS[cd] %@", text)
            }
            predicates.append(predicate)
        }
        if self.unique {
            let predicate = NSPredicate(format:"unique == 1")
            predicates.append(predicate)
        }
        if self.limited {
            let predicate = NSPredicate(format:"type != %d AND maxPerDeck == 1", NRCardType.identity.rawValue)
            predicates.append(predicate)
        }
        
        if predicates.count > 0 {
            let allPredicates = NSCompoundPredicate(andPredicateWithSubpredicates:predicates)
            filteredCards = filteredCards.filter { allPredicates.evaluate(with: $0) }
        }
        
        if self.mwl {
            let mwl = NRMWL(rawValue: UserDefaults.standard.integer(forKey: SettingsKeys.MWL_VERSION)) ?? .none
            if mwl != .none {
                filteredCards = filteredCards.filter { $0.isMostWanted(mwl) }
            }
        }
        
        return filteredCards
    }
    
    func sort(_ cards: inout [Card]) {
        
        cards.sort { (c1, c2) -> Bool in
            switch (self.sortType) {
            case .byType, .byTypeFaction:
                if c1.type.rawValue < c2.type.rawValue { return true }
                if c1.type.rawValue > c2.type.rawValue { return false }
            case .byFaction:
                if c1.factionStr < c2.factionStr { return true }
                if c1.factionStr > c2.factionStr { return false }
            case .bySet, .bySetType, .bySetFaction:
                if c1.packNumber < c2.packNumber { return true }
                if c1.packNumber > c2.packNumber { return false }
            case .bySetNumber:
                if c1.code < c2.code { return true }
                if c1.code > c2.code { return false }
            }
            
            switch (self.sortType)
            {
            case .byTypeFaction, .bySetFaction:
                if c1.factionStr < c2.factionStr { return true }
                if c1.factionStr > c2.factionStr { return false }
            case .bySetType, .byFaction:
                if c1.type.rawValue < c2.type.rawValue { return true }
                if c1.type.rawValue > c2.type.rawValue { return false }
            default: break
            }
            
            return c1.name.lowercased() < c2.name.lowercased()
        }
    }
    
    func count() -> Int {
        let arr = self.applyFilters()
        return arr.count
    }
    
    func allCards() -> [Card] {
        var filteredCards = self.applyFilters()
        self.sort(&filteredCards)
        return filteredCards
    }
    
    func typedDataForTableView() -> TypedTableData<Card> {
        return TypedTableData(untyped: dataForTableView())
    }
    
    func dataForTableView() -> TableData {
        var sections = [String]()
        var cards = [[Card]]()
        
        var filteredCards = self.applyFilters()
        self.sort(&filteredCards)
        
        var prevSection = ""
        var arr: [Card]?
        for card in filteredCards {
            var section = ""
            switch (self.sortType) {
            case .byType, .byTypeFaction:
                section = card.typeStr
            case .byFaction:
                section = card.factionStr
            default:
                section = card.packName
            }
            
            if section != prevSection {
                sections.append(section)
                if (arr != nil)
                {
                    cards.append(arr!)
                }
                arr = [Card]()
            }
            arr!.append(card)
            prevSection = section
        }
        
        if let arr = arr, arr.count > 0 {
            cards.append(arr)
        }
        
        assert(sections.count == cards.count, "count mismatch")
        
        return TableData(sections: sections, andValues: cards as NSArray)
    }
}
