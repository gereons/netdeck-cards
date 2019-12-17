//
//  Types.swift
//  NetDeck
//
//  Created by Gereon Steffens on 14.11.15.
//  Copyright © 2019 Gereon Steffens. All rights reserved.
//

import Foundation

struct Constant {
    static let kANY = "Any"
    static let arrow = " ▾"
}

enum Role: Int {
    case none = -1
    case runner, corp
}

enum DeckSort: Int {
    case byType           // sort by type, then alpha
    case byFactionType    // sort by faction, then type, then alpha
    case bySetType        // sort by set, then type, then alpha
    case bySetNum         // sort by set, then number in set
}

enum CardSearchScope: Int {
    case all
    case name
    case text
}

enum DeckSearchScope: Int {
    case all
    case name
    case identity
    case card
}

enum DeckListSort: Int {
    case byDate
    case byFaction
    case byName
}

enum CardView: Int {
    case image
    case largeTable
    case smallTable
}

enum CardFilterView: Int {
    case list
    case img2
    case img3
}

enum BrowserSort: Int {
    case byType
    case byFaction
    case byTypeFaction
    case bySet
    case bySetFaction
    case bySetType
    case bySetNumber
    case byCost
    case byStrength
}

enum ImportSource: Int {
    case none
    case dropbox
    case netrunnerDb
}

enum Filter: Int {
    case all
    case runner
    case corp
}

enum PackUsage: Int {
    case all
    case selected
}

enum DeckLegality: Equatable {
    case casual
    case standard(mwl: Int)
    case cacheRefresh
    case onesies
    case modded

    var mwl: Int {
        switch self {
        case .standard(let mwl): return mwl
        case .cacheRefresh: return MWLManager.activeMWL
        default: return 0
        }
    }

    var isStandard: Bool {
        switch self {
        case .standard: return true
        default: return false
        }
    }

    static func==(_ lhs: DeckLegality, _ rhs: DeckLegality) -> Bool {
        switch (lhs, rhs) {
        case (.casual, .casual): return true
        case (.standard(let m1), .standard(let m2)): return m1 == m2
        case (.cacheRefresh, .cacheRefresh): return true
        case (.modded, .modded): return true
        case (.onesies, .onesies): return true
        default: return false
        }
    }

    static func==(_ lhs: DeckLegality, _ rhs: Int) -> Bool {
        switch lhs {
        case .standard(let m): return m == rhs
        default: return false
        }
    }
}

struct RotatedPacks {
    let packs: Set<String>
    let cycles: [String]

    init(packs: [String], cycles: [String]) {
        self.packs = Set(packs)
        self.cycles = cycles
    }

    static let _2017 = RotatedPacks(
        packs: [ "core",
                 "wla", "ta", "ce", "asis", "hs", "fp", // genesis
                 "om", "st", "mt", "tc", "fal", "dt"    // spin
        ],
        cycles: [ "genesis", "spin" ]
    )

    static let _2018 = _2017.adding(
        packs: [ "core2", "td" ],
        cycles: [ "terminal-directive" ]
    )

    static let _2019 = _2018.adding(
        packs: [ "cac",                                   // c+c
                 "up", "tsb", "fc", "uao", "atr", "ts" ], // lunar
        cycles: [ "lunar", "creation-and-control" ]
    )

    private func adding(packs: [String], cycles: [String]) -> RotatedPacks {
        return RotatedPacks(packs: Array(self.packs) + packs, cycles: self.cycles + cycles)
    }
}

enum Rotation: Int {
    case _2017
    case _2018
    case _2019

    var packs: RotatedPacks {
        switch self {
        case ._2017: return RotatedPacks._2017
        case ._2018: return RotatedPacks._2018
        case ._2019: return RotatedPacks._2019
        }
    }

    // MARK: - settings values / titles
    private static let all = [ Rotation._2017, ._2018, ._2019 ]
    private static let names = [
        "2017 (Genesis + Spin)",
        "2018 (Terminal Directive)",
        "2019 (Lunar + C&C)"
    ]
    
    static func values() -> [Int] {
        return all.map { $0.rawValue }
    }

    static func titles() -> [String] {
        return all.map { names[$0.rawValue].localized() }
    }
}

enum FilterAttribute: Int {
    case mu
    case cost
    case agendaPoints
    case strength
    case influence
    case name
    case text
    case nameAndText
    case faction
    case set
    case type
    case subtype
    
    func localized() -> String {
        switch self {
        case .type: return "Type".localized()
        case .subtype: return "Subtype".localized()
        case .faction: return "Faction".localized()
        case .set: return "Set".localized()
        default: return "n/a"
        }
    }
}

enum FilterValue {
    case int(_: Int)
    case strings(_: Set<String>)
    
    static func string(_ s: String) -> FilterValue {
        return FilterValue.strings(Set([s]))
    }
    
    var int: Int? {
        switch self {
        case .int(let v): return v
        default: return nil
        }
    }
    
    var strings: Set<String>? {
        switch self {
        case .strings(let v): return v
        default: return nil
        }
    }
    
    var string: String? {
        switch self {
        case .strings(let v): return Array(v)[0]
        default: return nil
        }
    }
    
    var isAny: Bool {
        if let set = self.strings {
            return set.count == 0 || (set.count == 1 && Array(set)[0] == Constant.kANY)
        } else {
            return false
        }
    }
}
