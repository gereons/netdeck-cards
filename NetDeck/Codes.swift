//
//  Codes.swift
//  NetDeck
//
//  Created by Gereon Steffens on 22.03.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import Foundation


class Codes {
    
    static let codesForType: [NRCardType: Set<String>] = [
        .Identity: setOf("identity", "identität", "identité", "identidad", "tożsamość"),
        
        .Asset: setOf("asset", "aktivposten", "avoir", "ventaja", "aktywa"),
        .Agenda: setOf("agenda", "projet", "plan", "projekt"),
        .Ice: setOf("ice", "glace", "hielo", "lód"),
        .Upgrade: setOf("upgrade", "extension", "mejora"),
        .Operation: setOf("operation", "opération", "operación", "operacja"),
        
        .Program: setOf("program", "programm", "programme", "programa"),
        .Hardware: setOf("hardware", "matériel", "sprzęt"),
        .Resource: setOf("resource", "ressource", "recurso", "zasób"),
        .Event: setOf("event", "ereignis", "événement", "evento", "wydarzenie"),
    ]
    
    static let codesForRole: [NRRole: Set<String>] = [
        .Runner: setOf("runner", "기업"),
        .Corp: setOf("corp", "konzern", "corpo", "corporación", "korp", "러너")
    ]
    
    static let codesForFaction: [NRFaction: Set<String>] = [
        .Anarch: setOf("anarch", "anarchos", "anarchistas"),
        .Criminal: setOf("criminal", "kriminelle", "criminel", "delicuentes"),
        .Shaper: setOf("shaper", "gestalter", "façonneur", "moldeadores"),
        
        .Weyland: setOf("weyland-consortium"),
        .HaasBioroid: setOf("haas-bioroid"),
        .NBN: setOf("nbn"),
        .Jinteki: setOf("jinteki"),
        
        .Adam: setOf("adam"),
        .Apex: setOf("apex"),
        .SunnyLebeau: setOf("sunny-lebeau"),
        
        .Neutral: setOf("neutral", "neutre", "neutrales")
    ]
    
    class func typeForCode(code: String) -> NRCardType {
        for (type, codes) in codesForType {
            if codes.contains(code) {
                return type
            }
        }
        return .None
    }
    
    class func roleForCode(code: String) -> NRRole {
        for (role, codes) in codesForRole {
            if codes.contains(code) {
                return role
            }
        }
        return .None
    }
    
    class func factionForCode(code: String) -> NRFaction {
        for (faction, codes) in codesForFaction {
            if codes.contains(code) {
                return faction
            }
        }
        return .None
    }
}

private func setOf(str: String...) -> Set<String> {
    return Set<String>(str)
}
