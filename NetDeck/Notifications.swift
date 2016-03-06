//
//  Notifications.swift
//  NetDeck
//
//  Created by Gereon Steffens on 13.12.15.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

@objc class Notifications: NSObject {
    static let ADD_TOP_CARD    = "addTopCard"       // card filter: return pressed, add top card, no userInfo
    static let SELECT_IDENTITY = "selectIdentity"   // identity selection, userInfo contains = "code"
    static let DECK_CHANGED    = "deckChanged"      // change to current deck, e.g. count stepper, userInfo may contain = "initialLoad"=YES/NO
    static let DECK_SAVED      = "deckSaved"        // deck was saved
    static let LOAD_DECK       = "loadDeck"         // load a deck from disk, userInfo contains = "filename" and = "role"
    static let NEW_DECK        = "newDeck"          // create a new deck, userInfo contains = "role"
    static let IMPORT_DECK     = "importDeck"       // import deck from clipboard, userInfo contains = "deck"
    static let LOAD_CARDS      = "loadCards"        // card download from netrunnerdb.com, userInfo contains = "success" (BOOL)
    static let DROPBOX_CHANGED = "dropboxChanged"   // dropbox link status changed, no userInfo
    static let NOTES_CHANGED   = "notesChanged"     // notes for a deck changed, no userInfo
    static let BROWSER_NEW     = "browserNew"       // new deck with card, userInfo contains = "code"
    static let BROWSER_FIND    = "browserFind"      // find decks with card, userInfo contains = "code"
    static let NAME_ALERT      = "nameAlert"        // name alert is about to appear, no userInfo
}
