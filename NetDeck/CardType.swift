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
    fileprivate static let runnerTypes: [NRCardType] = [ .event, .hardware, .resource, .program ]
    fileprivate static let corpTypes: [NRCardType] = [ .agenda, .asset, .upgrade, .operation, .ice ]
    
    fileprivate static var type2name = [NRCardType: String]()
    fileprivate static var runnerTypeNames = [String]()
    fileprivate static var corpTypeNames = [String]()
    fileprivate(set) static var allTypes: TableData!
    
    class func initializeCardTypes(_ cards: [Card]) -> Bool {
        runnerTypeNames = [String]()
        corpTypeNames = [String]()
        
        assert(Codes.code2Type.count == runnerTypes.count + corpTypes.count + 1) // +1 for IDs
        if Codes.code2Type.count != runnerTypes.count + corpTypes.count + 1 {
            return false
        }
        
        type2name.removeAll()
        type2name[.none] = Constant.kANY
        for card in cards {
            type2name[card.type] = card.typeStr
        }
        assert(type2name.count == Codes.code2Type.count + 1) // +1 for "Any"
        if type2name.count != Codes.code2Type.count + 1 {
            return false
        }
        
        for type in runnerTypes {
            runnerTypeNames.append(CardType.name(type))
        }
        for type in corpTypes {
            corpTypeNames.append(CardType.name(type))
        }
        
        let typeSections = [ "", "Runner".localized(), "Corp".localized() ]
        let types = [
            [CardType.name(.none), CardType.name(.identity)],
            runnerTypeNames,
            corpTypeNames
        ]
        
        allTypes = TableData(sections:typeSections as NSArray, andValues:types as NSArray)
        
        runnerTypeNames.insert(Constant.kANY, at: 0)
        corpTypeNames.insert(Constant.kANY, at: 0)
        
        return true
    }
    
    class func name(_ type: NRCardType) -> String {
        return type2name[type] ?? "n/a"
    }
    
    class func typesForRole(_ role: NRRole) -> [String] {
        assert(role != .none, "no role")
        return role == .runner ? runnerTypeNames : corpTypeNames
    }
}
