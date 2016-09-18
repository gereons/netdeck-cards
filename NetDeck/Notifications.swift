//
//  Notifications.swift
//  NetDeck
//
//  Created by Gereon Steffens on 13.12.15.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

@objc class Notifications: NSObject {
    static let ADD_TOP_CARD    = NSNotification.Name("addTopCard")       // card filter: return pressed, add top card, no userInfo
    static let SELECT_IDENTITY = NSNotification.Name("selectIdentity")   // identity selection, userInfo contains = "code"
    static let DECK_CHANGED    = NSNotification.Name("deckChanged")      // change to current deck, e.g. count stepper, userInfo may contain = "initialLoad"=YES/NO
    static let DECK_SAVED      = NSNotification.Name("deckSaved")        // deck was saved
    static let LOAD_DECK       = NSNotification.Name("loadDeck")         // load a deck from disk, userInfo contains = "filename" and = "role"
    static let NEW_DECK        = NSNotification.Name("newDeck")          // create a new deck, userInfo contains = "role"
    static let IMPORT_DECK     = NSNotification.Name("importDeck")       // import deck from clipboard, userInfo contains = "deck"
    static let LOAD_CARDS      = NSNotification.Name("loadCards")        // card download from netrunnerdb.com, userInfo contains = "success" (BOOL)
    static let DROPBOX_CHANGED = NSNotification.Name("dropboxChanged")   // dropbox link status changed, no userInfo
    static let NOTES_CHANGED   = NSNotification.Name("notesChanged")     // notes for a deck changed, no userInfo
    static let BROWSER_NEW     = NSNotification.Name("browserNew")       // new deck with card, userInfo contains = "code"
    static let BROWSER_FIND    = NSNotification.Name("browserFind")      // find decks with card, userInfo contains = "code"
    static let NAME_ALERT      = NSNotification.Name("nameAlert")        // name alert is about to appear, no userInfo
}
