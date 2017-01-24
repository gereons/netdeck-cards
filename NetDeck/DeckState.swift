//
//  DeckState.swift
//  NetDeck
//
//  Created by Gereon Steffens on 14.11.15.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import Foundation

enum DeckState: Int {
    
    case none = -1
    case active, testing, retired

    static let arrow = " ▾"
    private static let states: [DeckState: String] = [
        .none: "All",
        .retired: "Retired",
        .testing: "Testing",
        .active: "Active"
    ]
    
    static func rawLabelFor(_ state: DeckState) -> String {
        return states[state]!
    }
    
    static func labelFor(_ state: DeckState) -> String {
        return rawLabelFor(state).localized()
    }
    
    static func buttonLabelFor(_ state: DeckState) -> String {
        return labelFor(state) + arrow
    }
    
    static func possibleTitles() -> [String] {
        return states.keys.map { DeckState.buttonLabelFor($0) }
    }
}
