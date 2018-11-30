//
//  Types.swift
//  NetDeck
//
//  Created by Gereon Steffens on 14.11.15.
//  Copyright © 2018 Gereon Steffens. All rights reserved.
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

enum MWL: Int, Comparable {
    static func < (lhs: MWL, rhs: MWL) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }

    case none
    case v1_0   // as of 2016-02-01
    case v1_1   // as of 2016-08-01
    case v1_2   // as of 2017-04-12
    case v2_0   // as of 2017-10-01
    case v2_1   // as of 2018-02-26
    case v2_2   // as of 2018-09-06
    case v3_0   // as of 2018-12-21

    static let latest = MWL.v3_0

    // map from "mwl_code" values we get from the NRDB API
    private static let codeMap: [String: MWL] = [
        "NAPD_MWL_1.0": .v1_0,
        "NAPD_MWL_1.1": .v1_1,
        "NAPD_MWL_1.2": .v1_2,
        "NAPD_MWL_2.0": .v2_0,
        "NAPD_MWL_2.1": .v2_1,
        "NAPD_MWL_2.2": .v2_2,
        "NAPD_MWL_3.0": .v3_0
    ]

    static func by(code: String) -> MWL {
        return MWL.codeMap[code] ?? .none
    }

    var universalInfluence: Bool {
        switch self {
        case .none, .v1_2: return true
        default: return false
        }
    }

    // MARK: - settings values / titles
    private static let all = [ MWL.none, .v1_0, .v1_1, .v1_2, .v2_0, .v2_1, .v2_2, .v3_0 ]
    private static let names = [ "Casual", "MWL v1.0", "MWL v1.1", "MWL v1.2", "MWL v2.0", "MWL v2.1", "MWL v2.2", "MWL v3.0" ]
    static func values() -> [Int] {
        return all.map { $0.rawValue }
    }

    static func titles() -> [String] {
        return all.map { names[$0.rawValue].localized() }
    }
}

struct MostWantedList {
    let penalties: [String: Int]?
    let banned: Set<String>?
    let restricted: Set<String>?
    
    init(penalties: [String: Int]) {
        self.penalties = penalties
        self.banned = nil
        self.restricted = nil
    }
    
    init(runnerBanned: [String], runnerRestricted: [String], corpBanned: [String], corpRestricted: [String]) {
        self.penalties = nil
        self.banned = Set(runnerBanned).union(corpBanned)
        self.restricted = Set(runnerRestricted).union(corpRestricted)
    }
}

enum DeckLegality: Equatable {
    case casual
    case standard(mwl: MWL)
    case cacheRefresh
    case onesies
    case modded

    var mwl: MWL {
        switch self {
        case .standard(let mwl): return mwl
        case .cacheRefresh: return MWL.latest
        default: return .none
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

    static func==(_ lhs: DeckLegality, _ rhs: MWL) -> Bool {
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

    private func adding(packs: [String], cycles: [String]) -> RotatedPacks {
        return RotatedPacks(packs: Array(self.packs) + packs, cycles: self.cycles + cycles)
    }
}

enum Rotation: Int {
    case _2017
    case _2018

    var packs: RotatedPacks {
        switch self {
        case ._2017: return RotatedPacks._2017
        case ._2018: return RotatedPacks._2018
        }
    }

    // MARK: - settings values / titles
    private static let all = [ Rotation._2017, ._2018 ]
    private static let names = [
        "2017 (Genesis & Spin)",
        "2018 (Terminal Directive)"
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
