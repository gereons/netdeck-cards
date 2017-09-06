//
//  Answers.swift
//  NetDeck
//
//  Created by Gereon Steffens on 26.03.16.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import Crashlytics

class Analytics {
    
    enum Event: String {
        case start = "Start"
        case browser = "Browser"
        case openNRDB = "Open NRDB"
        case compareDecks = "Compare Decks"
        case deckHistory = "Deck History"
        case revert = "Revert"
        case importFromClipboard = "Import from Clipboard"
        case openInSafari = "Open in Safari"
        case publishDeck = "Publish Deck"
        case unlinkDeck = "Unlink Deck"
        case reimportDeck = "Reimport Deck"
        case saveToNRDB = "Save to NRDB"
        case changeState = "Change State"
        case exportO8D = "Export .o8d"
        case exportBBCode = "Export BBCode"
        case exportMD = "Export MD"
        case exportText = "Export Text"
        case clipBBCode = "Clip BBCode"
        case clipMD = "Clip MD"
        case clipText = "Clip Text"
        case emailDeck = "Email Deck"
        case printDeck = "Print Deck"
        case uploadJintekiNet = "Upload Jinteki.net"
        case drawSim = "Draw Sim"
        case changeLanguage = "Change Language"
        case showTipJar = "Show Tip Jar"
        case selectTip = "Select Tip"
        case tipTransaction = "Tip Transaction"
    }

    static func logEvent(_ event: Event, attributes: [String: Any]? = nil) {
        if BuildConfig.useCrashlytics {
            Answers.logCustomEvent(withName: event.rawValue, customAttributes: attributes)
        }
    }

}
