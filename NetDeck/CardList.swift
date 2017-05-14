//
//  CardList.swift
//  NetDeck
//
//  Created by Gereon Steffens on 23.11.15.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import Foundation
import SwiftyUserDefaults

class CardList {
    private var role: Role
    private var initialCards = [Card]()
    
    private var cost = -1
    private var strength = -1
    private var mu = -1
    private var influence = -1
    private var trash = -1
    private var agendaPoints = -1
    
    private var types: Set<String>?
    private var subtype: String?
    private var subtypes: Set<String>?
    private var factions: Set<String>?
    private var sets: Set<String>?
    
    private var text: String?
    private var searchScope = CardSearchScope.all
    private var unique = false
    private var limited = false
    private var mwl = false
    
    private var faction4inf = Faction.none   // faction for influence filter
    
    private var sortType = BrowserSort.byType
    private var packUsage: PackUsage

    init(forRole role: Role, packUsage: PackUsage) {
        self.role = role
        self.packUsage = packUsage
        
        self.resetInitialCards()
        self.clearFilters()
    }
    
    static func browserInitForRole(_ role: Role, packUsage: PackUsage) -> CardList {
        let cl = CardList(forRole: role, packUsage: packUsage)
        
        var roles = [Role]()
        switch (role) {
        case .none: roles = [ .runner, .corp ]
        case .corp: roles = [ .corp ]
        case .runner: roles = [ .runner ]
        }
        
        cl.initialCards = []
        for role in roles {
            cl.initialCards.append(contentsOf: CardManager.allFor(role: role))
            cl.initialCards.append(contentsOf: CardManager.identitiesFor(role: role))
        }
        switch packUsage {
        case .selected: cl.filterDeselectedSets()
        case .all: cl.filterDraft()
        }

        cl.clearFilters()
        
        return cl
    }
    
    func resetInitialCards() {
        self.initialCards = CardManager.allFor(role: self.role)
        switch self.packUsage {
        case .selected: self.filterDeselectedSets()
        case .all: break
        }
    }
    
    func clearFilters() {
        self.cost = -1
        self.mu = -1
        self.strength = -1
        self.trash = -1
        self.influence = -1
        self.agendaPoints = -1
        
        
        self.types = nil
        self.subtypes = nil
        self.factions = nil
        self.sets = nil
        
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
        
        self.applyPredicate(predicate)
    }
    
    func filterDraft() {
        if !Defaults[.useDraft] {
            let predicate = NSPredicate(format: "packCode != %@", PackManager.draftSetCode)
            self.applyPredicate(predicate)
        }
    }
    
    func preFilterForCorp(_ identity: Card) {
        self.resetInitialCards()
        
        if (identity.faction != .neutral) {
            let factions: NSArray = [ Faction.neutral.rawValue, identity.faction.rawValue ]
            let predicate = NSPredicate(format:"type != %d OR (type = %d AND faction in %@)", CardType.agenda.rawValue, CardType.agenda.rawValue, factions)
            
            self.applyPredicate(predicate)
        }
        
        if identity.code == Card.customBiotics {
            let predicate = NSPredicate(format:"faction != %d", Faction.jinteki.rawValue)
            self.applyPredicate(predicate)
        }
        
        let _ = self.applyFilters()
    }
    
    func preFilterForRunner(_ identity: Card) {
        self.resetInitialCards()
        
        if identity.faction == .apex {
            let predicate = NSPredicate(format:"type != %d OR (type = %d AND isVirtual = 1)", CardType.resource.rawValue, CardType.resource.rawValue)
            self.applyPredicate(predicate)
        }
        
        let _ = self.applyFilters()
    }
    
    func filterByType(_ types: FilterValue) {
        self.types = types.isAny ? nil : types.strings!
    }
    
    func filterByFaction(_ factions: FilterValue) {
        self.factions = factions.isAny ? nil : factions.strings!
    }
    
    func filterBySet(_ sets: FilterValue) {
        self.sets = sets.isAny ? nil : sets.strings!
    }
    
    func filterBySubtype(_ subtypes: FilterValue) {
        self.subtypes = subtypes.isAny ? nil : subtypes.strings!
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

    func filterByInfluence(_ influence: Int) {
        self.influence = influence
        self.faction4inf = .none
    }
    
    func filterByInfluence(_ influence: Int, forFaction faction : Faction) {
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
    
    func sortBy(_ sortType: BrowserSort) {
        self.sortType = sortType
    }
    
    func applyPredicate(_ predicate: NSPredicate) {
        self.initialCards = self.initialCards.filter { predicate.evaluate(with: $0) }
    }
    
    func applyFilters() -> [Card] {
        var filteredCards = self.initialCards
        var predicates = [NSPredicate]()
        
        
        if let f = self.factions, f.count > 0 {
            let predicate = NSPredicate(format:"factionStr IN %@", f)
            predicates.append(predicate)
        }
        if let t = self.types, t.count > 0 {
            let predicate = NSPredicate(format:"typeStr IN %@", t)
            predicates.append(predicate)
        }
        if let s = self.sets, s.count > 0 {
            let predicate = NSPredicate(format:"packName IN %@", s)
            predicates.append(predicate)
        }
        if let s = self.subtypes, s.count > 0 {
            var subPredicates = [NSPredicate]()
            for subtype in s {
                subPredicates.append(NSPredicate(format:"%@ IN subtypes", subtype))
            }
            let subtypePredicate = NSCompoundPredicate(orPredicateWithSubpredicates:subPredicates)
            predicates.append(subtypePredicate)
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
        if self.cost != -1 {
            let predicate = NSPredicate(format:"cost == %d || advancementCost == %d", self.cost, self.cost)
            predicates.append(predicate)
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
                if (ch >= "0" && ch <= "9") {
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
            let predicate = NSPredicate(format:"type != %d AND maxPerDeck == 1", CardType.identity.rawValue)
            predicates.append(predicate)
        }
        
        if predicates.count > 0 {
            let allPredicates = NSCompoundPredicate(andPredicateWithSubpredicates:predicates)
            filteredCards = filteredCards.filter { allPredicates.evaluate(with: $0) }
        }
        
        if self.mwl {
            let mwl = Defaults[.defaultMwl]
            if mwl != .none {
                filteredCards = filteredCards.filter { $0.mwlPenalty(mwl) > 0 }
            }
        }
        
        return filteredCards
    }
    
    private func sort(_ cards: inout [Card]) {
        cards.sort { c1, c2 in
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
            case .byCost:
                if c1.cost < c2.cost { return true }
                if c1.cost > c2.cost { return false }
            case .byStrength:
                if c1.strength < c2.strength { return true }
                if c1.strength > c2.strength { return false }
            }
            
            switch (self.sortType) {
            case .byTypeFaction, .bySetFaction:
                if c1.factionStr < c2.factionStr { return true }
                if c1.factionStr > c2.factionStr { return false }
            case .bySetType:
                if c1.type.rawValue < c2.type.rawValue { return true }
                if c1.type.rawValue > c2.type.rawValue { return false }
            default: break
            }
            
            return c1.foldedName < c2.foldedName
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
    
    func dataForTableView() -> TableData<Card> {
        var filteredCards = self.applyFilters()
        self.sort(&filteredCards)
        
        var sections = [String]()
        var cards = [[Card]]()
        var current = [Card]()
        for card in filteredCards {
            if current.isEmpty || self.section(card) == self.section(current[0]) {
                current.append(card)
            } else {
                sections.append(self.section(current[0]))
                cards.append(current)
                current = [card]
            }
        }
        if !current.isEmpty {
            sections.append(self.section(current[0]))
            cards.append(current)
        }
        
        return TableData(sections: sections, values: cards)
    }
    
    private func section(_ card: Card) -> String {
        switch self.sortType {
        case .byType, .byTypeFaction:
            return card.typeStr
        case .byFaction:
            return card.factionStr
        case .bySet, .bySetType, .bySetNumber, .bySetFaction:
            return card.packName
        case .byCost:
            return "Cost".localized() + " \(card.costString)"
        case .byStrength:
            return "Strength".localized() + " \(card.strengthString)"
        }
    }
    
}
