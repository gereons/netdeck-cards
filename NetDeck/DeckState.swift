//
//  DeckState.swift
//  NetDeck
//
//  Created by Gereon Steffens on 14.11.15.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import Foundation

@objc class DeckState: NSObject {

    private static let states: [NRDeckState: String] = [
        .None: "All",
        .Retired: "Retired",
        .Testing: "Testing",
        .Active: "Active"
    ]
    
    class func rawLabelFor(state: NRDeckState) -> String {
        return states[state]!
    }
    
    class func labelFor(state: NRDeckState) -> String {
        return rawLabelFor(state).localized()
    }
    
    class func buttonLabelFor(state: NRDeckState) -> String {
        return labelFor(state) + " ▾"
    }
}