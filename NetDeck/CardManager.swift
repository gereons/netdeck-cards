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
    
    fileprivate(set) static var allCardsByRole = [NRRole: [Card] ]()    // non-id cards
    fileprivate static var allIdentitiesByRole = [NRRole: [Card] ]()    // ids
    
    fileprivate static var allSubtypes = [NRRole: [String: Set<String> ] ]()
    fileprivate static var identitySubtypes = [ NRRole : Set<String> ]()
    fileprivate static var identityKey: String!
    
    fileprivate static var allKnownCards = [ String: Card ]()
    
    fileprivate(set) static var maxMU: Int = -1
    fileprivate(set) static var maxInfluence: Int = -1
    fileprivate(set) static var maxStrength: Int = -1
    fileprivate(set) static var maxAgendaPoints: Int = -1
    fileprivate(set) static var maxRunnerCost: Int = -1
    fileprivate(set) static var maxCorpCost: Int = -1
    fileprivate(set) static var maxTrash: Int = -1
    
    fileprivate static let cardAliases = [
        "08034": "Franklin",  // crick
        "02085": "HQI",       // hq interface
        "02107": "RDI",       // r&d interface
        "06033": "David",     // d4v1d
        "05039": "SW35",      // unreg. s&w '35
        "03035": "LARLA",     // levy ar lab access
        "04029": "PPVP",      // prepaid voicepad
        "01092": "SSCG",      // sansan city grid
        "03049": "Proco",     // professional contacts
        "02079": "OAI",       // oversight AI
        "08009": "Baby",      // symmetrical visage
        "08003": "Pancakes",  // adjusted chronotype
        "08086": "Anita",     // film critic
        "01044": "Mopus",     // magnum opus
        "09007": "Kitty",     // quantum predictive model
        "10043": "Polop",     // political operative
        "10108": "FIRS",      // Full Immersion RecStudio
        "11024": "Clippy",    // Paperclip
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

    class func cardByCode(_ code: String) -> Card? {
        return allKnownCards[code]
    }
    
    class func allCards() -> [Card] {
        let cards = allKnownCards.values
        
        return cards.sorted(by: {
            return $0.name.length > $1.name.length
        })
    }
    
    class func allForRole(_ role: NRRole) -> [Card]
    {
        if role != .none {
            return allCardsByRole[role]!
        }
        else {
            var cards = allCardsByRole[.runner]!
            cards.append(contentsOf: allCardsByRole[.corp]!)
            return cards
        }
    }
    
    class func identitiesForRole(_ role: NRRole) -> [Card]
    {
        assert(role != .none)
        return allIdentitiesByRole[role]!
    }
    
    class func subtypesForRole(_ role: NRRole, andType type: String, includeIdentities: Bool) -> [String] {
        var subtypes = allSubtypes[role]?[type] ?? Set<String>()
        
        let includeIds = includeIdentities && (type == Constant.kANY || type == identityKey)
        if (includeIds) {
            if let set = identitySubtypes[role] {
                subtypes.formUnion(set)
            }
        }
    
        return subtypes.sorted(by: { $0.lowercased() < $1.lowercased() })
    }
    
    class func subtypesForRole(_ role: NRRole, andTypes types: Set<String>, includeIdentities: Bool) -> [String] {
        var subtypes = Set<String>()
        for type in types {
            let arr = subtypesForRole(role, andType: type, includeIdentities: includeIdentities)
            subtypes.formUnion(arr)
        }
    
        return subtypes.sorted(by: { $0.lowercased() < $1.lowercased() })
    }
    
    class func cardsAvailable() -> Bool {
        return allKnownCards.count > 0
    }
    
    fileprivate class func setSubtypes() {
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
    
    fileprivate class func addCardAliases() {
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
            if let card = CardManager.cardByCode(code) {
                card.setCardAlias(cardAliases[code]!)
            }
        }
    }
    
    fileprivate class func addCard(_ card: Card) {
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
            let cardsJson = JSON.parse(string: str as String)
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
            CardManager.addCard(card)
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
    
    fileprivate class func filename() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)
        let supportDirectory = paths[0]
    
        return supportDirectory.stringByAppendingPathComponent(CardManager.cardsFilename)
    }
    
    class func removeFiles() {
        let fileMgr = FileManager.default
        _ = try? fileMgr.removeItem(atPath: filename())
    
        CardManager.initialize()
    }
}
