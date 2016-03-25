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
    
    static let code2Role: [String: NRRole] = [
        "runner": .Runner,
        "corp": .Corp,
    ]
    
    static let code2Faction: [String: NRFaction] = [
        "anarch": .Anarch,
        "criminal": .Criminal,
        "shaper": .Shaper,
        
        "weyland-consortium": .Weyland,
        "haas-bioroid": .HaasBioroid,
        "nbn": .NBN,
        "jinteki": .Jinteki,
        
        "adam": .Adam,
        "apex": .Apex,
        "sunny-lebeau": .SunnyLebeau,
        
        "neutral": .Neutral,
    ]
    
    class func typeForCode(code: String) -> NRCardType {
        return code2Type[code] ?? .None
    }
    
    class func roleForCode(code: String) -> NRRole {
        return code2Role[code] ?? .None
    }
    
    class func factionForCode(code: String) -> NRFaction {
        return code2Faction[code] ?? .None
    }
}
