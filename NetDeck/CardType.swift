//
//  CardType.swift
//  NetDeck
//
//  Created by Gereon Steffens on 14.11.15.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import Foundation

class CardType: NSObject {
    
    // NB: Card diff depends on ICE/Program being the last entries!
    private static let runnerTypes: [NRCardType] = [ .event, .hardware, .resource, .program ]
    private static let corpTypes: [NRCardType] = [ .agenda, .asset, .upgrade, .operation, .ice ]
    
    private static var type2name = [NRCardType: String]()
    static var runnerTypeNames = [String]()
    static var corpTypeNames = [String]()
    private(set) static var allTypes: TableData!
    
    class func initializeCardTypes(_ cards: [Card]) -> Bool {
        runnerTypeNames = [String]()
        corpTypeNames = [String]()
        
        assert(Codes.code2Type.count == runnerTypes.count + corpTypes.count + 1) // +1 for IDs
        if Codes.code2Type.count != runnerTypes.count + corpTypes.count + 1 {
            return false
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
        
        allTypes = TableData(sections: typeSections, andValues: types as NSArray)
        
        runnerTypeNames.insert(Constant.kANY, at: 0)
        corpTypeNames.insert(Constant.kANY, at: 0)
        
        return true
    }
    
    class func name(for type: NRCardType) -> String {
        return type2name[type] ?? "n/a"
    }
    
    class func typesFor(role: NRRole) -> [String] {
        assert(role != .none, "no role")
        return role == .runner ? runnerTypeNames : corpTypeNames
    }
}
