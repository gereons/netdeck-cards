//
//  Faction.swift
//  NetDeck
//
//  Created by Gereon Steffens on 14.11.15.
//  Copyright © 2021 Gereon Steffens. All rights reserved.
//

import Foundation
import UIKit.UIColor
import SwiftyUserDefaults

// @objc to make NSPredicates on card.faction work

@objc enum Faction: Int {
    
    case none = -1
    case neutral
    
    case haasBioroid, weyland, nbn, jinteki
    
    case anarch, shaper, criminal
    
    case adam, apex, sunnyLebeau

    private static var faction2name = [Faction: String]()
    
    static let runnerFactionsCore: [Faction] = [ .anarch, .criminal, .shaper ]
    static let runnerMiniFactions: [Faction] = [ .adam, .apex, .sunnyLebeau ]
    static let runnerFactionsAll = runnerFactionsCore + runnerMiniFactions
    
    private(set) static var runnerFactionNamesAll = [String]()
    private(set) static var runnerFactionNamesCore = [String]()
    
    static let corpFactions: [Faction] = [ .haasBioroid, .jinteki, .nbn, .weyland ]
    private(set) static var corpFactionNames = [String]()
    
    private static var allFactions: TableData<String>!
    private static var allFactionsCore: TableData<String>!
    
    static let weylandConsortium = "Weyland Consortium"
    
    static func name(for faction: Faction) -> String {
        return Faction.faction2name[faction] ?? "n/a"
    }
    
    static func initializeFactionNames(_ factionsDict: [Faction: String]) -> Bool {
        faction2name = [:]
        faction2name[.none] = Constant.kANY
        faction2name[.neutral] = "Neutral".localized()
        
        let expectedNames = runnerFactionsAll.count + corpFactions.count + 2 // +2 for "any" and "neutral"
        faction2name.merge(factionsDict) { (current, _) in return current }
        assert(faction2name.count == expectedNames)
        if faction2name.count != expectedNames {
            return false
        }

        runnerFactionNamesAll = []
        runnerFactionNamesCore = []
        corpFactionNames = []

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

        allFactions = TableData(sections: factionSections, values: factionsAll)
        allFactionsCore = TableData(sections: factionSections, values: factionsCore)
        
        runnerFactionNamesAll.insert(contentsOf: common, at: 0)
        runnerFactionNamesCore.insert(contentsOf: common, at: 0)
        corpFactionNames.insert(contentsOf: common, at: 0)
        
        return true
    }
    
    static func factionsFor(role: Role, packUsage: PackUsage) -> [String] {
        assert(role != .none, "no role")
        
        if role == .runner {
            if packUsage == .selected {
                let dataDestinyAllowed = Defaults[.useDataDestiny]
                return dataDestinyAllowed ? runnerFactionNamesAll : runnerFactionNamesCore
            } else {
                return runnerFactionNamesAll
            }
        } else {
            return corpFactionNames
        }
    }
    
    static func factionsForBrowser(packUsage: PackUsage) -> TableData<String> {
        if packUsage == .selected {
            let dataDestinyAllowed = Defaults[.useDataDestiny]
            return dataDestinyAllowed ? allFactions : allFactionsCore
        } else {
            return allFactions
        }
    }
    
    static func shortName(for faction: Faction) -> String {
        switch faction {
        case .haasBioroid: return "H-B"
        case .weyland: return "Weyland".localized()
        case .sunnyLebeau: return "Sunny"
        default: return Faction.name(for: faction)
        }
    }
    
    // needed for the jinteki.net uploader
    static func fullName(for faction: Faction) -> String {
        switch faction {
        case .weyland:
            return Faction.weylandConsortium
        default:
            return Faction.name(for: faction)
        }
    }
}

extension Faction {
    private static let colors: [Faction: UInt] = [
        .jinteki:      0x940c00,
        .nbn:          0xd7a32d,
        .weyland:      0x2d7868,
        .haasBioroid:  0x6b2b8a,
        .shaper:       0x6ab545,
        .criminal:     0x4f67b0,
        .anarch:       0xf47c28,
        .adam:         0xae9543,
        .apex:         0xa8403d,
        .sunnyLebeau:  0x776e6f
    ]

    static func color(for faction: Faction) -> UIColor {
        guard let hex = hexColor(for: faction) else {
            return .label
        }

        return UIColor(rgb: hex)
    }
    
    static func hexColor(for faction: Faction) -> UInt? {
        return Faction.colors[faction]
    }
    
}

