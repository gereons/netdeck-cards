//
//  Faction.swift
//  NetDeck
//
//  Created by Gereon Steffens on 14.11.15.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import Foundation

@objc class Faction: NSObject {
    
    private static var faction2name = [NRFaction: String]()
    
    private static let runnerFactions: [NRFaction] = [ .Anarch, .Criminal, .Shaper, .Adam, .Apex, .SunnyLebeau ]
    private static let runnerFactionsPreDAD: [NRFaction] = [ .Anarch, .Criminal, .Shaper ]
    private static let corpFactions: [NRFaction] = [ .HaasBioroid, .Jinteki, .NBN, .Weyland ]
    
    private static var runnerFactionNames = [String]()
    private static var runnerFactionNamesPreDAD = [String]()
    private static var corpFactionNames = [String]()
    
    private static var allFactions: TableData!
    private static var allFactionsPreDAD: TableData!
    
    override class func initialize() {
        faction2name[.None] = Constant.kANY
        faction2name[.Neutral] = "Neutral".localized()
    }
    
    class func name(faction: NRFaction) -> String? {
        return Faction.faction2name[faction]
    }
    
    class func initializeFactionNames(cards: [Card]) -> Bool {
        runnerFactionNames = [String]()
        runnerFactionNamesPreDAD = [String]()
        corpFactionNames = [String]()
        
        for card in cards {
            faction2name[card.faction] = card.factionStr
        }
        assert(faction2name.count == runnerFactions.count + corpFactions.count + 2)
        if faction2name.count != runnerFactions.count + corpFactions.count + 2 {
            return false
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
        let factionsPreDAD = [ common, runnerFactionNamesPreDAD, corpFactionNames ]

        allFactions = TableData(sections: factionSections, andValues: factions)
        allFactionsPreDAD = TableData(sections: factionSections, andValues: factionsPreDAD)
        
        runnerFactionNames.insertContentsOf(common, at: 0)
        runnerFactionNamesPreDAD.insertContentsOf(common, at: 0)
        corpFactionNames.insertContentsOf(common, at: 0)
        
        return true
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
    
    class func factionsForBrowser() -> TableData {
        let dataDestinyAllowed = NSUserDefaults.standardUserDefaults().boolForKey(SettingsKeys.USE_DATA_DESTINY)
        
        return dataDestinyAllowed ? allFactions : allFactionsPreDAD
    }
    
    class func shortName(faction: NRFaction) -> String {
        switch faction {
        case .HaasBioroid: return "H-B"
        case .Weyland: return "Weyland".localized()
        case .SunnyLebeau: return "Sunny"
        default: return Faction.name(faction)!
        }
    }
    
    // needed for the jinteki.net uploader
    class func fullName(faction: NRFaction) -> String {
        switch faction {
        case .Weyland:
            return "Weyland Consortium"
        default:
            return Faction.name(faction)!
        }
    }
}

