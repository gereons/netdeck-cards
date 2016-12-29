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
    
    static let runnerFactionsCore: [NRFaction] = [ .anarch, .criminal, .shaper ]
    static let runnerMiniFactions: [NRFaction] = [ .adam, .apex, .sunnyLebeau ]
    static let runnerFactionsAll = runnerFactionsCore + runnerMiniFactions
    
    private static var runnerFactionNamesAll = [String]()
    private static var runnerFactionNamesCore = [String]()
    
    static let corpFactions: [NRFaction] = [ .haasBioroid, .jinteki, .nbn, .weyland ]
    private static var corpFactionNames = [String]()
    
    private static var allFactions: TableData!
    private static var allFactionsCore: TableData!
    
    static let weylandConsortium = "Weyland Consortium"
    
    class func name(for faction: NRFaction) -> String {
        return Faction.faction2name[faction] ?? "n/a"
    }
    
    class func initializeFactionNames(_ cards: [Card]) -> Bool {
        faction2name = [NRFaction: String]()
        faction2name[.none] = Constant.kANY
        faction2name[.neutral] = "Neutral".localized()
        
        let expectedNames = runnerFactionsAll.count + corpFactions.count + 2 // +2 for "any" and "neutral"
        
        runnerFactionNamesAll = [String]()
        runnerFactionNamesCore = [String]()
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
        
        let common = [ Faction.name(for: .none), Faction.name(for: .neutral) ]
        
        for faction in runnerFactionsAll {
            runnerFactionNamesAll.append(Faction.name(for: faction))
        }
        for faction in runnerFactionsCore {
            runnerFactionNamesCore.append(Faction.name(for: faction))
        }
        for faction in corpFactions {
            corpFactionNames.append(Faction.name(for: faction))
        }
        
        let factionSections = [ "", "Runner".localized(), "Corp".localized() ]
        let factionsAll = [ common, runnerFactionNamesAll, corpFactionNames ]
        let factionsCore = [ common, runnerFactionNamesCore, corpFactionNames ]

        allFactions = TableData(sections: factionSections, andValues: factionsAll as NSArray)
        allFactionsCore = TableData(sections: factionSections, andValues: factionsCore as NSArray)
        
        runnerFactionNamesAll.insert(contentsOf: common, at: 0)
        runnerFactionNamesCore.insert(contentsOf: common, at: 0)
        corpFactionNames.insert(contentsOf: common, at: 0)
        
        return true
    }
    
    class func factionsFor(role: NRRole, packUsage: NRPackUsage) -> [String] {
        assert(role != .none, "no role")
        
        if (role == .runner)
        {
            if packUsage == .selected {
                let dataDestinyAllowed = UserDefaults.standard.bool(forKey: SettingsKeys.USE_DATA_DESTINY)
                return dataDestinyAllowed ? runnerFactionNamesAll : runnerFactionNamesCore
            } else {
                return runnerFactionNamesAll
            }
        } else {
            return corpFactionNames
        }
    }
    
    class func factionsForBrowser(packUsage: NRPackUsage) -> TableData {
        if packUsage == .selected {
            let dataDestinyAllowed = UserDefaults.standard.bool(forKey: SettingsKeys.USE_DATA_DESTINY)
            return dataDestinyAllowed ? allFactions : allFactionsCore
        } else {
            return allFactions
        }
    }
    
    class func shortName(for faction: NRFaction) -> String {
        switch faction {
        case .haasBioroid: return "H-B"
        case .weyland: return "Weyland".localized()
        case .sunnyLebeau: return "Sunny"
        default: return Faction.name(for: faction)
        }
    }
    
    // needed for the jinteki.net uploader
    class func fullName(for faction: NRFaction) -> String {
        switch faction {
        case .weyland:
            return Faction.weylandConsortium
        default:
            return Faction.name(for: faction)
        }
    }
}

