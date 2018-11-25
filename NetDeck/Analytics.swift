//
//  Answers.swift
//  NetDeck
//
//  Created by Gereon Steffens on 26.03.16.
//  Copyright © 2018 Gereon Steffens. All rights reserved.
//

import Fabric
import Crashlytics
import StoreKit

class Analytics: NSObject {

    static let shared = Analytics()
    override private init() {}

    private(set) var crashDetected = false
    
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
        guard setup() else {
            return
        }
        
        Answers.logCustomEvent(withName: event.rawValue, customAttributes: attributes)
    }
    
    static func logPurchase(of product: SKProduct) {
        guard setup() else {
            return
        }

        Answers.logPurchase(withPrice: product.price,
                            currency: product.priceLocale.currencyCode,
                            success: true,
                            itemName: product.localizedTitle,
                            itemType: "iap",
                            itemId: product.productIdentifier,
                            customAttributes: nil)
    }

    static private var initialized = false

    @discardableResult
    static func setup() -> Bool {
        guard BuildConfig.useCrashlytics else {
            return false
        }

        if !initialized {
            Crashlytics.sharedInstance().delegate = Analytics.shared
            Fabric.with([Crashlytics.self])
            initialized = true
        }

        return true
    }
}


// MARK: - crashlytics delegate
extension Analytics: CrashlyticsDelegate {
    func crashlyticsDidDetectReport(forLastExecution report: CLSReport) {
        self.crashDetected = true
    }
}
