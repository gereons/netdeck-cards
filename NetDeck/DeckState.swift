//
//  DeckState.swift
//  NetDeck
//
//  Created by Gereon Steffens on 14.11.15.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import Foundation

class DeckState: NSObject {

    private static let states: [NRDeckState: String] = [
        .none: "All",
        .retired: "Retired",
        .testing: "Testing",
        .active: "Active"
    ]
    
    class func rawLabelFor(_ state: NRDeckState) -> String {
        return states[state]!
    }
    
    class func labelFor(_ state: NRDeckState) -> String {
        return rawLabelFor(state).localized()
    }
    
    class func buttonLabelFor(_ state: NRDeckState) -> String {
        return labelFor(state) + " ▾"
    }
}
