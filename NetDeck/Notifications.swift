//
//  Notifications.swift
//  NetDeck
//
//  Created by Gereon Steffens on 13.12.15.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import Foundation

struct Notifications {
    static let addTopCard       = Notification.Name("addTopCard")       // card filter: return pressed, add top card, no userInfo
    static let selectIdentity   = Notification.Name("selectIdentity")   // identity selection, userInfo contains = "code"
    static let deckChanged      = Notification.Name("deckChanged")      // change to current deck, e.g. count stepper, userInfo may contain = "initialLoad"=YES/NO
    static let deckSaved        = Notification.Name("deckSaved")        // deck was saved
    static let loadDeck         = Notification.Name("loadDeck")         // load a deck from disk, userInfo contains = "filename" and = "role"
    static let newDeck          = Notification.Name("newDeck")          // create a new deck, userInfo contains = "role"
    static let importDeck       = Notification.Name("importDeck")       // import deck from clipboard, userInfo contains = "deck"
    static let loadCards        = Notification.Name("loadCards")        // card download from netrunnerdb.com, userInfo contains = "success" (BOOL)
    static let notesChanged     = Notification.Name("notesChanged")     // notes for a deck changed, no userInfo
    static let browserNew       = Notification.Name("browserNew")       // new deck with card, userInfo contains = "code"
    static let browserFind      = Notification.Name("browserFind")      // find decks with card, userInfo contains = "code"
    static let nameAlert        = Notification.Name("nameAlert")        // name alert is about to appear, no userInfo
}
