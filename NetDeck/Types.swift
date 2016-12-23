//
//  Types.swift
//  NetDeck
//
//  Created by Gereon Steffens on 14.11.15.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import Foundation

@objc enum NRCardType: Int {
    case none = -1
    case identity

    // corp
    case agenda, asset, upgrade, operation, ice

    // runner
    case event, hardware, resource, program
}

@objc enum NRRole: Int {
    case none = -1
    case runner, corp
}

@objc enum NRFaction: Int {
    case none = -1
    case neutral
    
    case haasBioroid, weyland, nbn, jinteki
    
    case anarch, shaper, criminal
    
    case adam, apex, sunnyLebeau
}

@objc enum NRDeckState: Int {
    case none = -1
    case active, testing, retired
}

@objc enum NRDeckSort: Int {
    case byType           // sort by type, then alpha
    case byFactionType    // sort by faction, then type, then alpha
    case bySetType        // sort by set, then type, then alpha
    case bySetNum         // sort by set, then number in set
}

@objc enum NRSearchScope: Int {
    case all
    case name
    case text
}

@objc enum NRDeckSearchScope: Int {
    case all
    case name
    case identity
    case card
}

@objc enum NRDeckListSort: Int {
    case byDate
    case byFaction
    case byName
}

@objc enum NRCardView: Int {
    case image
    case largeTable
    case smallTable
}

@objc enum NRBrowserSort: Int {
    case byType
    case byFaction
    case byTypeFaction
    case bySet
    case bySetFaction
    case bySetType
    case bySetNumber
}

@objc enum NRImportSource: Int {
    case none
    case dropbox
    case netrunnerDb
}

@objc enum NRFilter: Int {
    case all
    case runner
    case corp
}

@objc enum NRPackUsage: Int {
    case all
    case selected
    case allAfterRotation
}

@objc enum NRMWL: Int {
    case none
    case v1_0   // as of 2016-02-01
    case v1_1   // as of 2016-08-01
    
    // map from "mwl_code" values we get from the NRDB API
    static let codeMap: [String: NRMWL] = [
        "NAPD_MWL_1.0": .v1_0,
        "NAPD_MWL_1.1": .v1_1
    ]
    
    static func by(code: String) -> NRMWL {
        return NRMWL.codeMap[code] ?? .none
    }
}
