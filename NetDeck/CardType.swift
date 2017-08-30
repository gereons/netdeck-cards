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
    
    static func initializeCardType(_ cards: [Card]) -> (Bool, String) {
        runnerTypeNames = []
        corpTypeNames = []
        
        assert(Codes.code2Type.count == runnerTypes.count + corpTypes.count + 1) // +1 for IDs
        if Codes.code2Type.count != runnerTypes.count + corpTypes.count + 1 {
            return (false, "type count mismatch: \(Codes.code2Type.count) != \(runnerTypes.count + corpTypes.count + 1)")
        }
        
        type2name.removeAll()
        type2name[.none] = Constant.kANY
        let expectedTypes = Codes.code2Type.count + 1 // +1 for "Any"
        for card in cards {
            type2name[card.type] = card.typeStr
            if type2name.count == expectedTypes {
                break
            }
        }
        assert(type2name.count == expectedTypes)
        if type2name.count != type2name.count {
            return (false, "names count mismatch: \(type2name.count) != \(type2name.count)")
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
        
        return (true, "ok")
    }
    
    static func name(for type: CardType) -> String {
        return type2name[type] ?? "n/a"
    }
    
    static func typesFor(role: Role) -> [String] {
        assert(role != .none, "no role")
        return role == .runner ? runnerTypeNames : corpTypeNames
    }
}
