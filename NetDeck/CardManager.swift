//
//  CardManager.swift
//  NetDeck
//
//  Created by Gereon Steffens on 21.11.15.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import Foundation
import SwiftyJSON

class CardManager: NSObject {
    
    static let cardsFilename = "nrcards2.json"
    
    private(set) static var allCardsByRole = [NRRole: [Card] ]()    // non-id cards
    private static var allIdentitiesByRole = [NRRole: [Card] ]()    // ids
    
    private static var allSubtypes = [NRRole: [String: Set<String> ] ]()
    private static var identitySubtypes = [ NRRole : Set<String> ]()
    private static var identityKey: String!
    
    private static var allKnownCards = [ String: Card ]()
    
    private(set) static var maxMU: Int = -1
    private(set) static var maxInfluence: Int = -1
    private(set) static var maxStrength: Int = -1
    private(set) static var maxAgendaPoints: Int = -1
    private(set) static var maxRunnerCost: Int = -1
    private(set) static var maxCorpCost: Int = -1
    private(set) static var maxTrash: Int = -1
    
    private static let cardAliases = [
        "08034": "Franklin",  // Crick
        "02085": "HQI",       // HQ Interface
        "02107": "RDI",       // R&D Interface
        "06033": "David",     // D4v1d
        "05039": "SW35",      // Unreg. s&w '35
        "03035": "LARLA",     // Levy AR Lab Access
        "04029": "PPVP",      // Prepaid Voicepad
        "01092": "SSCG",      // Sansan City Grid
        "03049": "Proco",     // Professional Contacts
        "02079": "OAI",       // Oversight AI
        "08009": "Baby",      // Symmetrical Visage
        "08003": "Pancakes",  // Adjusted Chronotype
        "08086": "Anita",     // Film Critic
        "01044": "Mopus",     // Magnum Opus
        "09007": "Kitty",     // Quantum Predictive Model
        "10043": "Polop",     // Political Operative
        "10108": "FIRS",      // Full Immersion RecStudio
        "11024": "Clippy",    // Paperclip
        "11036": "CIF",       // C.I. Funds
    ]
    
    override class func initialize() {
        super.initialize()
        
        allKnownCards.removeAll()
        
        allCardsByRole[.runner] = [Card]()
        allCardsByRole[.corp] = [Card]()
        
        allIdentitiesByRole[.runner] = [Card]()
        allIdentitiesByRole[.corp] = [Card]()
        
        identitySubtypes[.runner] = Set<String>()
        identitySubtypes[.corp] = Set<String>()
        
        allSubtypes[.runner] = [String: Set<String>]()
        allSubtypes[.corp] = [String: Set<String>]()
        
        maxMU = -1
        maxInfluence = -1
        maxStrength = -1
        maxAgendaPoints = -1
        maxRunnerCost = -1
        maxCorpCost = -1
        maxTrash = -1
    }

    class func cardBy(code: String) -> Card? {
        return allKnownCards[code]
    }
    
    class func allCards() -> [Card] {
        let cards = allKnownCards.values
        
        return cards.sorted {
            return $0.name.length > $1.name.length
        }
    }
    
    class func allFor(role: NRRole) -> [Card]
    {
        if role != .none {
            return allCardsByRole[role]!
        } else {
            var cards = allCardsByRole[.runner]!
            cards.append(contentsOf: allCardsByRole[.corp]!)
            return cards
        }
    }
    
    class func identitiesFor(role: NRRole) -> [Card]
    {
        assert(role != .none)
        return allIdentitiesByRole[role]!
    }
    
    class func subtypesFor(role: NRRole, andType type: String, includeIdentities: Bool) -> [String] {
        var subtypes = allSubtypes[role]?[type] ?? Set<String>()
        
        let includeIds = includeIdentities && (type == Constant.kANY || type == identityKey)
        if (includeIds) {
            if let set = identitySubtypes[role] {
                subtypes.formUnion(set)
            }
        }
    
        return subtypes.sorted { $0.lowercased() < $1.lowercased() }
    }
    
    class func subtypesFor(role: NRRole, andTypes types: Set<String>, includeIdentities: Bool) -> [String] {
        var subtypes = Set<String>()
        for type in types {
            let arr = subtypesFor(role: role, andType: type, includeIdentities: includeIdentities)
            subtypes.formUnion(arr)
        }
    
        return subtypes.sorted(by: { $0.lowercased() < $1.lowercased() })
    }
    
    class var cardsAvailable: Bool {
        return allKnownCards.count > 0
    }
    
    private class func setSubtypes() {
        // fill subtypes per role
        for card in allKnownCards.values {
            if (card.subtypes.count > 0) {
                // NSLog(@"%@", card.subtype)
                if (card.type == .identity)
                {
                    identityKey = card.typeStr
                    identitySubtypes[card.role]?.formUnion(card.subtypes)
                }
                else
                {
                    var dict = allSubtypes[card.role]
                    if (dict == nil) {
                        dict = [String: Set<String>]()
                    }
                    
                    if dict![card.typeStr] == nil {
                        dict![card.typeStr] = Set<String>()
                    }
                    if (dict![Constant.kANY] == nil) {
                        dict![Constant.kANY] = Set<String>()
                    }
                    
                    dict![card.typeStr]?.formUnion(card.subtypes)
                    dict![Constant.kANY]?.formUnion(card.subtypes)
                    allSubtypes[card.role] = dict
                }
            }
        }
    }
    
    private class func addCardAliases() {
        // add automatic aliases like "Self Modifying Code" -> "SMC"
        for card in allKnownCards.values {
            if (card.name.length > 2) {
                let words = card.name.components(separatedBy: CharacterSet(charactersIn: " -"))
                if words.count > 1 {
                    var alias = ""
                    for word in words {
                        if word.length > 0 {
                            var c = word.characters[word.startIndex]
                            if c == "\"" {
                                c = word.characters[word.characters.index(word.startIndex, offsetBy: 1)]
                            }
                            alias.append(c)
                        }
                    }
                    // NSLog("%@ -> %@", card.name, alias)
                    card.setCardAlias(alias)
                }
            }
        }
        
        // add hard-coded aliases
        for code in cardAliases.keys {
            if let card = CardManager.cardBy(code: code) {
                card.setCardAlias(cardAliases[code]!)
            }
        }
    }
    
    private class func add(card: Card) {
        guard card.isValid else {
            print("invalid card: \(card.code) \(card.name)")
            return
        }
        
        allKnownCards[card.code] = card
        
        if (card.type == .identity) {
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
        
        if card.role == .runner
        {
            maxRunnerCost = max(card.cost, maxRunnerCost)
        }
        else
        {
            maxCorpCost = max(card.cost, maxCorpCost)
        }
    }
    
    class func setNextDownloadDate() {
        let fmt = DateFormatter()
        fmt.dateStyle = .short // e.g. 08.10.2008 for locale=de
        fmt.timeStyle = .none
        let now = Date()
        
        let settings = UserDefaults.standard
        settings.set(fmt.string(from: now), forKey:SettingsKeys.LAST_DOWNLOAD)
        
        let interval = settings.integer(forKey: SettingsKeys.UPDATE_INTERVAL)
        
        var nextDownload: String
        switch (interval) {
        case 30:
            let cal = Calendar.current
            let next = cal.date(byAdding: .month, value: 1, to: now)
            nextDownload = fmt.string(from: next!)
        case 0:
            nextDownload = "never".localized()
        default:
            let next = Date(timeIntervalSinceNow:TimeInterval(interval*24*60*60))
            nextDownload = fmt.string(from: next)
        }
        
        settings.set(nextDownload, forKey:SettingsKeys.NEXT_DOWNLOAD)
    }
    
    // MARK: - persistence 
    
    class func setupFromFiles(_ language: String) -> Bool {
        let filename = CardManager.filename()
        
        if let str = try? NSString(contentsOfFile: filename, encoding: String.Encoding.utf8.rawValue) {
            let cardsJson = JSON.parse(str as String)
            return setupFromJson(cardsJson, language: language)
        }
        // print("app start: missing card file")
        return false
    }
    
    class func setupFromNetrunnerDb(_ cards: JSON, language: String) -> Bool {
        var ok = setupFromJson(cards, language: language)
        if ok {
            let filename = CardManager.filename()
            if let data = try? cards.rawData() {
                do {
                    try data.write(to: URL(fileURLWithPath: filename), options: .atomic)
                } catch {
                    ok = false
                }
                // print("write cards ok=\(ok)")
            }
            AppDelegate.excludeFromBackup(filename)
        }
        return ok
    }
    
    class func setupFromJson(_ cards: JSON, language: String) -> Bool {
        if !cards.validNrdbResponse {
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
        
        CardManager.setSubtypes()
        CardManager.addCardAliases()
        
        if !Faction.initializeFactionNames(cards) {
            return false
        }
        if !CardType.initializeCardTypes(cards) {
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
    
    private class func filename() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)
        let supportDirectory = paths[0]
    
        return supportDirectory.appendPathComponent(CardManager.cardsFilename)
    }
    
    class func removeFiles() {
        let fileMgr = FileManager.default
        _ = try? fileMgr.removeItem(atPath: filename())
    
        CardManager.initialize()
    }
}
