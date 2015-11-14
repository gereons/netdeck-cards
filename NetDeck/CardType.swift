//
//  CardType.swift
//  NetDeck
//
//  Created by Gereon Steffens on 14.11.15.
//  Copyright © 2015 Gereon Steffens. All rights reserved.
//

import Foundation

@objc class CardType: NSObject {
    private static let code2type: [String: NRCardType] = [
        "identity": .Identity,
        "asset": .Asset,
        "agenda": .Agenda,
        "ice": .Ice,
        "upgrade": .Upgrade,
        "operation": .Operation,
        "program": .Program,
        "hardware": .Hardware,
        "resource": .Resource,
        "event": .Event,
    ]
    
    // NB: Card diff depends on ICE/Program being the last entries!
    private static let runnerTypes:[NRCardType] = [ .Event, .Hardware, .Resource, .Program ];
    private static let corpTypes:[NRCardType] = [ .Agenda, .Asset, .Upgrade, .Operation, .Ice ];
    
    private static var type2name = [NRCardType: String]()
    private static var runnerTypeNames = [String]()
    private static var corpTypeNames = [String]()
    private(set) static var allTypes: TableData!
    
    class func initializeCardTypes(cards: NSArray) {
        type2name.removeAll()
        type2name[.None] = kANY
        for card in cards as! [Card] {
            type2name[card.type] = card.typeStr
        }
        
        for type in runnerTypes {
            runnerTypeNames.append(CardType.name(type)!)
        }
        for type in corpTypes {
            corpTypeNames.append(CardType.name(type)!)
        }
        
        let typeSections = [ "", "Runner".localized(), "Corp".localized() ];
        let types = [
            [CardType.name(.None)!, CardType.name(.Identity)!],
            runnerTypeNames,
            corpTypeNames]
        
        allTypes = TableData(sections:typeSections, andValues:types);
        
        runnerTypeNames.insert(kANY, atIndex: 0)
        corpTypeNames.insert(kANY, atIndex: 0)
    }
    
    class func name(type: NRCardType) -> String? {
        return type2name[type]
    }
    
    class func type(type: String) -> NRCardType {
        if let t = code2type[type] {
            return t
        }
        return .None
    }
    
    class func typesForRole(role: NRRole) -> [String] {
        assert(role != .None, "no role");
        return role == .Runner ? runnerTypeNames : corpTypeNames;
    }
}