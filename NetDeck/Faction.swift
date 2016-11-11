//
//  Faction.swift
//  NetDeck
//
//  Created by Gereon Steffens on 14.11.15.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import Foundation

class Faction: NSObject {
    
    private static var faction2name = [NRFaction: String]()
    
    private static let runnerFactions: [NRFaction] = [ .anarch, .criminal, .shaper, .adam, .apex, .sunnyLebeau ]
    private static let runnerFactionsPreDAD: [NRFaction] = [ .anarch, .criminal, .shaper ]
    private static let corpFactions: [NRFaction] = [ .haasBioroid, .jinteki, .nbn, .weyland ]
    
    private static var runnerFactionNames = [String]()
    private static var runnerFactionNamesPreDAD = [String]()
    private static var corpFactionNames = [String]()
    
    private static var allFactions: TableData!
    private static var allFactionsPreDAD: TableData!
    
    static let weylandConsortium = "Weyland Consortium"
    
    class func name(for faction: NRFaction) -> String? {
        return Faction.faction2name[faction]
    }
    
    class func initializeFactionNames(_ cards: [Card]) -> Bool {
        faction2name = [NRFaction: String]()
        faction2name[.none] = Constant.kANY
        faction2name[.neutral] = "Neutral".localized()
        
        let expectedNames = runnerFactions.count + corpFactions.count + 2 // +2 for "any" and "neutral"
        
        runnerFactionNames = [String]()
        runnerFactionNamesPreDAD = [String]()
        corpFactionNames = [String]()
        
        for card in cards {
            faction2name[card.faction] = card.factionStr
            if faction2name.count == expectedNames {
                break
            }
        }
        assert(faction2name.count == expectedNames)
        if faction2name.count != expectedNames {
            return false
        }
        
        let common = [ Faction.name(for: .none)!, Faction.name(for: .neutral)! ]
        
        for faction in runnerFactions {
            runnerFactionNames.append(Faction.name(for: faction)!)
        }
        for faction in runnerFactionsPreDAD {
            runnerFactionNamesPreDAD.append(Faction.name(for: faction)!)
        }
        for faction in corpFactions {
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
            FIXME("packUsage!")
            let dataDestinyAllowed = UserDefaults.standard.bool(forKey: SettingsKeys.USE_DATA_DESTINY)
            return dataDestinyAllowed ? runnerFactionNames : runnerFactionNamesPreDAD
        } else {
            return corpFactionNames
        }
    }
    
    class func factionsForBrowser() -> TableData {
        FIXME("packUsage!")
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

