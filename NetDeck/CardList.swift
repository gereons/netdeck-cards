//
//  CardList.swift
//  NetDeck
//
//  Created by Gereon Steffens on 23.11.15.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import Foundation

class CardList: NSObject {
    private var role: NRRole = .None
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
    private var searchScope: NRSearchScope = .All
    private var unique: Bool = false
    private var limited: Bool = false
    private var faction4inf: NRFaction = .None   // faction for influence filter
    
    private var sortType: NRBrowserSort = .ByType
    private var packUsage: NRPackUsage

    init(forRole role: NRRole, packUsage: NRPackUsage) {
        self.role = role
        self.sortType = .ByType
        self.faction4inf = .None
        self.initialCards = [Card]()
        self.packUsage = packUsage
        super.init()
        
        self.resetInitialCards()
        self.clearFilters()
    }
    
    class func browserInitForRole(role: NRRole, packUsage: NRPackUsage) -> CardList {
        let cl = CardList(forRole: role, packUsage: packUsage)
        
        var roles = [NRRole]()
        switch (role) {
        case .None: roles = [ .Runner, .Corp ]
        case .Corp: roles = [ .Corp ]
        case .Runner: roles = [ .Runner ]
        }
        
        cl.initialCards = [Card]()
        for role in roles {
            cl.initialCards.appendContentsOf(CardManager.allForRole(role))
            cl.initialCards.appendContentsOf(CardManager.identitiesForRole(role))
        }
        switch packUsage {
        case .Selected: cl.filterDeselectedSets()
        case .AllAfterRotation: cl.filterRotatedSets()
        case .All: break
        }

        cl.clearFilters()
        
        return cl
    }
    
    func resetInitialCards() {
        self.initialCards = CardManager.allForRole(self.role)
        switch self.packUsage {
        case .Selected: self.filterDeselectedSets()
        case .AllAfterRotation: self.filterRotatedSets()
        case .All: break
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
        self.searchScope = .All
        self.unique = false
        self.limited = false
        self.faction4inf = .None
    }
    
    func filterDeselectedSets() {
        let disabledPackCodes = PackManager.disabledPackCodes()
        let packPredicate = NSPredicate(format: "!(packCode in %@)", disabledPackCodes)
        var predicate = packPredicate
        
        if let cards = PrebuiltManager.availableCards() {
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
    
    func preFilterForCorp(identity: Card) {
        self.resetInitialCards()
        
        if (identity.faction != .Neutral)
        {
            let factions: NSArray = [ NRFaction.Neutral.rawValue, identity.faction.rawValue ]
            let predicate = NSPredicate(format:"type != %d OR (type = %d AND faction in %@)", NRCardType.Agenda.rawValue, NRCardType.Agenda.rawValue, factions)
            
            applyPredicate(predicate)
        }
        
        if identity.code == Card.CUSTOM_BIOTICS {
            let predicate = NSPredicate(format:"faction != %d", NRFaction.Jinteki.rawValue)
            applyPredicate(predicate)
        }
        
        self.applyFilters()
    }
    
    func preFilterForRunner(identity: Card) {
        self.resetInitialCards()
        
        if identity.faction == .Apex {
            let predicate = NSPredicate(format:"type != %d OR (type = %d AND isVirtual = 1)", NRCardType.Resource.rawValue, NRCardType.Resource.rawValue)
            applyPredicate(predicate)
        }
        
        self.applyFilters()
    }
    
    func filterByType(type: String)
    {
        self.type = type
        self.types = nil
    }
    
    func filterByTypes(types: Set<String>) {
        self.type = ""
        self.types = types
    }
    
    func filterByFaction(faction: String) {
        self.faction = faction
        self.factions = nil
    }
    
    func filterByFactions(factions: Set<String>) {
        self.faction = ""
        self.factions = factions
    }
    
    func filterByText(text: String) {
        self.text = text
        self.searchScope = .Text
    }
    
    func filterByTextOrName(text: String) {
        self.text = text
        self.searchScope = .All
    }
    
    func filterByName(name: String) {
        self.text = name
        self.searchScope = .Name
    }
    
    func filterBySet(set: String) {
        self.set = set
        self.sets = nil
    }
    
    func filterBySets(sets: Set<String>) {
        self.set = ""
        self.sets = sets
    }
    
    func filterByInfluence(influence: Int) {
        self.influence = influence
        self.faction4inf = .None
    }
    
    func filterByInfluence(influence: Int, forFaction faction : NRFaction) {
        self.influence = influence
        self.faction4inf = faction
    }
    
    func filterByMU(mu: Int) {
        self.mu = mu
    }
    
    func filterByTrash(trash: Int) {
        self.trash = trash
    }
    
    func filterByCost(cost: Int) {
        self.cost = cost
    }
    
    func filterBySubtype(subtype: String) {
        self.subtype = subtype
        self.subtypes = nil
    }
    
    func filterBySubtypes(subtypes: Set<String>) {
        self.subtype = ""
        self.subtypes = subtypes
    }
    
    func filterByStrength(strength: Int) {
        self.strength = strength
    }
    
    func filterByAgendaPoints(ap: Int) {
        self.agendaPoints = ap
    }
    
    func filterByUniqueness(unique: Bool) {
        self.unique = unique
    }
    
    func filterByLimited(limited: Bool) {
        self.limited = limited
    }
    
    func sortBy(sortType: NRBrowserSort) {
        self.sortType = sortType
    }
    
    func applyPredicate(predicate: NSPredicate) {
        self.initialCards = self.initialCards.filter { predicate.evaluateWithObject($0) }
    }
    
    func applyFilters() -> [Card] {
        var filteredCards = self.initialCards
        var predicates = [NSPredicate]()
        
        if self.faction?.length > 0 && self.faction != Constant.kANY {
            let predicate = NSPredicate(format:"factionStr LIKE[cd] %@", self.faction!)
            predicates.append(predicate)
        }
        if self.factions?.count > 0 {
            let predicate = NSPredicate(format:"factionStr IN %@", self.factions!)
            predicates.append(predicate)
        }
        if self.type?.length > 0 && self.type != Constant.kANY {
            let predicate = NSPredicate(format:"typeStr LIKE[cd] %@", self.type!)
            predicates.append(predicate)
        }
        if self.types?.count > 0 {
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
            if (self.faction4inf == .None) {
                let predicate = NSPredicate(format:"influence == %d", self.influence)
                predicates.append(predicate)
            } else {
                let predicate = NSPredicate(format:"influence == %d && faction != %d", self.influence, self.faction4inf.rawValue)
                predicates.append(predicate)
            }
        }
        if self.set?.length > 0 && self.set != Constant.kANY {
            let predicate = NSPredicate(format:"packName LIKE[cd] %@", self.set!)
            predicates.append(predicate)
        }
        if self.sets?.count > 0 {
            let predicate = NSPredicate(format:"packName IN %@", self.sets!)
            predicates.append(predicate)
        }
        if self.cost != -1 {
            let predicate = NSPredicate(format:"cost == %d || advancementCost == %d", self.cost, self.cost)
            predicates.append(predicate)
        }
        if self.subtype?.length > 0 && self.subtype != Constant.kANY {
            let predicate = NSPredicate(format:"%@ IN subtypes", self.subtype!)
            predicates.append(predicate)
        }
        if self.subtypes?.count > 0 {
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
        if let text = self.text where text.length > 0 {
            var predicate: NSPredicate
            switch (self.searchScope) {
            case .All:
                predicate = NSPredicate(format:"(name CONTAINS[cd] %@) OR (englishName CONTAINS[cd] %@) OR (text CONTAINS[cd] %@) or (alias CONTAINS[cd] %@)",
                                        text, text, text, text)
            case .Name:
                predicate = NSPredicate(format:"(name CONTAINS[cd] %@) OR (englishName CONTAINS[cd] %@) OR (alias CONTAINS[cd] %@)",
                                        text, text, text)
                let ch = text.characters[text.startIndex]
                if (ch >= "0" && ch <= "9")
                {
                    let codePredicate = NSPredicate(format:"code BEGINSWITH %@", text)
                    predicate = NSCompoundPredicate(orPredicateWithSubpredicates:[ predicate, codePredicate ])
                }
            case .Text:
                predicate = NSPredicate(format:"text CONTAINS[cd] %@", text)
            }
            predicates.append(predicate)
        }
        if self.unique {
            let predicate = NSPredicate(format:"unique == 1")
            predicates.append(predicate)
        }
        if self.limited {
            let predicate = NSPredicate(format:"type != %d AND maxPerDeck == 1", NRCardType.Identity.rawValue)
            predicates.append(predicate)
        }
        
        if predicates.count > 0 {
            let allPredicates = NSCompoundPredicate(andPredicateWithSubpredicates:predicates)
            filteredCards = filteredCards.filter { allPredicates.evaluateWithObject($0) }
        }
        
        return filteredCards
    }
    
    func sort(inout cards: [Card]) {
        
        cards.sortInPlace { (c1, c2) -> Bool in
            switch (self.sortType) {
            case .ByType, .ByTypeFaction:
                if c1.type.rawValue < c2.type.rawValue { return true }
                if c1.type.rawValue > c2.type.rawValue { return false }
            case .ByFaction:
                if c1.factionStr < c2.factionStr { return true }
                if c1.factionStr > c2.factionStr { return false }
            case .BySet, .BySetType, .BySetFaction:
                if c1.packNumber < c2.packNumber { return true }
                if c1.packNumber > c2.packNumber { return false }
            case .BySetNumber:
                if c1.code < c2.code { return true }
                if c1.code > c2.code { return false }
            }
            
            switch (self.sortType)
            {
            case .ByTypeFaction, .BySetFaction:
                if c1.factionStr < c2.factionStr { return true }
                if c1.factionStr > c2.factionStr { return false }
            case .BySetType, .ByFaction:
                if c1.type.rawValue < c2.type.rawValue { return true }
                if c1.type.rawValue > c2.type.rawValue { return false }
            default: break
            }
            
            return c1.name.lowercaseString < c2.name.lowercaseString
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
            case .ByType, .ByTypeFaction:
                section = card.typeStr
            case .ByFaction:
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
        
        if (arr?.count > 0) {
            cards.append(arr!)
        }
        
        assert(sections.count == cards.count, "count mismatch")
        
        return TableData(sections:sections, andValues:cards)
    }
}
