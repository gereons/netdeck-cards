//
//  Codes.swift
//  NetDeck
//
//  Created by Gereon Steffens on 22.03.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import Foundation


class Codes {
    
    static let code2Type: [String: NRCardType] = [
        "identity": .identity,
        
        "asset": .asset,
        "agenda": .agenda,
        "ice": .ice,
        "upgrade": .upgrade,
        "operation": .operation,
        
        "program": .program,
        "hardware": .hardware,
        "resource": .resource,
        "event": .event,
    ]
    
    static let code2Role: [String: NRRole] = [
        "runner": .runner,
        "corp": .corp,
    ]
    
    static let code2Faction: [String: NRFaction] = [
        "anarch": .anarch,
        "criminal": .criminal,
        "shaper": .shaper,
        
        "weyland-consortium": .weyland,
        "haas-bioroid": .haasBioroid,
        "nbn": .nbn,
        "jinteki": .jinteki,
        
        "adam": .adam,
        "apex": .apex,
        "sunny-lebeau": .sunnyLebeau,
        
        "neutral": .neutral,
        "neutral-runner": .neutral,
        "neutral-corp": .neutral
    ]
    
    class func typeFor(code: String) -> NRCardType {
        return code2Type[code] ?? .none
    }
    
    class func roleFor(code: String) -> NRRole {
        return code2Role[code] ?? .none
    }
    
    class func factionFor(code: String) -> NRFaction {
        return code2Faction[code] ?? .none
    }
}
