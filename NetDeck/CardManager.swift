//
//  CardManager.swift
//  NetDeck
//
//  Created by Gereon Steffens on 21.11.15.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import Foundation
import SwiftyJSON

@objc class CardManager: NSObject {
    
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
    ]
    
    override class func initialize() {
        super.initialize()
        
        allKnownCards.removeAll()
        
        allCardsByRole[.Runner] = [Card]()
        allCardsByRole[.Corp] = [Card]()
        
        allIdentitiesByRole[.Runner] = [Card]()
        allIdentitiesByRole[.Corp] = [Card]()
        
        identitySubtypes[.Runner] = Set<String>()
        identitySubtypes[.Corp] = Set<String>()
        
        allSubtypes[.Runner] = [String: Set<String>]()
        allSubtypes[.Corp] = [String: Set<String>]()
        
        maxMU = -1
        maxInfluence = -1
        maxStrength = -1
        maxAgendaPoints = -1
        maxRunnerCost = -1
        maxCorpCost = -1
        maxTrash = -1
    }

    class func cardByCode(code: String) -> Card? {
        return allKnownCards[code]
    }
    
    class func allCards() -> [Card] {
        let cards = allKnownCards.values
        
        return cards.sort({
            return $0.name.length > $1.name.length
        })
    }
    
    class func allForRole(role: NRRole) -> [Card]
    {
        if role != .None {
            return allCardsByRole[role]!
        }
        else {
            var cards = allCardsByRole[.Runner]!
            cards.appendContentsOf(allCardsByRole[.Corp]!)
            return cards
        }
    }
    
    class func identitiesForRole(role: NRRole) -> [Card]
    {
        assert(role != .None)
        return allIdentitiesByRole[role]!
    }
    
    class func subtypesForRole(role: NRRole, andType type: String, includeIdentities: Bool) -> [String] {
        var subtypes = allSubtypes[role]?[type] ?? Set<String>()
        
        let includeIds = includeIdentities && (type == Constant.kANY || type == identityKey)
        if (includeIds) {
            if let set = identitySubtypes[role] {
                subtypes.unionInPlace(set)
            }
        }
    
        return subtypes.sort({ $0.lowercaseString < $1.lowercaseString })
    }
    
    class func subtypesForRole(role: NRRole, andTypes types: Set<String>, includeIdentities: Bool) -> [String] {
        var subtypes = Set<String>()
        for type in types {
            let arr = subtypesForRole(role, andType: type, includeIdentities: includeIdentities)
            subtypes.unionInPlace(arr)
        }
    
        return subtypes.sort({ $0.lowercaseString < $1.lowercaseString })
    }
    
    class func cardsAvailable() -> Bool {
        return allKnownCards.count > 0
    }
    
    private class func setSubtypes() {
        // fill subtypes per role
        for card in allKnownCards.values {
            if (card.subtypes.count > 0) {
                // NSLog(@"%@", card.subtype)
                if (card.type == .Identity)
                {
                    identityKey = card.typeStr
                    identitySubtypes[card.role]?.unionInPlace(card.subtypes)
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
                    
                    dict![card.typeStr]?.unionInPlace(card.subtypes)
                    dict![Constant.kANY]?.unionInPlace(card.subtypes)
                    allSubtypes[card.role] = dict
                }
            }
        }
    }
    
    private class func addCardAliases() {
        // add automatic aliases like "Self Modifying Code" -> "SMC"
        for card in allKnownCards.values {
            if (card.name.length > 2) {
                let words = card.name.componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: " -"))
                if words.count > 1 {
                    var alias = ""
                    for word in words {
                        if word.length > 0 {
                            var c = word.characters[word.startIndex]
                            if c == "\"" {
                                c = word.characters[word.startIndex.advancedBy(1)]
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
    
    private class func addCard(card: Card) {
        guard card.isValid else {
            print("invalid card: \(card.code) \(card.name)")
            return
        }
        
        allKnownCards[card.code] = card
        
        if (card.type == .Identity) {
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
        
        if card.role == .Runner
        {
            maxRunnerCost = max(card.cost, maxRunnerCost)
        }
        else
        {
            maxCorpCost = max(card.cost, maxCorpCost)
        }
    }
    
    class func setNextDownloadDate() {
        let fmt = NSDateFormatter()
        fmt.dateStyle = .ShortStyle // e.g. 08.10.2008 for locale=de
        fmt.timeStyle = .NoStyle
        let now = NSDate()
        
        let settings = NSUserDefaults.standardUserDefaults()
        settings.setObject(fmt.stringFromDate(now), forKey:SettingsKeys.LAST_DOWNLOAD)
        
        let interval = settings.integerForKey(SettingsKeys.UPDATE_INTERVAL)
        
        var nextDownload: String
        switch (interval) {
        case 30:
            let cal = NSCalendar.currentCalendar()
            let next = cal.dateByAddingUnit(.Month, value:1, toDate:now, options:[])
            nextDownload = fmt.stringFromDate(next!)
        case 0:
            nextDownload = "never".localized()
        default:
            let next = NSDate(timeIntervalSinceNow:NSTimeInterval(interval*24*60*60))
            nextDownload = fmt.stringFromDate(next)
        }
        
        settings.setObject(nextDownload, forKey:SettingsKeys.NEXT_DOWNLOAD)
    }
    
    // MARK: - persistence 
    
    class func setupFromFiles(language: String) -> Bool {
        let filename = CardManager.filename()
        
        if let str = try? NSString(contentsOfFile: filename, encoding: NSUTF8StringEncoding) {
            let cardsJson = JSON.parse(str as String)
            return setupFromJson(cardsJson, language: language)
        }
        // print("app start: missing card file")
        return false
    }
    
    class func setupFromNetrunnerDb(cards: JSON, language: String) -> Bool {
        let ok = setupFromJson(cards, language: language)
        if ok {
            let filename = CardManager.filename()
            if let data = try? cards.rawData() {
                data.writeToFile(filename, atomically:true)
                // print("write cards ok=\(ok)")
            }
            AppDelegate.excludeFromBackup(filename)
        }
        return ok
    }
    
    class func setupFromJson(cards: JSON, language: String) -> Bool {
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
        for var arr in [ allIdentitiesByRole[.Runner]!, allIdentitiesByRole[.Corp]! ] {
            arr.sortInPlace({ (c1, c2) -> Bool in
                if c1.faction.rawValue < c2.faction.rawValue { return true }
                if c1.faction.rawValue > c2.faction.rawValue { return false }
                return c1.name < c2.name
            })
        }
        
        return true
    }
    
    private class func filename() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.ApplicationSupportDirectory, .UserDomainMask, true)
        let supportDirectory = paths[0]
    
        return supportDirectory.stringByAppendingPathComponent(CardManager.cardsFilename)
    }
    
    class func removeFiles() {
        let fileMgr = NSFileManager.defaultManager()
        _ = try? fileMgr.removeItemAtPath(filename())
    
        CardManager.initialize()
    }
}