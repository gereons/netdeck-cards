//
//  CardType.swift
//  NetDeck
//
//  Created by Gereon Steffens on 14.11.15.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import Foundation

@objc class CardType: NSObject {
    
    // NB: Card diff depends on ICE/Program being the last entries!
    private static let runnerTypes: [NRCardType] = [ .Event, .Hardware, .Resource, .Program ]
    private static let corpTypes: [NRCardType] = [ .Agenda, .Asset, .Upgrade, .Operation, .Ice ]
    
    private static var type2name = [NRCardType: String]()
    private static var runnerTypeNames = [String]()
    private static var corpTypeNames = [String]()
    private(set) static var allTypes: TableData!
    
    class func initializeCardTypes(cards: [Card]) -> Bool {
        runnerTypeNames = [String]()
        corpTypeNames = [String]()
        
        assert(Codes.codesForType.count == runnerTypes.count + corpTypes.count + 1) // +1 for IDs
        if Codes.codesForType.count != runnerTypes.count + corpTypes.count + 1 {
            return false
        }
        
        type2name.removeAll()
        type2name[.None] = kANY
        for card in cards {
            type2name[card.type] = card.typeStr
        }
        assert(type2name.count == Codes.codesForType.count + 1) // +1 for "Any"
        if type2name.count != Codes.codesForType.count + 1 {
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
            [CardType.name(.None), CardType.name(.Identity)],
            runnerTypeNames,
            corpTypeNames
        ]
        
        allTypes = TableData(sections:typeSections, andValues:types)
        
        runnerTypeNames.insert(kANY, atIndex: 0)
        corpTypeNames.insert(kANY, atIndex: 0)
        
        return true
    }
    
    class func name(type: NRCardType) -> String {
        return type2name[type] ?? "n/a"
    }
    
    class func type(code: String) -> NRCardType {
        return Codes.typeForCode(code)
    }
    
    class func typesForRole(role: NRRole) -> [String] {
        assert(role != .None, "no role")
        return role == .Runner ? runnerTypeNames : corpTypeNames
    }
}