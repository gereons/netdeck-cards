//
//  CardType.swift
//  NetDeck
//
//  Created by Gereon Steffens on 14.11.15.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import Foundation

// @objc to make NSPredicates on card.type work

@objc enum CardType: Int {
    
    case none = -1
    case identity
        
    // corp
    case agenda, asset, upgrade, operation, ice
        
    // runner
    case event, hardware, resource, program
    
    // NB: Card diff depends on ICE/Program being the last entries!
    private static let runnerTypes: [CardType] = [ .event, .hardware, .resource, .program ]
    private static let corpTypes: [CardType] = [ .agenda, .asset, .upgrade, .operation, .ice ]
    
    private static var type2name = [CardType: String]()
    static var runnerTypeNames = [String]()
    static var corpTypeNames = [String]()
    private(set) static var allTypes: TableData<String>!
    
    static func initializeCardType(_ typesDict: [CardType: String]) -> Bool {
        runnerTypeNames = []
        corpTypeNames = []
        
        type2name.removeAll()
        type2name[.none] = Constant.kANY
        type2name.merge(typesDict) { (current, _) in return current }
        for (type, str) in typesDict {
            type2name[type] = str
        }
        let expectedTypes = 11 // 10 card types, +1 for "Any"
        assert(type2name.count == expectedTypes)
        if type2name.count != expectedTypes {
            return false
        }
        
        for type in runnerTypes {
            runnerTypeNames.append(CardType.name(for: type))
        }
        for type in corpTypes {
            corpTypeNames.append(CardType.name(for: type))
        }
        
        let typeSections = [ "", "Runner".localized(), "Corp".localized() ]
        let types = [
            [CardType.name(for: .none), CardType.name(for: .identity)],
            runnerTypeNames,
            corpTypeNames
        ]
        
        allTypes = TableData(sections: typeSections, values: types)
        
        runnerTypeNames.insert(Constant.kANY, at: 0)
        corpTypeNames.insert(Constant.kANY, at: 0)
        
        return true
    }
    
    static func name(for type: CardType) -> String {
        return type2name[type] ?? "n/a"
    }
    
    static func typesFor(role: Role) -> [String] {
        assert(role != .none, "no role")
        return role == .runner ? runnerTypeNames : corpTypeNames
    }
}
