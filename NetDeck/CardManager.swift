//
//  CardManager.swift
//  NetDeck
//
//  Created by Gereon Steffens on 21.11.15.
//  Copyright © 2015 Gereon Steffens. All rights reserved.
//

import Foundation

@objc class CardManager: NSObject {
    private(set) static var allRunnerCards = [Card]()        // non-id runner cards
    private(set) static var allCorpCards = [Card]()          // non-id corp cards
    private static var allRunnerIdentities = [Card]()   // runner ids
    private static var allCorpIdentities = [Card]()     // corp ids
    
    private static var subtypes = [NRRole: [String: [String] ] ]()
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
    
    private let cardAliases = [
        "08034": "Franklin",  // crick
        "02085": "HQI",       // hq interface
        "02107": "RDI",       // r&d interface
        "06033": "David",     // d4v1d
        "05039": "SW35",      // unreg. s&w '35
        "03035": "LARLA",     // levy ar lab access
        "04029": "PPVP",      // prepaid voicepad
        "01092": "SSCG",      // sansan city grid
        "04034": "SFSS",      // shipment from sansan
        "03049": "ProCo",     // professional contacts
        "02079": "OAI",       // oversight AI
        "08009": "Baby",      // symmetrical visage
        "08003": "Pancakes",  // adjusted chronotype
        "09022": "ASI",       // the all-seeing i
    ]

    class func cardByCode(code: String) -> Card {
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
        assert(role != .None)
        return role == .Runner ? allRunnerCards : allCorpCards;
    }
    
    class func identitiesForRole(role: NRRole) -> [Card]
    {
        assert(role != .None)
        return role == .Runner ? allRunnerIdentities : allCorpIdentities;
    }
    
    class func subtypesForRole(role: NRRole, andType type: String, includeIdentities: Bool) -> [String]? {
        var arr = subtypes[role]?[type]
        
        let includeIds = includeIdentities && (type == kANY || type == identityKey)
        if (includeIds) {
            if (arr == nil) {
                arr = [String]()
            }
            if let set = identitySubtypes[role] {
                for s in set {
                    arr!.append(s)
                }
            }
        }
    
        return arr?.sort({ $0.lowercaseString > $1.lowercaseString })
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
        return true
    }
    
    class func setupFromNrdbApi(array: NSArray) -> Bool {
        return true
    }
    
    class func removeFiles() {
    }
    
    class func setNextDownloadDate() {
    }

    class func addAdditionalNames(json: NSArray, saveFile: Bool) {
    }
}