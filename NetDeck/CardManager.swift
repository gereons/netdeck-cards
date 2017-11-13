//
//  CardManager.swift
//  NetDeck
//
//  Created by Gereon Steffens on 21.11.15.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import Foundation
import Marshal
import SwiftyUserDefaults

class CardManager {
    
    static let cardsFilename = "nrcards2.json"
    
    private static var allCardsByRole = [Role: [Card] ]()    // non-id cards
    private static var allIdentitiesByRole = [Role: [Card] ]()    // ids
    private(set) static var quantities = [String: Int]()   // map of code+packCode -> quantity
    
    private static var allSubtypes = [Role: [String: Set<String> ] ]()
    private static var identitySubtypes = [ Role: Set<String> ]()
    private static var identityKey = ""
    
    private static var allKnownCards = [ String: Card ](minimumCapacity: 1600)
    
    private(set) static var maxMU: Int = -1
    private(set) static var maxInfluence: Int = -1
    private(set) static var maxStrength: Int = -1
    private(set) static var maxAgendaPoints: Int = -1
    private(set) static var maxRunnerCost: Int = -1
    private(set) static var maxCorpCost: Int = -1
    private(set) static var maxTrash: Int = -1
    
    static func initialize() {
        allKnownCards.removeAll()
        
        allCardsByRole[.runner] = { var c = [Card](); c.reserveCapacity(800); return c }()
        allCardsByRole[.corp] = { var c = [Card](); c.reserveCapacity(800); return c }()
        
        allIdentitiesByRole[.runner] = { var c = [Card](); c.reserveCapacity(50); return c }()
        allIdentitiesByRole[.corp] = { var c = [Card](); c.reserveCapacity(50); return c }()
        
        identitySubtypes[.runner] = Set<String>()
        identitySubtypes[.corp] = Set<String>()
        
        allSubtypes[.runner] = [:]
        allSubtypes[.corp] = [:]
        
        quantities = [:]
        
        maxMU = -1
        maxInfluence = -1
        maxStrength = -1
        maxAgendaPoints = -1
        maxRunnerCost = -1
        maxCorpCost = -1
        maxTrash = -1
    }
    
    static func maxCost(for role: Role) -> Int {
        switch role {
        case .none: return max(maxCorpCost, maxRunnerCost)
        case .runner: return maxRunnerCost
        case .corp: return maxCorpCost
        }
    }

    static func cardBy(code: String) -> Card? {
        return allKnownCards[code]
    }
    
    static func allCards() -> [Card] {
        let cards = allKnownCards.values
        
        return cards.sorted {
            return $0.name.count > $1.name.count
        }
    }
    
    static func allFor(role: Role) -> [Card] {
        if role != .none {
            return allCardsByRole[role]!
        } else {
            return allCardsByRole[.runner]! + allCardsByRole[.corp]!
        }
    }
    
    static func identitiesFor(role: Role) -> [Card] {
        assert(role != .none)
        return allIdentitiesByRole[role]!
    }
    
    static func identitiesForSelection(_ role: Role, packUsage: PackUsage) -> TableData<Card> {
        var factionNames = Faction.factionsFor(role: role, packUsage: packUsage)
        factionNames.removeFirst(2) // remove "any" and "neutral"
        
        let disabledPackCodes: Set<String>
        switch packUsage {
        case .all:
            var draft = Set<String>()
            if Defaults[.useDraft] {
                draft.insert(PackManager.draft)
            }
            disabledPackCodes = PackManager.rotatedPackCodes().union(draft)
        case .selected:
            disabledPackCodes = PackManager.disabledPackCodes().union(PackManager.rotatedPackCodes())
        }
        
        if !disabledPackCodes.contains(PackManager.draft) {
            factionNames.append(Faction.name(for: .neutral))
        }
        
        var identities = [[Card]]()
        factionNames.forEach { str in
            identities.append([])
        }
        
        let allIdentities = identitiesFor(role: role).sorted { c1, c2 in
            c1.packNumber == c2.packNumber ? c1.number < c2.number : c1.packNumber < c2.packNumber
        }
        
        for identity in allIdentities {
            let faction = Faction.name(for: identity.faction)
            if let index = factionNames.index(where: { $0 == faction }), !identity.inDisabledPack {
                identities[index].append(identity)
            }
        }
        
        if !disabledPackCodes.contains(PackManager.draft) {
            factionNames.removeLast()
            factionNames.append("Draft".localized())
        }
        
        for i in (0 ..< factionNames.count).reversed() {
            if identities[i].count == 0 {
                identities.remove(at: i)
                factionNames.remove(at: i)
            }
        }

        assert(factionNames.count == identities.count)
        
        return TableData(sections: factionNames, values: identities)
    }
    
    static func subtypesFor(role: Role, andType type: String, includeIdentities: Bool) -> [String] {
        var subtypes = allSubtypes[role]?[type] ?? Set<String>()
        
        let includeIds = includeIdentities && (type == Constant.kANY || type == identityKey)
        if includeIds {
            if let set = identitySubtypes[role] {
                subtypes.formUnion(set)
            }
        }
    
        return subtypes.sorted { $0.lowercased() < $1.lowercased() }
    }
    
    static func subtypesFor(role: Role, andTypes types: Set<String>, includeIdentities: Bool) -> [String] {
        var subtypes = Set<String>()
        for type in types {
            let arr = subtypesFor(role: role, andType: type, includeIdentities: includeIdentities)
            subtypes.formUnion(arr)
        }
        if types.count == 0 {
            subtypes = (allSubtypes[role]?[Constant.kANY])!
        }
    
        return subtypes.sorted(by: { $0.lowercased() < $1.lowercased() })
    }
    
    static var cardsAvailable: Bool {
        return allKnownCards.count > 0 && PackManager.packsAvailable
    }
    
    private static func setSubtypes(_ cards: [Card]) {
        // fill subtypes per role
        for card in cards {
            if card.subtypes.count > 0 {
                // NSLog(@"%@", card.subtype)
                if card.type == .identity {
                    identityKey = card.typeStr
                    identitySubtypes[card.role]?.formUnion(card.subtypes)
                } else {
                    var dict = allSubtypes[card.role] ?? [String: Set<String>]()
                    
                    if dict[card.typeStr] == nil {
                        dict[card.typeStr] = Set<String>()
                    }
                    if dict[Constant.kANY] == nil {
                        dict[Constant.kANY] = Set<String>()
                    }
                    
                    dict[card.typeStr]?.formUnion(card.subtypes)
                    dict[Constant.kANY]?.formUnion(card.subtypes)
                    allSubtypes[card.role] = dict
                }
            }
        }
    }
    
    private static func addCardAliases(_ cards: [Card]) {
        // add automatic aliases like "Self Modifying Code" -> "SMC"
        let split = CharacterSet(charactersIn: " -.")
        for card in cards {
            if card.name.count > 2 {
                let words = card.name.components(separatedBy: split)
                if words.count > 1 {
                    var alias = ""
                    for word in words {
                        if word.count > 0 {
                            var c = word[word.startIndex]
                            if c == "\"" {
                                c = word[word.index(word.startIndex, offsetBy: 1)]
                            }
                            alias.append(c)
                        }
                    }
                    // NSLog("%@ -> %@", card.name, alias)
                    card.addCardAlias(alias)
                }
            }
        }
        
        // add hard-coded aliases
        for (code, alias) in Card.aliases {
            if let card = CardManager.cardBy(code: code) {
                card.addCardAlias(alias)
            }
        }
    }
    
    private static func add(card: Card) {
        guard card.isValid else {
            print("invalid card: \(card.code) \(card.name)")
            return
        }
        
        allKnownCards[card.code] = card
        if card.type == .identity {
            allIdentitiesByRole[card.role]!.append(card)
        } else {
            allCardsByRole[card.role]!.append(card)
        }
        
        // calculate max values for filter sliders
        maxMU = max(card.mu, maxMU)
        maxTrash = max(card.trash, maxTrash)
        maxStrength = max(card.strength, maxStrength)
        maxInfluence = max(card.influence, maxInfluence)
        maxAgendaPoints = max(card.agendaPoints, maxAgendaPoints)
        
        if card.role == .runner {
            maxRunnerCost = max(card.cost, maxRunnerCost)
        } else {
            maxCorpCost = max(card.cost, maxCorpCost)
        }
    }
    
    static func setNextDownloadDate() {
        let fmt = DateFormatter()
        fmt.dateStyle = .short // e.g. 08.10.2008 for locale=de
        fmt.timeStyle = .none
        let now = Date()
        
        let interval = Defaults[.updateInterval]
        let nextDownload: String
        switch interval {
        case 30:
            let cal = Calendar.current
            let next = cal.date(byAdding: .month, value: 1, to: now)
            nextDownload = fmt.string(from: next!)
        case 0:
            nextDownload = "never".localized()
        default:
            let next = Date(timeIntervalSinceNow:TimeInterval(interval * 24*60*60))
            nextDownload = fmt.string(from: next)
        }

        Defaults[.lastDownload] = fmt.string(from: now)
        Defaults[.nextDownload] = nextDownload
        
        // print("next download \(nextDownload)")
    }
    
    // MARK: - persistence 
    
    static func setupFromFiles(_ language: String) -> Bool {
        let filename = CardManager.filename()
        
        if let data = FileManager.default.contents(atPath: filename) {
            do {
                let cardsJson = try JSONParser.JSONObjectWithData(data) 
                return setupFromJson(cardsJson, language: language)
            } catch let error {
                print("\(error)")
                return false
            }
        }
        // print("app start: missing card file")
        return false
    }
    
    static func setupFromNetrunnerDb(_ cardsData: Data, language: String) -> Bool {
        var ok = false
        do {
            let cardsJson = try JSONParser.JSONObjectWithData(cardsData)
            ok = setupFromJson(cardsJson, language: language)
            if !ok {
                return false
            }
            
            let filename = self.filename()
            try cardsData.write(to: URL(fileURLWithPath: filename), options: .atomic)
            Utils.excludeFromBackup(filename)
        } catch let error {
            print("\(error)")
        }
        
        return ok
    }
    
    static func setupFromJson(_ cards: JSONObject, language: String) -> Bool {
        if !Utils.validJsonResponse(json: cards) {
            return false
        }
        
        CardManager.initialize()
        
        // parse data
        let parsedCards = Card.cardsFromJson(cards, language: language)
        for card in parsedCards {
            CardManager.add(card: card)
        }

        let cards = Array(allKnownCards.values)
        if cards.count == 0 {
            return false
        }

        CardManager.setSubtypes(cards)
        CardManager.addCardAliases(cards)

        let factionsDict = cards.reduce(into: [Faction: String]()) { $0[$1.faction] = $1.factionStr }
        var ok = Faction.initializeFactionNames(factionsDict)
        if !ok {
            return false
        }

        let typesDict = cards.reduce(into: [CardType: String]()) { $0[$1.type] = $1.typeStr }
        ok = CardType.initializeCardType(typesDict)
        if !ok {
            return false
        }
        
        // sort identities by faction and name
        for var arr in [ allIdentitiesByRole[.runner]!, allIdentitiesByRole[.corp]! ] {
            arr.sort(by: { (c1, c2) -> Bool in
                if c1.faction.rawValue < c2.faction.rawValue { return true }
                if c1.faction.rawValue > c2.faction.rawValue { return false }
                return c1.name < c2.name
            })
        }
        
        return true
    }
    
    static func fileExists() -> Bool {
        return FileManager.default.fileExists(atPath: filename())
    }
    
    private static func filename() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)
        let supportDirectory = paths[0]
    
        return supportDirectory.appendPathComponent(CardManager.cardsFilename)
    }
    
    static func removeFiles() {
        let fileMgr = FileManager.default
        _ = try? fileMgr.removeItem(atPath: filename())
    
        CardManager.initialize()
    }
}
