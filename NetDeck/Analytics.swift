//
//  Answers.swift
//  NetDeck
//
//  Created by Gereon Steffens on 26.03.16.
//  Copyright © 2019 Gereon Steffens. All rights reserved.
//

import Sentry
import StoreKit

class Analytics: NSObject {

    static let shared = Analytics()
    override private init() {}
    
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
        case cardUpdate = "Card Update"
        case appUpdateAvailable = "App Update Available"
        case appUpdateStarted = "App Update Started"
        case showSettings = "Show Settings"
        case changeMwl = "Change MWL"
        case showAbout = "Show About"
        case deckNotes = "Show Deck Notes"
    }

    static func logEvent(_ event: Event, attributes: [String: Any]? = nil) {
        // nop
    }
    
    static func logPurchase(of product: SKProduct) {
        // nop
    }

    static private var initialized = false

    @discardableResult
    static func setup() -> Bool {
        guard BuildConfig.useSentry else {
            return false
        }

        if !initialized {
            SentrySDK.start(options: [
                "dsn": "https://2f7b1cb084b644478c09c436d24931c5@o397144.ingest.sentry.io/5275922",
                "debug": true // Enabled debug when first installing is always helpful
            ])
            initialized = true
        }

        return true
    }
}

extension Analytics {
    var crashDetected: Bool {
        return SentryCrash.sharedInstance()?.crashedLastLaunch ?? false
    }
}
