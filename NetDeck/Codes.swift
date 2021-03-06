//
//  Codes.swift
//  NetDeck
//
//  Created by Gereon Steffens on 22.03.16.
//  Copyright © 2021 Gereon Steffens. All rights reserved.
//

import Foundation


class Codes {
    
    static let code2Type: [String: CardType] = [
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
    
    static let code2Role: [String: Role] = [
        "runner": .runner,
        "corp": .corp,
    ]
    
    static let code2Faction: [String: Faction] = [
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
    
    static func typeFor(code: String) -> CardType {
        return code2Type[code] ?? .none
    }
    
    static func roleFor(code: String) -> Role {
        return code2Role[code] ?? .none
    }
    
    static func factionFor(code: String) -> Faction {
        return code2Faction[code] ?? .none
    }
}
