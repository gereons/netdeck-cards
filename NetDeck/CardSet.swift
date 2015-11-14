//
//  CardSet.swift
//  NetDeck
//
//  Created by Gereon Steffens on 14.11.15.
//  Copyright © 2015 Gereon Steffens. All rights reserved.
//

import Foundation

@objc class CardSet : NSObject {
    var name: String!
    var setNum: Int = 0
    var setCode: String!
    var settingsKey: String!
    var cycle: NRCycle = .None
    var released = false
}
