//
//  Types.swift
//  NetDeck
//
//  Created by Gereon Steffens on 14.11.15.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import Foundation

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

enum BrowserSort: Int {
    case byType
    case byFaction
    case byTypeFaction
    case bySet
    case bySetFaction
    case bySetType
    case bySetNumber
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

enum MWL: Int {
    case none
    case v1_0   // as of 2016-02-01
    case v1_1   // as of 2016-08-01
//    case v1_2   // as of 2017-02-01 (?)
    
    // map from "mwl_code" values we get from the NRDB API
    static let codeMap: [String: MWL] = [
        "NAPD_MWL_1.0": .v1_0,
        "NAPD_MWL_1.1": .v1_1,
//        "NAPD_MWL_1.2": .v1_2
    ]
    
    static func by(code: String) -> MWL {
        return MWL.codeMap[code] ?? .none
    }
}
