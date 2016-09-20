//
//  Faction.swift
//  NetDeck
//
//  Created by Gereon Steffens on 14.11.15.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import Foundation

class Faction: NSObject {
    
    fileprivate static var faction2name = [NRFaction: String]()
    
    fileprivate static let runnerFactions: [NRFaction] = [ .anarch, .criminal, .shaper, .adam, .apex, .sunnyLebeau ]
    fileprivate static let runnerFactionsPreDAD: [NRFaction] = [ .anarch, .criminal, .shaper ]
    fileprivate static let corpFactions: [NRFaction] = [ .haasBioroid, .jinteki, .nbn, .weyland ]
    
    fileprivate static var runnerFactionNames = [String]()
    fileprivate static var runnerFactionNamesPreDAD = [String]()
    fileprivate static var corpFactionNames = [String]()
    
    fileprivate static var allFactions: TableData!
    fileprivate static var allFactionsPreDAD: TableData!
    
    static let weylandConsortium = "Weyland Consortium"
    
    override class func initialize() {
        faction2name[.none] = Constant.kANY
        faction2name[.neutral] = "Neutral".localized()
    }
    
    class func name(for faction: NRFaction) -> String? {
        return Faction.faction2name[faction]
    }
    
    class func initializeFactionNames(_ cards: [Card]) -> Bool {
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
        
        let common = [ Faction.name(for: .none)!, Faction.name(for: .neutral)! ]
        
        for faction in runnerFactions
        {
            runnerFactionNames.append(Faction.name(for: faction)!)
        }
        for faction in runnerFactionsPreDAD
        {
            runnerFactionNamesPreDAD.append(Faction.name(for: faction)!)
        }
        for faction in corpFactions
        {
            corpFactionNames.append(Faction.name(for: faction)!)
        }
        
        let factionSections = [ "", "Runner".localized(), "Corp".localized() ]
        let factions = [ common, runnerFactionNames, corpFactionNames ]
        let factionsPreDAD = [ common, runnerFactionNamesPreDAD, corpFactionNames ]

        allFactions = TableData(sections: factionSections as NSArray, andValues: factions as NSArray)
        allFactionsPreDAD = TableData(sections: factionSections as NSArray, andValues: factionsPreDAD as NSArray)
        
        runnerFactionNames.insert(contentsOf: common, at: 0)
        runnerFactionNamesPreDAD.insert(contentsOf: common, at: 0)
        corpFactionNames.insert(contentsOf: common, at: 0)
        
        return true
    }
    
    class func factionsFor(role: NRRole) -> [String] {
        assert(role != .none, "no role")
        
        if (role == .runner)
        {
            let dataDestinyAllowed = UserDefaults.standard.bool(forKey: SettingsKeys.USE_DATA_DESTINY)
            return dataDestinyAllowed ? runnerFactionNames : runnerFactionNamesPreDAD
        }
        return corpFactionNames
    }
    
    class func factionsForBrowser() -> TableData {
        let dataDestinyAllowed = UserDefaults.standard.bool(forKey: SettingsKeys.USE_DATA_DESTINY)
        
        return dataDestinyAllowed ? allFactions : allFactionsPreDAD
    }
    
    class func shortName(for faction: NRFaction) -> String {
        switch faction {
        case .haasBioroid: return "H-B"
        case .weyland: return "Weyland".localized()
        case .sunnyLebeau: return "Sunny"
        default: return Faction.name(for: faction)!
        }
    }
    
    // needed for the jinteki.net uploader
    class func fullName(for faction: NRFaction) -> String {
        switch faction {
        case .weyland:
            return Faction.weylandConsortium
        default:
            return Faction.name(for: faction)!
        }
    }
}

