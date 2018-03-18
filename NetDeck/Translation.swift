//
//  Translation.swift
//  NetDeck
//
//  Created by Gereon Steffens on 04.06.16.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import Foundation

class Translation {
    static func forTerm(_ term: String) -> String {
        return data[term] ?? term.capitalized
    }
    
    private static let data = [
        "adam": "Adam",
        "anarch": "Anarch",
        "apex": "Apex",
        "criminal": "Criminal",
        "haas-bioroid": "Haas-Bioroid",
        "jinteki": "Jinteki",
        "nbn": "NBN",
        "neutral-runner": "Neutral",
        "neutral-corp": "Neutral",
        "shaper": "Shaper",
        "sunny-lebeau": "Sunny Lebeau",
        "weyland-consortium": "Weyland",

        "agenda": "Agenda",
        "asset": "Asset",
        "event": "Event",
        "hardware": "Hardware",
        "ice": "ICE",
        "identity": "Identity",
        "operation": "Operation",
        "program": "Program",
        "resource": "Resource",
        "upgrade": "Upgrade",

        "runner": "Runner",
        "corp": "Corp"
    ]
}
