//
//  Faction.swift
//  NetDeck
//
//  Created by Gereon Steffens on 14.11.15.
//  Copyright © 2015 Gereon Steffens. All rights reserved.
//

import Foundation

@objc class Faction: NSObject {
    
    static var faction2name = [NRFaction: String]()
    static let code2faction: [String: NRFaction] = [
        "anarch": .Anarch,
        "shaper": .Shaper,
        "criminal": .Criminal,
        "weyland-consortium": .Weyland,
        "haas-bioroid": .HaasBioroid,
        "nbn": .NBN,
        "jinteki": .Jinteki,
        "adam": .Adam,
        "apex": .Apex,
        "sunny-lebeau": .SunnyLebeau,
        "neutral": .Neutral
    ]
    private static var runnerFactions: [NRFaction] = [ .Anarch, .Criminal, .Shaper, .Adam, .Apex, .SunnyLebeau ]
    private static var runnerFactionsPreDAD: [NRFaction] = [ .Anarch, .Criminal, .Shaper ]
    private static var corpFactions: [NRFaction] = [ .HaasBioroid, .Jinteki, .NBN, .Weyland ]
    
    static var runnerFactionNames = [String]()
    static var runnerFactionNamesPreDAD = [String]()
    static var corpFactionNames = [String]()
    
    private(set) static var allFactions: TableData!
    
    override class func initialize() {
        faction2name[.None] = kANY
    }
    
    class func name(faction: NRFaction) -> String? {
        return Faction.faction2name[faction]
    }
    
    class func initializeFactionNames(cards: [Card]) {
        for card in cards {
            faction2name[card.faction] = card.factionStr
        }
        
        let common = [ Faction.name(.None)!, Faction.name(.Neutral)! ]
        
        for faction in runnerFactions
        {
            runnerFactionNames.append(Faction.name(faction)!)
        }
        for faction in runnerFactionsPreDAD
        {
            runnerFactionNamesPreDAD.append(Faction.name(faction)!)
        }
        for faction in corpFactions
        {
            corpFactionNames.append(Faction.name(faction)!)
        }
        
        let factionSections = [ "", "Runner".localized(), "Corp".localized() ]
        let factions = [ common, runnerFactionNames, corpFactionNames ]

        allFactions = TableData(sections: factionSections, andValues: factions)
        
        runnerFactionNames.insertContentsOf(common, at: 0)
        runnerFactionNamesPreDAD.insertContentsOf(common, at: 0)
        corpFactionNames.insertContentsOf(common, at: 0)
    }
    
    class func faction(faction: String) -> NRFaction {
        if let faction = code2faction[faction] {
            return faction
        }
        return .None
    }
    
    class func factionsForRole(role: NRRole) -> [String] {
        assert(role != .None, "no role")
        
        if (role == .Runner)
        {
            let dataDestinyAllowed = NSUserDefaults.standardUserDefaults().boolForKey(SettingsKeys.USE_DATA_DESTINY)
            return dataDestinyAllowed ? runnerFactionNames : runnerFactionNamesPreDAD
        }
        return corpFactionNames
    }
    
    class func shortName(faction: NRFaction) -> String {
        switch faction {
        case .HaasBioroid: return "H-B"
        case .Weyland: return "Weyland"
        case .SunnyLebeau: return "Sunny"
        default: return Faction.name(faction)!
        }
    }
}

