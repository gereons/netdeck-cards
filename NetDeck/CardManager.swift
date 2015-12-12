//
//  CardManager.swift
//  NetDeck
//
//  Created by Gereon Steffens on 21.11.15.
//  Copyright © 2015 Gereon Steffens. All rights reserved.
//

import Foundation

@objc class CardManager: NSObject {
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
        "03049": "ProCo",     // professional contacts
        "02079": "OAI",       // oversight AI
        "08009": "Baby",      // symmetrical visage
        "08003": "Pancakes",  // adjusted chronotype
        "08086": "Anita",     // film critic
    ]
    
    override class func initialize() {
        super.initialize()
        // TODO: clear data
        
        allKnownCards.removeAll()
        
        allCardsByRole[.Runner] = [Card]()
        allCardsByRole[.Corp] = [Card]()
        
        allIdentitiesByRole[.Runner] = [Card]()
        allIdentitiesByRole[.Corp] = [Card]()
        
        identitySubtypes[.Runner] = Set<String>()
        identitySubtypes[.Corp] = Set<String>()
        
        allSubtypes[.Runner] = [String: Set<String>]()
        allSubtypes[.Corp] = [String: Set<String>]()
    }

    class func cardByCode(code: String) -> Card? {
        return allKnownCards[code]!
    }
    
    class func allCards() -> [Card] {
        let cards = allKnownCards.values
        
        return cards.sort({
            return $0.name.length < $1.name.length
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
    
    class func subtypesForRole(role: NRRole, andType type: String, includeIdentities: Bool) -> [String]? {
        var subtypes = allSubtypes[role]?[type]
        
        let includeIds = includeIdentities && (type == kANY || type == identityKey)
        if (includeIds) {
            if (subtypes == nil) {
                subtypes = Set<String>()
            }
            if let set = identitySubtypes[role] {
                subtypes?.unionInPlace(set)
            }
        }
    
        return subtypes?.sort({ $0.lowercaseString < $1.lowercaseString })
    }
    
    class func subtypesForRole(role: NRRole, andTypes types: Set<String>, includeIdentities: Bool) -> [String]? {
        var subtypes = Set<String>()
        for type in types {
            if let arr = subtypesForRole(role, andType: type, includeIdentities: includeIdentities) {
                subtypes.unionInPlace(arr)
            }
        }
    
        return subtypes.sort({ $0.lowercaseString > $1.lowercaseString })
    }
    
    class func cardsAvailable() -> Bool {
        return allKnownCards.count > 0
    }
    
    class func setupFromFiles() -> Bool {
        let cardsFile = CardManager.filename()
        let cardsEnFile = CardManager.filenameEn()
        var ok = false
        
        let fileMgr = NSFileManager.defaultManager()
        if fileMgr.fileExistsAtPath(cardsFile) {
            if let data = NSArray(contentsOfFile: cardsFile) {
                ok = CardManager.setupFromJsonData(data)
            }
        }
        
        if ok && fileMgr.fileExistsAtPath(cardsEnFile)
        {
            if let data = NSArray(contentsOfFile:cardsEnFile) {
                CardManager.addAdditionalNames(data, saveFile:false)
            }
        }
        
        return ok
    }
    
    class func setupFromNrdbApi(json: NSArray) -> Bool {
        CardManager.setNextDownloadDate()
        
        let cardsFile = CardManager.filename()
        json.writeToFile(cardsFile, atomically:true)
        AppDelegate.excludeFromBackup(cardsFile)
        
        CardManager.initialize()
        return setupFromJsonData(json)
    }
    
    class func setupFromJsonData(json: NSArray) -> Bool {

        for obj in json {
            let card = Card.cardFromJson(obj as! NSDictionary)
            assert(card.isValid, "invalid card from \(obj)");
                
            CardManager.addCard(card)
        }
        
        let cards = Array(allKnownCards.values)
        Faction.initializeFactionNames(cards)
        CardType.initializeCardTypes(cards)
        
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
    
    class func addCard(card: Card) {
        // add to dictionaries/arrays
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
            maxRunnerCost = max(card.cost, maxRunnerCost);
        }
        else
        {
            maxCorpCost = max(card.cost, maxCorpCost);
        }
        
        // fill subtypes per role
        if (card.subtypes.count > 0) {
            // NSLog(@"%@", card.subtype);
            if (card.type == .Identity)
            {
                identityKey = card.typeStr;
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
                if (dict![kANY] == nil) {
                    dict![kANY] = Set<String>()
                }

                dict![card.typeStr]?.unionInPlace(card.subtypes)
                dict![kANY]?.unionInPlace(card.subtypes)
                allSubtypes[card.role] = dict
            }
        }
    }
    
    class func addAdditionalNames(json: NSArray, saveFile: Bool) {
        // add english names from json
        if (saveFile) {
            let cardsFile = CardManager.filenameEn()
            json.writeToFile(cardsFile, atomically: true)
            
            AppDelegate.excludeFromBackup(cardsFile)
        }
        
        for obj in json {
            let code = obj["code"] as! String
            let name_en = obj["title"] as! String
            let subtype = obj["subtype"] as? String
            
            if let card = CardManager.cardByCode(code) {
                card.setNameEn(name_en)
                card.setAlliance(subtype ?? "")
                card.setVirtual(subtype ?? "")
            }
        }
        
        // add automatic aliases like "Self Modifying Code" -> "SMC"
        for card in allKnownCards.values {
            if (card.name.length > 2) {
                var alias = ""
                let words = card.name.componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: " -"))
                if words.count > 2 {
                    for word in words {
                        var c = word.characters[word.startIndex]
                        if c == "\"" {
                            c = word.characters[word.startIndex.advancedBy(1)]
                        }
                        alias.append(c)
                    }
                    // NSLog("%@ -> %@", card.name, alias);
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
    
    class func setNextDownloadDate() {
        let fmt = NSDateFormatter()
        fmt.dateStyle = .ShortStyle // e.g. 08.10.2008 for locale=de
        fmt.timeStyle = .NoStyle
        let now = NSDate()
        
        let settings = NSUserDefaults.standardUserDefaults()
        settings.setObject(fmt.stringFromDate(now), forKey:LAST_DOWNLOAD)
        
        let interval = settings.integerForKey(UPDATE_INTERVAL)
        
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
        
        settings.setObject(nextDownload, forKey:NEXT_DOWNLOAD)
    }

    class func filename() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.ApplicationSupportDirectory, .UserDomainMask, true);
        let supportDirectory = paths[0]
    
        return supportDirectory.stringByAppendingPathComponent(CARDS_FILENAME)
    }
    
    class func filenameEn() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.ApplicationSupportDirectory, .UserDomainMask, true);
        let supportDirectory = paths[0]
        
        return supportDirectory.stringByAppendingPathComponent(CARDS_FILENAME_EN)
    }
    
    class func removeFiles() {
        let fileMgr = NSFileManager.defaultManager()
        _ = try? fileMgr.removeItemAtPath(filename())
        _ = try? fileMgr.removeItemAtPath(filenameEn())
    
        CardManager.initialize()
    }

}