//
//  DeckState.swift
//  NetDeck
//
//  Created by Gereon Steffens on 14.11.15.
//  Copyright © 2015 Gereon Steffens. All rights reserved.
//

import Foundation

@objc class DeckState: NSObject {

    private static let states: [NRDeckState: String] = [
        .None: "All".localized(),
        .Retired: "Retired".localized(),
        .Testing: "Testing".localized(),
        .Active: "Active".localized()
    ]
    
    class func labelFor(state: NRDeckState) -> String {
        return states[state]!;
    }
    
    class func buttonLabelFor(state: NRDeckState) -> String {
        return String(format:"%@ ▾", states[state]!);
    }
}