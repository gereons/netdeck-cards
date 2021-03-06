//
//  DeckState.swift
//  NetDeck
//
//  Created by Gereon Steffens on 14.11.15.
//  Copyright © 2021 Gereon Steffens. All rights reserved.
//

import Foundation

// @objc to make NSPredicates on deck.state work

@objc enum DeckState: Int {
    
    case none = -1
    case active, testing, retired

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
        return labelFor(state) + Constant.arrow
    }
    
    static func possibleTitles() -> [String] {
        return states.keys.map { DeckState.buttonLabelFor($0) }
    }
}
